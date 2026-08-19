import 'package:admin_web/dados/acessos.dart';
import 'package:admin_web/dados/conteudo_repository.dart';
import 'package:admin_web/dados/membros_repository.dart';
import 'package:admin_web/estado/providers.dart';
import 'package:admin_web/telas/lideranca_tela.dart';
import 'package:admin_web/ui/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import 'responsivo.dart';

/// Registra a chamada em vez de ir ao servidor. O teste do painel verifica o
/// que a interface ENVIA; quem prova o efeito no Firestore é
/// `functions/test/transferencia.test.js`.
class _RepositorioEspiao extends MembrosRepository {
  Map<String, Object?>? enviado;
  int chamadas = 0;

  @override
  Future<void> transferir({
    required IgrejaId igrejaOrigemId,
    required IgrejaId igrejaDestinoId,
    required String uid,
    required String motivo,
    bool confirmarSaidaDePastor = false,
  }) async {
    chamadas++;
    enviado = {
      'igrejaOrigemId': igrejaOrigemId.valor,
      'igrejaDestinoId': igrejaDestinoId.valor,
      'uid': uid,
      'motivo': motivo,
      'confirmarSaidaDePastor': confirmarSaidaDePastor,
    };
  }
}

final _olinda = IgrejaId('olinda');
final _petrolina = IgrejaId('petrolina');

final _unidades = <IgrejaModel>[
  IgrejaModel(id: _olinda, nome: 'Nova Aliança Olinda', ativa: true),
  IgrejaModel(id: _petrolina, nome: 'Nova Aliança Petrolina', ativa: true),
];

AcessoIgreja _acesso() => AcessoIgreja(
  igrejaId: _olinda,
  nome: 'Nova Aliança Olinda',
  ativa: true,
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

MembroPainel _membro({
  String uid = 'uid-ana',
  String nome = 'Ana Souza',
  PerfilComunitario perfil = PerfilComunitario.membro,
}) {
  return MembroPainel(
    nome: nome,
    vinculo: VinculoIgreja(
      uid: uid,
      igrejaId: _olinda,
      status: StatusVinculo.aprovado,
      perfil: perfil,
    ),
  );
}

Widget _tela({
  required bool isSuperAdmin,
  required MembrosRepository repositorio,
  List<MembroPainel>? membros,
}) {
  final acesso = _acesso();
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(null)),
      meusAcessosProvider.overrideWith(
        (ref) async => MeusAcessos(
          uid: 'uid-quem-administra',
          isSuperAdmin: isSuperAdmin,
          acessos: [acesso],
        ),
      ),
      acessoAtualProvider.overrideWithValue(acesso),
      membrosRepositoryProvider.overrideWithValue(repositorio),
      igrejasProvider.overrideWith((ref) => Stream.value(_unidades)),
      membrosProvider.overrideWith(
        (ref) => Stream.value(
          Pagina(itens: membros ?? [_membro()], truncada: false),
        ),
      ),
    ],
    child: MaterialApp(
      theme: TemaPainel.claro(),
      home: const Scaffold(body: LiderancaTela()),
    ),
  );
}

Future<void> _montar(WidgetTester tester, Widget widget) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(1440, 900);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

/// Preenche destino, motivo e confirmações do diálogo já aberto.
Future<void> _preencherDialogo(
  WidgetTester tester, {
  required String destino,
  required String motivo,
  bool confirmarTodas = true,
}) async {
  await tester.tap(find.byType(DropdownButtonFormField<IgrejaId>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(destino).last);
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField), motivo);
  await tester.pumpAndSettle();

  if (confirmarTodas) {
    for (final caixa in find.byType(CheckboxListTile).evaluate().toList()) {
      await tester.tap(find.byWidget(caixa.widget));
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  group('Ação de transferir entre igrejas no painel', () {
    testWidgets('pastor da unidade não vê a ação', (tester) async {
      await _montar(
        tester,
        _tela(isSuperAdmin: false, repositorio: _RepositorioEspiao()),
      );

      // As demais ações de liderança continuam disponíveis a ele.
      expect(find.text('Desvincular'), findsOneWidget);
      expect(find.text('Transferir para outra igreja'), findsNothing);
    });

    testWidgets('super_admin vê a ação', (tester) async {
      await _montar(
        tester,
        _tela(isSuperAdmin: true, repositorio: _RepositorioEspiao()),
      );

      expect(find.text('Transferir para outra igreja'), findsOneWidget);
    });

    testWidgets('o diálogo avisa que cargos não são transportados', (
      tester,
    ) async {
      await _montar(
        tester,
        _tela(isSuperAdmin: true, repositorio: _RepositorioEspiao()),
      );

      await tester.tap(find.text('Transferir para outra igreja'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Unidade de origem: Nova Aliança Olinda'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Cargos e permissões NÃO são transportados'),
        findsOneWidget,
      );
      expect(find.textContaining('histórico preservado'), findsOneWidget);
    });

    testWidgets('não oferece a própria unidade como destino', (tester) async {
      await _montar(
        tester,
        _tela(isSuperAdmin: true, repositorio: _RepositorioEspiao()),
      );

      await tester.tap(find.text('Transferir para outra igreja'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<IgrejaId>));
      await tester.pumpAndSettle();

      expect(find.text('Nova Aliança Petrolina'), findsWidgets);
      expect(find.text('Nova Aliança Olinda'), findsNothing);
    });

    testWidgets('confirmar fica bloqueado sem destino, motivo e aceite', (
      tester,
    ) async {
      final repo = _RepositorioEspiao();
      await _montar(tester, _tela(isSuperAdmin: true, repositorio: repo));

      await tester.tap(find.text('Transferir para outra igreja'));
      await tester.pumpAndSettle();

      FilledButton confirmar() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Transferir'),
      );

      expect(confirmar().onPressed, isNull, reason: 'nada preenchido');

      await tester.tap(find.byType(DropdownButtonFormField<IgrejaId>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nova Aliança Petrolina').last);
      await tester.pumpAndSettle();
      expect(confirmar().onPressed, isNull, reason: 'ainda sem motivo');

      await tester.enterText(
        find.byType(TextField),
        'Mudanca de cidade da familia',
      );
      await tester.pumpAndSettle();
      expect(confirmar().onPressed, isNull, reason: 'ainda sem confirmação');

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(confirmar().onPressed, isNotNull);

      expect(repo.chamadas, 0, reason: 'nada foi enviado antes de confirmar');
    });

    testWidgets('envia uid, origem, destino e motivo ao servidor', (
      tester,
    ) async {
      final repo = _RepositorioEspiao();
      await _montar(tester, _tela(isSuperAdmin: true, repositorio: repo));

      await tester.tap(find.text('Transferir para outra igreja'));
      await tester.pumpAndSettle();
      await _preencherDialogo(
        tester,
        destino: 'Nova Aliança Petrolina',
        motivo: 'Mudanca de cidade confirmada pela familia',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Transferir'));
      await tester.pumpAndSettle();

      expect(repo.chamadas, 1);
      expect(repo.enviado, {
        'igrejaOrigemId': 'olinda',
        'igrejaDestinoId': 'petrolina',
        'uid': 'uid-ana',
        'motivo': 'Mudanca de cidade confirmada pela familia',
        'confirmarSaidaDePastor': false,
      });
      expect(find.textContaining('Vínculo transferido'), findsOneWidget);
    });

    testWidgets('cancelar não envia nada', (tester) async {
      final repo = _RepositorioEspiao();
      await _montar(tester, _tela(isSuperAdmin: true, repositorio: repo));

      await tester.tap(find.text('Transferir para outra igreja'));
      await tester.pumpAndSettle();
      await _preencherDialogo(
        tester,
        destino: 'Nova Aliança Petrolina',
        motivo: 'Mudanca de cidade confirmada pela familia',
      );

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.chamadas, 0);
    });

    testWidgets('pastor exige confirmação extra da saída', (tester) async {
      final repo = _RepositorioEspiao();
      await _montar(
        tester,
        _tela(
          isSuperAdmin: true,
          repositorio: repo,
          membros: [
            _membro(
              uid: 'uid-pastor-ana',
              nome: 'Pastora Ana',
              perfil: PerfilComunitario.pastor,
            ),
          ],
        ),
      );

      await tester.tap(find.text('Transferir para outra igreja'));
      await tester.pumpAndSettle();

      expect(find.textContaining('pode ficar sem pastor'), findsOneWidget);
      // Duas confirmações: a da transferência e a da saída do pastor.
      expect(find.byType(CheckboxListTile), findsNWidgets(2));

      await _preencherDialogo(
        tester,
        destino: 'Nova Aliança Petrolina',
        motivo: 'Assumira o pastoreio da unidade de destino',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Transferir'));
      await tester.pumpAndSettle();

      expect(repo.enviado?['confirmarSaidaDePastor'], true);
      expect(repo.enviado?['uid'], 'uid-pastor-ana');
    });
  });

  group('Responsividade da transferencia', () {
    paraCadaTamanho('a tela de lideranca com a acao nao estoura', (
      tester,
      tamanho,
      escala,
    ) async {
      await esperarSemOverflow(
        tester,
        _tela(isSuperAdmin: true, repositorio: _RepositorioEspiao()),
        tamanho: tamanho,
        escalaTexto: escala,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    paraCadaTamanho('o dialogo de transferencia nao estoura', (
      tester,
      tamanho,
      escala,
    ) async {
      await esperarSemOverflow(
        tester,
        _tela(isSuperAdmin: true, repositorio: _RepositorioEspiao()),
        tamanho: tamanho,
        escalaTexto: escala,
      );
      await tester.pumpAndSettle();

      // Em tela pequena o cartao fica abaixo da dobra e o ListView nem o
      // constroi: e preciso rolar ate ele antes de tocar.
      final botao = find.text('Transferir para outra igreja');
      await tester.scrollUntilVisible(botao, 200);
      await tester.pumpAndSettle();
      await tester.tap(botao);
      await tester.pumpAndSettle();

      expect(find.textContaining('Unidade de origem'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
