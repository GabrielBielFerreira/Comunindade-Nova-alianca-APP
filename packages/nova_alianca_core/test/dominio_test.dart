import 'package:nova_alianca_core/nova_alianca_core.dart';
import 'package:test/test.dart';

void main() {
  group('normalizarChave', () {
    test('remove acentos e normaliza caixa', () {
      expect(normalizarChave('Líder'), 'lider');
      expect(normalizarChave('DIÁCONO'), 'diacono');
      expect(normalizarChave('  Evangelista  '), 'evangelista');
    });

    test('converte espaço e hífen em underscore', () {
      expect(normalizarChave('moderador de oração'), 'moderador_de_oracao');
      expect(normalizarChave('moderador-oracao'), 'moderador_oracao');
    });
  });

  group('IgrejaId', () {
    test('normaliza a entrada', () {
      expect(IgrejaId('Olinda').valor, 'olinda');
      expect(IgrejaId('Nova Aliança').valor, 'nova_alianca');
    });

    test('rejeita valores inválidos', () {
      expect(() => IgrejaId(''), throwsArgumentError);
      expect(() => IgrejaId('a'), throwsArgumentError);
      expect(() => IgrejaId('igreja/olinda'), throwsArgumentError);
      expect(() => IgrejaId('../admin'), throwsArgumentError);
    });

    test('tentar() devolve null em vez de lançar', () {
      expect(IgrejaId.tentar('x'), isNull);
      expect(IgrejaId.tentar(null), isNull);
      expect(IgrejaId.tentar('petrolina'), IgrejaId.petrolina);
    });

    test('igualdade por valor', () {
      expect(IgrejaId('olinda'), IgrejaId.olinda);
      expect(IgrejaId('olinda') == IgrejaId.petrolina, isFalse);
    });
  });

  group('PerfilComunitario', () {
    test('reconhece grafias com acento e maiúscula', () {
      expect(PerfilComunitario.deTexto('Líder'), PerfilComunitario.lider);
      expect(PerfilComunitario.deTexto('Diácono'), PerfilComunitario.diacono);
      expect(PerfilComunitario.deTexto('EVANGELISTA'), PerfilComunitario.evangelista);
    });

    test('desconhecido cai no menor privilégio', () {
      expect(PerfilComunitario.deTexto('super-chefe'), PerfilComunitario.membro);
      expect(PerfilComunitario.deTexto(null), PerfilComunitario.membro);
    });

    test('evangelista faz parte da liderança ministerial', () {
      expect(PerfilComunitario.evangelista.isLiderancaMinisterial, isTrue);
      expect(PerfilComunitario.membro.isLiderancaMinisterial, isFalse);
    });
  });

  group('FuncaoAdmin', () {
    test('serializa moderador_oracao em snake_case', () {
      expect(FuncaoAdmin.moderadorOracao.valor, 'moderador_oracao');
      expect(FuncaoAdmin.deTexto('moderador de oração'), FuncaoAdmin.moderadorOracao);
    });

    test('descarta funções desconhecidas da lista', () {
      final funcoes = FuncaoAdmin.deLista(['tesoureiro', 'inventada', 'editor']);
      expect(funcoes, {FuncaoAdmin.tesoureiro, FuncaoAdmin.editor});
    });

    test('deTexto desconhecido devolve null (nunca adivinha)', () {
      expect(FuncaoAdmin.deTexto('admin_geral'), isNull);
    });
  });

  group('VinculoIgreja', () {
    test('round-trip do mapa preserva perfil e funções', () {
      final original = VinculoIgreja(
        uid: 'u1',
        igrejaId: IgrejaId.olinda,
        status: StatusVinculo.aprovado,
        perfil: PerfilComunitario.evangelista,
        funcoesAdmin: {FuncaoAdmin.tesoureiro},
      );
      final mapa = original.paraMapa();
      final lido = VinculoIgreja.doMapa(
        uid: 'u1',
        igrejaId: IgrejaId.olinda,
        dados: mapa,
      );
      expect(lido.perfil, PerfilComunitario.evangelista);
      expect(lido.funcoesAdmin, {FuncaoAdmin.tesoureiro});
      expect(lido.status, StatusVinculo.aprovado);
    });

    test('vínculo inativo não é ativo mesmo com perfil de pastor', () {
      final v = VinculoIgreja(
        uid: 'u1',
        igrejaId: IgrejaId.olinda,
        status: StatusVinculo.inativo,
        perfil: PerfilComunitario.pastor,
      );
      expect(v.isAtivo, isFalse);
      expect(v.isPastor, isFalse);
      expect(v.isLiderancaMinisterial, isFalse);
    });

    test('campos ausentes caem no menor privilégio', () {
      final v = VinculoIgreja.doMapa(
        uid: 'u1',
        igrejaId: IgrejaId.olinda,
        dados: const {},
      );
      expect(v.status, StatusVinculo.pendente);
      expect(v.perfil, PerfilComunitario.membro);
      expect(v.funcoesAdmin, isEmpty);
    });
  });

  group('IgrejaModel', () {
    test('unidade nova aparece como não configurada, sem inventar dados', () {
      final igreja = IgrejaModel.doMapa(
        id: 'petrolina',
        dados: const {'nome': 'Nova Aliança Petrolina'},
      );
      expect(igreja.ativa, isFalse);
      expect(igreja.configurada, isFalse);
      expect(igreja.pastorResponsavel, isNull);
      expect(igreja.pastorExibicao, 'Não configurado');
      expect(igreja.enderecoExibicao, 'Não configurado');
      expect(igreja.mercadoPagoStatus, StatusMercadoPago.naoConfigurado);
    });

    test('campos vazios contam como não configurados', () {
      final igreja = IgrejaModel.doMapa(
        id: 'olinda',
        dados: const {
          'nome': 'Nova Aliança Olinda',
          'dados_institucionais': {'endereco': '   '},
        },
      );
      expect(igreja.endereco, isNull);
    });
  });
}
