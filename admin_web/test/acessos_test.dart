import 'package:admin_web/dados/acessos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

Map<String, dynamic> mapaAcesso({
  String igrejaId = 'olinda',
  String perfil = 'lider',
  List<String> funcoes = const [],
  bool lerFinancas = true,
  bool gerenciarLideranca = false,
}) {
  return {
    'igrejaId': igrejaId,
    'nome': 'Nova Aliança ${igrejaId[0].toUpperCase()}${igrejaId.substring(1)}',
    'ativa': true,
    'perfil': perfil,
    'status': 'aprovado',
    'funcoesAdmin': funcoes,
    'capacidades': {
      'acessarPainel': true,
      'lerFinancas': lerFinancas,
      'gerenciarConteudo': true,
      'moderarOracao': true,
      'aprovarMembro': true,
      'gerenciarLideranca': gerenciarLideranca,
    },
  };
}

void main() {
  group('AcessoIgreja', () {
    test('lê capacidades vindas do servidor', () {
      final acesso = AcessoIgreja.doMapa(mapaAcesso(
        perfil: 'evangelista',
        funcoes: ['tesoureiro'],
        gerenciarLideranca: false,
      ));

      expect(acesso.igrejaId, IgrejaId.olinda);
      expect(acesso.perfil, PerfilComunitario.evangelista);
      expect(acesso.funcoesAdmin, {FuncaoAdmin.tesoureiro});
      expect(acesso.lerFinancas, isTrue);
      expect(acesso.gerenciarLideranca, isFalse);
    });

    test('capacidade ausente é tratada como negada', () {
      final acesso = AcessoIgreja.doMapa({
        'igrejaId': 'olinda',
        'nome': 'Olinda',
        'perfil': 'membro',
        'status': 'aprovado',
        'capacidades': const {},
      });

      expect(acesso.lerFinancas, isFalse);
      expect(acesso.gerenciarLideranca, isFalse);
      expect(acesso.acessarPainel, isFalse);
    });
  });

  group('MeusAcessos', () {
    test('sem acessos => bloqueio do painel', () {
      const acessos = MeusAcessos(uid: 'u1', isSuperAdmin: false, acessos: []);
      expect(acessos.semAcessoAdministrativo, isTrue);
      expect(acessos.precisaSeletor, isFalse);
    });

    test('uma unidade => sem seletor de igreja', () {
      final acessos = MeusAcessos(
        uid: 'u1',
        isSuperAdmin: false,
        acessos: [AcessoIgreja.doMapa(mapaAcesso())],
      );
      expect(acessos.semAcessoAdministrativo, isFalse);
      expect(acessos.precisaSeletor, isFalse);
    });

    test('duas unidades => seletor aparece', () {
      final acessos = MeusAcessos(
        uid: 'sa',
        isSuperAdmin: true,
        acessos: [
          AcessoIgreja.doMapa(mapaAcesso()),
          AcessoIgreja.doMapa(mapaAcesso(igrejaId: 'petrolina')),
        ],
      );
      expect(acessos.precisaSeletor, isTrue);
      expect(acessos.porId(IgrejaId.petrolina)?.igrejaId, IgrejaId.petrolina);
    });

    test('porId devolve null para unidade não autorizada', () {
      final acessos = MeusAcessos(
        uid: 'u1',
        isSuperAdmin: false,
        acessos: [AcessoIgreja.doMapa(mapaAcesso())],
      );
      // Selecionar Petrolina no frontend não inventa um acesso.
      expect(acessos.porId(IgrejaId.petrolina), isNull);
    });
  });
}
