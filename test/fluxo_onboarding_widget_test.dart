import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nova_alianca_app/app/root_gate.dart';
import 'package:nova_alianca_app/app/screens/aguardando_aprovacao_screen.dart';
import 'package:nova_alianca_app/app/screens/conta_inativa_screen.dart';
import 'package:nova_alianca_app/app/screens/splash_screen.dart';
import 'package:nova_alianca_app/features/auth/data/usuario_model.dart';
import 'package:nova_alianca_app/features/auth/providers/auth_provider.dart';
import 'package:nova_alianca_app/core/services/notification_preferences.dart';
import 'package:nova_alianca_app/features/igrejas/providers/igreja_providers.dart';
import 'package:nova_alianca_app/visual/screens/home_leader_screen.dart';
import 'package:nova_alianca_app/visual/screens/home_member_screen.dart';
import 'package:nova_alianca_app/visual/screens/select_church_screen.dart';
import 'package:nova_alianca_app/visual/screens/welcome_access_screen.dart';
import 'package:nova_alianca_app/visual/visual_router.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fluxo multi-igreja pela INTERFACE.
///
/// Complementa `fluxo_onboarding_test.dart`, que exercita só os providers.
/// Aqui o teste toca na tela: o gate escolhe a primeira tela de verdade, a
/// lista de igrejas é pintada, o cartão é tocado e a escolha é confirmada.
///
/// As telas Home não entram: elas dependem de dezenas de consultas ao
/// Firestore e o que importa neste arquivo é a decisão de entrada.
void main() {
  final olinda = IgrejaId('olinda');
  final petrolina = IgrejaId('petrolina');

  final unidades = <IgrejaModel>[
    IgrejaModel(
      id: olinda,
      nome: 'Comunidade Nova Aliança Olinda',
      ativa: true,
      configurada: true,
      endereco: 'Rua da Sede, 100',
      cidadeEstado: 'Olinda — PE',
    ),
    IgrejaModel(
      id: petrolina,
      nome: 'Comunidade Nova Aliança Petrolina',
      ativa: true,
      // Sem dados institucionais oficiais: a tela precisa dizer isso, e não
      // repetir o endereço de Olinda.
      configurada: false,
    ),
  ];

  Widget app({
    required List<Override> overrides,
    Widget home = const RootGate(),
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: home),
    );
  }

  /// Sessão ausente: o caminho do visitante.
  final semSessao = authStateProvider.overrideWith((ref) => Stream.value(null));

  Override comIgrejas(List<IgrejaModel> lista) =>
      igrejasAtivasProvider.overrideWith((ref) => Stream.value(lista));

  Future<void> montar(WidgetTester tester, Widget widget) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  // ══════════════════════════════════════════════════════════════════
  // Primeira abertura
  // ══════════════════════════════════════════════════════════════════

  group('Primeira abertura na interface', () {
    testWidgets('sem escolha salva, o gate abre a seleção de igreja', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await montar(tester, app(overrides: [semSessao, comIgrejas(unidades)]));

      expect(find.byType(SelectChurchScreen), findsOneWidget);
      expect(find.text('Comunidade Nova Aliança Olinda'), findsOneWidget);
      expect(find.text('Comunidade Nova Aliança Petrolina'), findsOneWidget);
    });

    testWidgets('enquanto lê o disco mostra o splash, não a seleção', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'igreja_visualizada_id': 'petrolina',
      });

      await tester.pumpWidget(
        app(overrides: [semSessao, comIgrejas(unidades)]),
      );
      // Um único quadro: a leitura do SharedPreferences ainda não voltou.
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(SelectChurchScreen), findsNothing);
    });

    testWidgets('com escolha salva, o gate não volta para a seleção', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'igreja_visualizada_id': 'petrolina',
      });

      await montar(tester, app(overrides: [semSessao, comIgrejas(unidades)]));

      expect(find.byType(SelectChurchScreen), findsNothing);
    });

    testWidgets('sem unidade ativa, o estado vazio é honesto', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await montar(tester, app(overrides: [semSessao, comIgrejas(const [])]));

      expect(find.text('Nenhuma igreja disponível'), findsOneWidget);
      // Nada de unidade inventada para preencher a tela.
      expect(find.textContaining('Olinda'), findsNothing);
      expect(find.textContaining('Petrolina'), findsNothing);
    });

    testWidgets('unidade sem dados oficiais não herda endereço de outra', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await montar(tester, app(overrides: [semSessao, comIgrejas(unidades)]));

      expect(find.text('Endereço não informado'), findsOneWidget);
      expect(find.text('Rua da Sede, 100 — Olinda — PE'), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // Escolher Petrolina
  // ══════════════════════════════════════════════════════════════════

  group('Escolher Petrolina', () {
    testWidgets('confirmar grava a escolha e sai da seleção', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await montar(tester, app(overrides: [semSessao, comIgrejas(unidades)]));

      await tester.tap(find.text('Comunidade Nova Aliança Petrolina'));
      await tester.pumpAndSettle();

      // O cartão abre a folha de detalhes antes de confirmar.
      expect(find.text('Confirmar escolha'), findsOneWidget);

      await tester.tap(find.text('Confirmar escolha'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('igreja_visualizada_id'), 'petrolina');
      // A escolha do cadastro acompanha a do onboarding.
      expect(prefs.getString('igreja_escolhida_cadastro_id'), 'petrolina');

      expect(find.byType(SelectChurchScreen), findsNothing);
      // O RootGate continua como raiz e reage ao provider. Substituir a rota
      // raiz aqui quebrava o encaminhamento para a Home depois do login.
      expect(find.byType(WelcomeAccessScreen), findsOneWidget);
    });

    testWidgets('rota direta volta ao RootGate sem empilhar outro Welcome', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await montar(
        tester,
        ProviderScope(
          overrides: [semSessao, comIgrejas(unidades)],
          child: MaterialApp(
            initialRoute: VisualRoutes.selectChurch,
            routes: {
              ...visualRoutes,
              VisualRoutes.entraconta: (_) => const RootGate(),
            },
          ),
        ),
      );

      await tester.tap(find.text('Comunidade Nova Aliança Petrolina'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar escolha'));
      await tester.pumpAndSettle();

      expect(find.byType(SelectChurchScreen), findsNothing);
      expect(find.byType(WelcomeAccessScreen), findsOneWidget);
      final navigator = Navigator.of(
        tester.element(find.byType(WelcomeAccessScreen)),
      );
      expect(navigator.canPop(), isFalse);
    });

    testWidgets('sessão anônima continua como visitante', (tester) async {
      SharedPreferences.setMockInitialValues({
        'igreja_visualizada_id': 'petrolina',
      });

      final sessaoAnonima = authStateProvider.overrideWith(
        (ref) => Stream.value(_UsuarioAnonimoFake()),
      );

      await montar(
        tester,
        app(overrides: [sessaoAnonima, comIgrejas(unidades)]),
      );

      expect(find.byType(WelcomeAccessScreen), findsOneWidget);
      expect(find.text('Preparando sua conta...'), findsNothing);
    });

    testWidgets('a busca filtra a lista pelo nome', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await montar(tester, app(overrides: [semSessao, comIgrejas(unidades)]));

      await tester.enterText(find.byType(TextField).first, 'petro');
      await tester.pumpAndSettle();

      expect(find.text('Comunidade Nova Aliança Petrolina'), findsOneWidget);
      expect(find.text('Comunidade Nova Aliança Olinda'), findsNothing);
    });

    testWidgets('voltar para a lista não grava escolha nenhuma', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await montar(tester, app(overrides: [semSessao, comIgrejas(unidades)]));

      await tester.tap(find.text('Comunidade Nova Aliança Petrolina'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voltar para a lista'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('igreja_visualizada_id'), isNull);
      expect(find.byType(SelectChurchScreen), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // Troca da unidade VISUALIZADA (não muda vínculo)
  // ══════════════════════════════════════════════════════════════════

  group('Troca da unidade visualizada', () {
    testWidgets('escolher Olinda no modo troca devolve o nome e persiste', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'igreja_visualizada_id': 'petrolina',
      });

      String? devolvido;

      await montar(
        tester,
        app(
          overrides: [semSessao, comIgrejas(unidades)],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    devolvido = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (_) => const SelectChurchScreen(
                          modo: ModoSelecaoIgreja.troca,
                        ),
                      ),
                    );
                  },
                  child: const Text('abrir troca'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir troca'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comunidade Nova Aliança Olinda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar escolha'));
      await tester.pumpAndSettle();

      expect(devolvido, 'Comunidade Nova Aliança Olinda');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('igreja_visualizada_id'), 'olinda');
      // Trocar o que se VÊ não mexe na escolha de cadastro nem em vínculo.
      expect(prefs.getString('igreja_escolhida_cadastro_id'), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // Sessão autenticada: o gate decide pelo VÍNCULO PRINCIPAL
  // ══════════════════════════════════════════════════════════════════

  group('Gate com sessão', () {
    final comSessao = authStateProvider.overrideWith(
      (ref) => Stream.value(_UsuarioFake()),
    );

    Override comUsuario(String? igrejaPrincipalId) =>
        usuarioAtualProvider.overrideWith(
          (ref) => Stream.value(
            UsuarioModel(
              uid: 'uid-ana',
              nome: 'Ana Souza',
              email: 'ana@exemplo.test',
              telefone: '',
              dataCadastro: DateTime(2026, 8, 1),
              perfil: PerfilUsuario.membro,
              status: StatusUsuario.aprovado,
              igrejaPrincipalId: igrejaPrincipalId,
            ),
          ),
        );

    Override comVinculo(VinculoIgreja? vinculo) =>
        vinculoPrincipalProvider.overrideWith((ref) => Stream.value(vinculo));

    testWidgets('conta sem igreja principal não entra no aplicativo', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await montar(
        tester,
        app(
          overrides: [
            comSessao,
            comIgrejas(unidades),
            comUsuario(null),
            comVinculo(null),
          ],
        ),
      );

      expect(find.byType(SemIgrejaVinculadaScreen), findsOneWidget);
    });

    testWidgets('vínculo pendente vai para aguardando aprovação', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await montar(
        tester,
        app(
          overrides: [
            comSessao,
            comIgrejas(unidades),
            comUsuario('olinda'),
            comVinculo(
              VinculoIgreja(
                uid: 'uid-ana',
                igrejaId: olinda,
                status: StatusVinculo.pendente,
                perfil: PerfilComunitario.membro,
              ),
            ),
          ],
        ),
      );

      expect(find.byType(AguardandoAprovacaoScreen), findsOneWidget);
    });

    testWidgets('vínculo inativo vai para conta inativa', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await montar(
        tester,
        app(
          overrides: [
            comSessao,
            comIgrejas(unidades),
            comUsuario('olinda'),
            comVinculo(
              VinculoIgreja(
                uid: 'uid-ana',
                igrejaId: olinda,
                // É o estado em que a origem fica depois de uma transferência.
                status: StatusVinculo.inativo,
                perfil: PerfilComunitario.lider,
              ),
            ),
          ],
        ),
      );

      expect(find.byType(ContaInativaScreen), findsOneWidget);
    });

    testWidgets('depois da transferencia, o gate entra pela nova unidade', (
      tester,
    ) async {
      // Estado que a transferencia oficial deixa: igreja principal ja e
      // Petrolina e o vinculo la esta aprovado. A preferencia local antiga
      // ainda aponta para Olinda e nao pode segurar a pessoa la.
      SharedPreferences.setMockInitialValues({
        'igreja_visualizada_id': 'olinda',
      });

      await montar(
        tester,
        app(
          overrides: [
            comSessao,
            comIgrejas(unidades),
            comUsuario('petrolina'),
            comVinculo(
              VinculoIgreja(
                uid: 'uid-ana',
                igrejaId: petrolina,
                status: StatusVinculo.aprovado,
                perfil: PerfilComunitario.membro,
              ),
            ),
          ],
        ),
      );

      // Nenhuma tela de bloqueio: o vinculo de destino libera a entrada.
      expect(find.byType(AguardandoAprovacaoScreen), findsNothing);
      expect(find.byType(ContaInativaScreen), findsNothing);
      expect(find.byType(SemIgrejaVinculadaScreen), findsNothing);
      expect(find.byType(SelectChurchScreen), findsNothing);
    });

    testWidgets(
      'as notificacoes seguem a igreja PRINCIPAL, nao a visualizada',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final espiao = _TopicosEspiao();
        NotificationPreferences.topicos = espiao;
        addTearDown(() {
          NotificationPreferences.topicos = const TopicosFcmFirebase();
        });

        final container = ProviderContainer(
          overrides: [
            comSessao,
            comIgrejas(unidades),
            comUsuario('olinda'),
            comVinculo(
              VinculoIgreja(
                uid: 'uid-ana',
                igrejaId: olinda,
                status: StatusVinculo.aprovado,
                perfil: PerfilComunitario.membro,
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: RootGate()),
          ),
        );
        await tester.pumpAndSettle();

        expect(espiao.inscritos, [
          'igreja_olinda_transmissoes',
          'igreja_olinda_eventos',
          'igreja_olinda_comunicacoes',
        ]);

        espiao.inscritos.clear();
        espiao.cancelados.clear();

        // Visitar Petrolina e so contexto de leitura: nao pode reconfigurar de
        // forma permanente para onde as notificacoes desta pessoa vao.
        await container
            .read(igrejaVisualizadaProvider.notifier)
            .definir(petrolina);
        await tester.pumpAndSettle();

        expect(espiao.inscritos, isEmpty);
        expect(espiao.cancelados, isEmpty);
      },
    );

    testWidgets('estar visualizando outra unidade não muda a decisão do gate', (
      tester,
    ) async {
      // Visitando Petrolina, mas o vínculo oficial é de Olinda e está
      // pendente: o gate continua barrando. Ver outra igreja não libera nada.
      SharedPreferences.setMockInitialValues({
        'igreja_visualizada_id': 'petrolina',
      });

      await montar(
        tester,
        app(
          overrides: [
            comSessao,
            comIgrejas(unidades),
            comUsuario('olinda'),
            comVinculo(
              VinculoIgreja(
                uid: 'uid-ana',
                igrejaId: olinda,
                status: StatusVinculo.pendente,
                perfil: PerfilComunitario.membro,
              ),
            ),
          ],
        ),
      );

      expect(find.byType(AguardandoAprovacaoScreen), findsOneWidget);
    });

    testWidgets(
      'lider sem vinculo na unidade visitada recebe navegacao de membro',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final container = ProviderContainer(
          overrides: [
            comSessao,
            comIgrejas(unidades),
            comUsuario('olinda'),
            comVinculo(
              VinculoIgreja(
                uid: 'uid-ana',
                igrejaId: olinda,
                status: StatusVinculo.aprovado,
                perfil: PerfilComunitario.lider,
              ),
            ),
            vinculoAtualProvider.overrideWith((ref) => Stream.value(null)),
          ],
        );
        addTearDown(container.dispose);

        await montar(
          tester,
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: RootGate()),
          ),
        );

        expect(find.byType(HomeLeaderScreen), findsOneWidget);

        // A visita acontece depois de a sessão já estar estabelecida, como no
        // botão "Trocar igreja" das configurações.
        await container
            .read(igrejaVisualizadaProvider.notifier)
            .definir(petrolina);
        await tester.pumpAndSettle();

        expect(find.byType(HomeMemberScreen), findsOneWidget);
        expect(find.byType(HomeLeaderScreen), findsNothing);
      },
    );
  });
}

/// Observa as inscricoes de topico sem precisar do Firebase.
class _TopicosEspiao implements TopicosFcm {
  final inscritos = <String>[];
  final cancelados = <String>[];

  @override
  Future<void> inscrever(String topico) async => inscritos.add(topico);

  @override
  Future<void> cancelar(String topico) async => cancelados.add(topico);
}

/// `User` mínimo: o gate só precisa saber que existe uma sessão.
class _UsuarioFake extends Fake implements User {
  @override
  String get uid => 'uid-ana';

  @override
  bool get isAnonymous => false;
}

class _UsuarioAnonimoFake extends Fake implements User {
  @override
  String get uid => 'uid-visitante';

  @override
  bool get isAnonymous => true;
}
