import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/features/auth/data/usuario_model.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

/// Testes do contrato multi-igreja que travava a publicação.
void main() {
  group('Cadastro compatível com as Rules', () {
    test('o mapa de criação só usa chaves que as Rules aceitam', () {
      final mapa = mapaDeCriacaoUsuario(
        nome: 'Maria',
        email: 'maria@exemplo.com',
        telefone: '(81) 99999-0000',
        igrejaPrincipalId: 'olinda',
        fotoUrl: 'https://exemplo.com/foto.jpg',
      );

      // Era exatamente isto que quebrava: UsuarioModel.toMap() escreve
      // 'perfil', 'status' e 'uid', que o hasOnly das Rules recusa.
      expect(
        mapa.keys.toSet().difference(chavesPermitidasCriacaoUsuario),
        isEmpty,
        reason: 'Chave fora do hasOnly faz o Firestore recusar o cadastro.',
      );
    });

    test('autorização não vai para o documento global do usuário', () {
      final mapa = mapaDeCriacaoUsuario(
        nome: 'Maria',
        email: 'maria@exemplo.com',
        telefone: '',
        igrejaPrincipalId: 'petrolina',
      );

      expect(mapa.containsKey('perfil'), isFalse);
      expect(mapa.containsKey('status'), isFalse);
      expect(mapa.containsKey('funcoes_admin'), isFalse);
    });

    test('a igreja escolhida vira a igreja principal', () {
      final mapa = mapaDeCriacaoUsuario(
        nome: 'João',
        email: 'joao@exemplo.com',
        telefone: '',
        igrejaPrincipalId: 'petrolina',
      );

      expect(mapa['igreja_principal_id'], 'petrolina');
    });

    test('campos opcionais ausentes não viram null gravado', () {
      final mapa = mapaDeCriacaoUsuario(
        nome: 'João',
        email: 'joao@exemplo.com',
        telefone: '',
        igrejaPrincipalId: 'olinda',
      );

      expect(mapa.containsKey('foto_url'), isFalse);
      expect(mapa.containsKey('dados_pessoais'), isFalse);
    });
  });

  group('Visualizar outra igreja não transfere permissão', () {
    final olinda = IgrejaId('olinda');
    final petrolina = IgrejaId('petrolina');

    final pastorDeOlinda = VinculoIgreja(
      uid: 'uid-pastor',
      igrejaId: olinda,
      status: StatusVinculo.aprovado,
      perfil: PerfilComunitario.pastor,
    );

    test('pastor de Olinda administra Olinda', () {
      final a = Autorizacao(
        uid: 'uid-pastor',
        igrejaId: olinda,
        vinculo: pastorDeOlinda,
      );
      expect(a.podeAcessarPainel, isTrue);
      expect(a.temVinculoAtivo, isTrue);
    });

    test('o mesmo vínculo NÃO vale em Petrolina', () {
      // É o caso perigoso: levar o vínculo de uma unidade para outra.
      final a = Autorizacao(
        uid: 'uid-pastor',
        igrejaId: petrolina,
        vinculo: pastorDeOlinda,
      );
      expect(a.temVinculoAtivo, isFalse);
      expect(a.podeAcessarPainel, isFalse);
      expect(a.perfilEfetivo, PerfilComunitario.membro);
    });

    test('visitante sem vínculo não acessa o painel', () {
      final a =
          Autorizacao.semVinculo(uid: 'uid-visitante', igrejaId: petrolina);
      expect(a.podeAcessarPainel, isFalse);
      expect(a.podeLerFinancas, isFalse);
    });

    test('membro comum não vê o botão do painel', () {
      final a = Autorizacao(
        uid: 'uid-membro',
        igrejaId: olinda,
        vinculo: VinculoIgreja(
          uid: 'uid-membro',
          igrejaId: olinda,
          status: StatusVinculo.aprovado,
          perfil: PerfilComunitario.membro,
        ),
      );
      expect(a.podeAcessarPainel, isFalse);
    });

    test('vínculo pendente não concede acesso', () {
      final a = Autorizacao(
        uid: 'uid-novo',
        igrejaId: olinda,
        vinculo: VinculoIgreja(
          uid: 'uid-novo',
          igrejaId: olinda,
          status: StatusVinculo.pendente,
          perfil: PerfilComunitario.pastor,
        ),
      );
      expect(a.temVinculoAtivo, isFalse);
      expect(a.podeAcessarPainel, isFalse);
    });

    test('tesoureiro e editor acessam o painel; só o tesoureiro vê finanças',
        () {
      Autorizacao com(FuncaoAdmin f) => Autorizacao(
            uid: 'uid',
            igrejaId: olinda,
            vinculo: VinculoIgreja(
              uid: 'uid',
              igrejaId: olinda,
              status: StatusVinculo.aprovado,
              perfil: PerfilComunitario.membro,
              funcoesAdmin: {f},
            ),
          );

      expect(com(FuncaoAdmin.tesoureiro).podeAcessarPainel, isTrue);
      expect(com(FuncaoAdmin.tesoureiro).podeLerFinancas, isTrue);
      expect(com(FuncaoAdmin.editor).podeAcessarPainel, isTrue);
      expect(com(FuncaoAdmin.editor).podeLerFinancas, isFalse);
      expect(com(FuncaoAdmin.moderadorOracao).podeLerFinancas, isFalse);
    });
  });

  group('Dados institucionais por unidade', () {
    IgrejaModel igreja({
      String? pix,
      String? endereco,
      String? pastor,
      List<String> pastores = const [],
    }) =>
        IgrejaModel(
          id: IgrejaId('petrolina'),
          nome: 'Comunidade Nova Aliança Petrolina',
          endereco: endereco,
          cidadeEstado: 'Petrolina — PE',
          pixChave: pix,
          pastorResponsavel: pastor,
          pastoresPublicos: pastores,
        );

    test('unidade sem PIX não aceita contribuição', () {
      expect(igreja().aceitaContribuicao, isFalse);
      expect(igreja(pix: '  ').aceitaContribuicao, isFalse);
    });

    test('unidade com PIX aceita contribuição', () {
      expect(igreja(pix: 'chave@exemplo.com').aceitaContribuicao, isTrue);
    });

    test('sem endereço não há link de mapa', () {
      expect(igreja().mapaUrl, isNull);
    });

    test('com endereço, o mapa usa o endereço da própria unidade', () {
      final url = igreja(endereco: 'Rua 47, número 180').mapaUrl;
      expect(url, isNotNull);
      expect(url, contains('Petrolina'));
      // Nunca o endereço de Olinda.
      expect(url, isNot(contains('Leopoldino')));
    });

    test('liderança divergente não elege um pastor', () {
      // Enquanto a divergência de Petrolina não for resolvida, a tela precisa
      // dizer "não informado" em vez de escolher um nome.
      expect(igreja().pastoresExibicao, isEmpty);
    });

    test('vários pastores públicos são preservados', () {
      final lista = igreja(pastores: ['Pr. A', 'Pra. B']).pastoresExibicao;
      expect(lista, ['Pr. A', 'Pra. B']);
    });

    test('um pastor confirmado aparece sozinho', () {
      expect(igreja(pastor: 'Pr. Victor').pastoresExibicao, ['Pr. Victor']);
    });
  });

  group('IgrejaId é o escopo, não o nome', () {
    test('nomes parecidos produzem ids distintos', () {
      expect(IgrejaId('olinda'), isNot(IgrejaId('petrolina')));
    });

    test('texto inválido não vira escopo silenciosamente', () {
      expect(IgrejaId.tentar(null), isNull);
      expect(IgrejaId.tentar(''), isNull);
    });
  });
}
