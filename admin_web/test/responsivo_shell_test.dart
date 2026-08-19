import 'package:admin_web/dados/acessos.dart';
import 'package:admin_web/dados/conteudo_repository.dart';
import 'package:admin_web/estado/providers.dart';
import 'package:admin_web/telas/conteudo_telas.dart';
import 'package:admin_web/telas/igrejas_tela.dart';
import 'package:admin_web/telas/shell.dart';
import 'package:admin_web/ui/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import 'responsivo.dart';
import 'responsivo_painel_test.dart' show acessoCompleto;

/// Moldura do painel e as telas que faltavam na auditoria de responsividade.
///
/// `responsivo_telas_test.dart` cobre Membros, Finanças e Programação;
/// `responsivo_painel_test.dart` cobre Login e Dashboard. Aqui entram o shell
/// (barra lateral que vira drawer) e o restante dos módulos.

final _olinda = IgrejaId('olinda');
final _petrolina = IgrejaId('petrolina');

// Textos longos de propósito: é o que estoura cartão e tabela.
final _avisos = <Aviso>[
  Aviso(
    id: 'a1',
    titulo: 'Mutirão de limpeza do templo neste sábado a partir das 8h',
    conteudo: 'Traga luvas. O café da manhã fica por conta da diaconia.',
    prioridade: 'urgente',
    publicadoEm: DateTime(2026, 8, 10),
  ),
];

final _campanhas = <Campanha>[
  Campanha(
    id: 'c1',
    titulo: 'Campanha de reforma do telhado do templo sede',
    descricao: 'Arrecadação para a troca completa das telhas e calhas.',
    dataInicio: DateTime(2026, 8, 1),
    dataFim: DateTime(2026, 12, 20),
    metaCentavos: 4500000,
  ),
];

const _ministerios = <Ministerio>[
  Ministerio(
    id: 'mi1',
    nome: 'Ministério de Louvor e Adoração da Comunidade Nova Aliança',
    descricao: 'Equipe responsável pela música dos cultos e ensaios.',
    liderNome: 'João Pedro de Albuquerque Vasconcelos',
  ),
];

final _devocionais = <Devocional>[
  Devocional(
    id: 'd1',
    titulo: 'A perseverança que sustenta a caminhada',
    corpo: 'Reflexão sobre constância na fé em tempos difíceis.',
    autor: 'Pastor responsável',
    data: DateTime(2026, 8, 15),
    referencia: 'Hebreus 12:1-3',
  ),
];

const _oracoes = <PedidoOracao>[
  PedidoOracao(
    id: 'p1',
    texto:
        'Peço oração pela saúde da minha mãe, que está internada há '
        'duas semanas aguardando cirurgia.',
    autorNome: 'Maria das Graças Albuquerque',
    urgente: true,
  ),
];

final _igrejas = <IgrejaModel>[
  IgrejaModel(
    id: _olinda,
    nome: 'Comunidade Nova Aliança — Olinda (Sede)',
    ativa: true,
    configurada: true,
  ),
  IgrejaModel(
    id: _petrolina,
    nome: 'Comunidade Nova Aliança — Petrolina',
    ativa: false,
    configurada: false,
  ),
];

List<Override> _overrides({
  required AcessoIgreja acesso,
  bool isSuperAdmin = false,
  List<AcessoIgreja>? acessos,
}) {
  Stream<Pagina<T>> pagina<T>(List<T> itens) =>
      Stream.value(Pagina(itens: itens, truncada: false));

  return [
    authStateProvider.overrideWith((ref) => Stream.value(null)),
    meusAcessosProvider.overrideWith(
      (ref) async => MeusAcessos(
        uid: 'uid',
        isSuperAdmin: isSuperAdmin,
        acessos: acessos ?? [acesso],
      ),
    ),
    acessoAtualProvider.overrideWithValue(acesso),
    igrejasProvider.overrideWith((ref) => Stream.value(_igrejas)),
    igrejaAtualProvider.overrideWith((ref) => Stream.value(_igrejas.first)),
    avisosProvider.overrideWith((ref) => pagina(_avisos)),
    campanhasProvider.overrideWith((ref) => pagina(_campanhas)),
    ministeriosProvider.overrideWith((ref) => pagina(_ministerios)),
    devocionaisProvider.overrideWith((ref) => pagina(_devocionais)),
    oracoesPendentesProvider.overrideWith((ref) => pagina(_oracoes)),
    oracoesAprovadasProvider.overrideWith((ref) => pagina(const [])),
    membrosProvider.overrideWith((ref) => pagina(const [])),
    eventosProvider.overrideWith((ref) => pagina(const [])),
  ];
}

/// Uma tela isolada. Vai com GoRouter porque varias leem a query string
/// (`?novo=1`) via `GoRouterState` para abrir o formulario ja no ar.
Widget _tela(Widget corpo, {required AcessoIgreja acesso}) {
  return ProviderScope(
    overrides: _overrides(acesso: acesso, isSuperAdmin: true),
    child: MaterialApp.router(
      theme: TemaPainel.claro(),
      routerConfig: GoRouter(
        initialLocation: '/tela',
        routes: [
          GoRoute(
            path: '/tela',
            builder: (_, _) => Scaffold(body: corpo),
          ),
        ],
      ),
    ),
  );
}

/// Painel inteiro: shell + conteúdo, com GoRouter de verdade porque os itens
/// do menu navegam com `context.go`.
Widget _painel({
  required AcessoIgreja acesso,
  bool isSuperAdmin = true,
  List<AcessoIgreja>? acessos,
  String rotaInicial = '/avisos',
}) {
  return ProviderScope(
    overrides: _overrides(
      acesso: acesso,
      isSuperAdmin: isSuperAdmin,
      acessos: acessos,
    ),
    child: MaterialApp.router(
      theme: TemaPainel.claro(),
      routerConfig: GoRouter(
        initialLocation: rotaInicial,
        routes: [
          ShellRoute(
            builder: (_, _, child) => PainelShell(child: child),
            routes: [
              GoRoute(path: '/avisos', builder: (_, _) => const AvisosTela()),
              GoRoute(
                path: '/dashboard',
                builder: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('Moldura do painel', () {
    paraCadaTamanho('não estoura', (tester, tamanho, escala) async {
      await esperarSemOverflow(
        tester,
        _painel(acesso: acessoCompleto()),
        tamanho: tamanho,
        escalaTexto: escala,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('em celular a barra lateral fica recolhida no drawer', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_painel(acesso: acessoCompleto()));
      await tester.pumpAndSettle();

      // Recolhida: o menu não ocupa a tela, mas está a um toque de distância.
      expect(find.text('Dashboard'), findsNothing);
      expect(find.byTooltip('Open navigation menu'), findsOneWidget);

      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Membros'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('em desktop a barra lateral fica fixa, sem drawer', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_painel(acesso: acessoCompleto()));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byTooltip('Open navigation menu'), findsNothing);
    });

    testWidgets('o menu só mostra o que a capacidade do servidor permite', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);

      // Tesoureiro: finanças sim; liderança, conteúdo, oração e igrejas não.
      final tesoureiro = AcessoIgreja(
        igrejaId: _olinda,
        nome: 'Comunidade Nova Aliança — Olinda (Sede)',
        ativa: true,
        perfil: PerfilComunitario.membro,
        status: 'aprovado',
        funcoesAdmin: const {FuncaoAdmin.tesoureiro},
        acessarPainel: true,
        lerFinancas: true,
        gerenciarConteudo: false,
        moderarOracao: false,
        aprovarMembro: false,
        gerenciarLideranca: false,
      );

      await tester.pumpWidget(
        _painel(
          acesso: tesoureiro,
          isSuperAdmin: false,
          rotaInicial: '/dashboard',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Finanças'), findsOneWidget);
      expect(find.text('Membros'), findsOneWidget);
      expect(find.text('Liderança'), findsNothing);
      expect(find.text('Avisos'), findsNothing);
      expect(find.text('Oração'), findsNothing);
      // `/igrejas` é exclusiva do superadministrador.
      expect(find.text('Igrejas'), findsNothing);
    });

    testWidgets('com um unico acesso nao existe seletor de unidade', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_painel(acesso: acessoCompleto()));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButton<String>), findsNothing);
    });

    testWidgets('com dois acessos o seletor aparece e lista as duas unidades', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);

      final petrolina = AcessoIgreja(
        igrejaId: _petrolina,
        nome: 'Comunidade Nova Aliança — Petrolina',
        ativa: false,
        perfil: PerfilComunitario.pastor,
        status: 'aprovado',
        funcoesAdmin: const {},
        acessarPainel: true,
        lerFinancas: true,
        gerenciarConteudo: true,
        moderarOracao: true,
        aprovarMembro: true,
        gerenciarLideranca: true,
      );

      await tester.pumpWidget(
        _painel(
          acesso: acessoCompleto(),
          acessos: [acessoCompleto(), petrolina],
        ),
      );
      await tester.pumpAndSettle();

      // O seletor apenas alterna entre unidades JA autorizadas pelo servidor.
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('em 320px dois acessos usam seletor compacto sem overflow', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);

      final petrolina = AcessoIgreja(
        igrejaId: _petrolina,
        nome: 'Comunidade Nova Aliança — Petrolina com nome extenso',
        ativa: false,
        perfil: PerfilComunitario.pastor,
        status: 'aprovado',
        funcoesAdmin: const {},
        acessarPainel: true,
        lerFinancas: true,
        gerenciarConteudo: true,
        moderarOracao: true,
        aprovarMembro: true,
        gerenciarLideranca: true,
      );

      await tester.pumpWidget(
        _painel(
          acesso: acessoCompleto(),
          acessos: [acessoCompleto(), petrolina],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Trocar unidade'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Trocar unidade'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Petrolina com nome extenso'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Telas restantes do painel', () {
    final casos = <String, Widget>{
      'Avisos': const AvisosTela(),
      'Campanhas': const CampanhasTela(),
      'Ministérios': const MinisteriosTela(),
      'Devocionais': const DevocionaisTela(),
      'Oração': const OracaoTela(),
      'Igrejas': const IgrejasTela(),
    };

    for (final caso in casos.entries) {
      paraCadaTamanho('${caso.key} não estoura', (
        tester,
        tamanho,
        escala,
      ) async {
        await esperarSemOverflow(
          tester,
          _tela(caso.value, acesso: acessoCompleto()),
          tamanho: tamanho,
          escalaTexto: escala,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
