import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/core/theme/app_theme.dart';
import 'package:nova_alianca_app/features/igrejas/providers/igreja_providers.dart';
import 'package:nova_alianca_app/visual/screens/select_church_screen.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

void main() {
  final unidades = <IgrejaModel>[
    IgrejaModel(
      id: IgrejaId('olinda'),
      nome: 'Comunidade Nova Aliança Olinda',
      ativa: true,
      configurada: true,
      endereco: 'Rua São José, 10',
      cidadeEstado: 'Olinda — PE',
    ),
    IgrejaModel(
      id: IgrejaId('petrolina'),
      nome: 'Comunidade Nova Aliança Petrolina',
      ativa: true,
      configurada: true,
      endereco: 'Avenida Central, 20',
      cidadeEstado: 'Petrolina — PE',
    ),
  ];

  Override comIgrejas(List<IgrejaModel> igrejas) => igrejasAtivasProvider
      .overrideWith((ref) => Stream<List<IgrejaModel>>.value(igrejas));

  Override comErro(Object erro) => igrejasAtivasProvider.overrideWith(
    (ref) => Stream<List<IgrejaModel>>.error(erro),
  );

  Widget app(Override override, {double textScale = 1}) {
    return ProviderScope(
      overrides: [override],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const SelectChurchScreen(),
      ),
    );
  }

  Future<void> montar(
    WidgetTester tester,
    Override override, {
    Size tamanho = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = tamanho;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(override, textScale: textScale));
    await tester.pumpAndSettle();
  }

  testWidgets('busca nome e endereço ignorando acentos, caixa e espaços', (
    tester,
  ) async {
    await montar(tester, comIgrejas(unidades));

    final busca = find.byKey(const Key('select-church-search-field'));
    await tester.enterText(busca, '  SAO JOSE  ');
    await tester.pumpAndSettle();

    expect(find.text('Comunidade Nova Aliança Olinda'), findsOneWidget);
    expect(find.text('Comunidade Nova Aliança Petrolina'), findsNothing);

    await tester.enterText(busca, 'PETRO');
    await tester.pumpAndSettle();

    expect(find.text('Comunidade Nova Aliança Petrolina'), findsOneWidget);
    expect(find.text('Comunidade Nova Aliança Olinda'), findsNothing);
  });

  testWidgets('campo não herda borda e preenchimento duplicados do tema', (
    tester,
  ) async {
    await montar(tester, comIgrejas(unidades));

    final campo = tester.widget<TextField>(
      find.byKey(const Key('select-church-search-field')),
    );
    final decoracao = campo.decoration!;

    expect(decoracao.border, InputBorder.none);
    expect(decoracao.enabledBorder, InputBorder.none);
    expect(decoracao.focusedBorder, InputBorder.none);
    expect(decoracao.disabledBorder, InputBorder.none);
    expect(decoracao.errorBorder, InputBorder.none);
    expect(decoracao.focusedErrorBorder, InputBorder.none);
    expect(decoracao.filled, isFalse);
    expect(decoracao.contentPadding, EdgeInsets.zero);
    expect(decoracao.hintText, 'Nome ou endereço');
  });

  testWidgets('erro de permissão não acusa falsamente a internet', (
    tester,
  ) async {
    await montar(
      tester,
      comErro(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      ),
    );

    expect(
      find.text('Lista de igrejas temporariamente indisponível'),
      findsOneWidget,
    );
    expect(find.textContaining('Não foi possível acessar'), findsOneWidget);
    expect(find.textContaining('Verifique sua conexão'), findsNothing);
  });

  testWidgets('indisponibilidade de rede recebe orientação de conexão', (
    tester,
  ) async {
    await montar(
      tester,
      comErro(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      ),
    );

    expect(find.text('Sem conexão com o serviço'), findsOneWidget);
    expect(find.textContaining('conexão com a internet'), findsOneWidget);
  });

  testWidgets('largura pequena mantém busca legível e sem controle morto', (
    tester,
  ) async {
    await montar(
      tester,
      comIgrejas(unidades),
      tamanho: const Size(320, 720),
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
    final campo = tester.widget<TextField>(
      find.byKey(const Key('select-church-search-field')),
    );
    expect(campo.decoration?.hintText, 'Nome ou endereço');
    expect(find.text('Usar localização atual'), findsNothing);
  });
}
