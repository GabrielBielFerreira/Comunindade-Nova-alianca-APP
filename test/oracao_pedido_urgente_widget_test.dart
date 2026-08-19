import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/features/auth/providers/auth_controller.dart';
import 'package:nova_alianca_app/features/auth/providers/auth_provider.dart';
import 'package:nova_alianca_app/features/oracao/data/oracao_repository.dart';
import 'package:nova_alianca_app/features/oracao/providers/oracao_providers.dart';
import 'package:nova_alianca_app/visual/screens/oracao_pedido_urgente_screen.dart';

void main() {
  testWidgets('pedido urgente persiste no repositório antes de confirmar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final repository = _OracaoRepositoryFake();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(_UsuarioAnonimoFake()),
          ),
          authActionsProvider.overrideWith((ref) => _AuthActionsFake()),
          oracaoRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: const MaterialApp(
          home: OracaoPedidoUrgenteScreen(isLeader: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'Minha família precisa de ajuda agora.',
    );
    await tester.tap(find.text('Hospitalização'));
    await tester.ensureVisible(find.text('Enviar pedido'));
    await tester.pumpAndSettle();
    final enviar = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Enviar pedido'),
    );
    enviar.onPressed!();
    await tester.pumpAndSettle();

    expect(repository.chamadas, 1);
    expect(repository.autorId, 'uid-visitante');
    expect(repository.autorNome, 'Visitante');
    expect(repository.texto, 'Minha família precisa de ajuda agora.');
    expect(repository.privado, isTrue);
    expect(repository.anonimo, isTrue);
    expect(repository.urgente, isTrue);
    expect(repository.categoria, 'Hospitalização');
  });
}

class _UsuarioAnonimoFake extends Fake implements User {
  @override
  String get uid => 'uid-visitante';

  @override
  bool get isAnonymous => true;

  @override
  String? get displayName => null;
}

class _AuthActionsFake extends Fake implements AuthActions {
  @override
  Future<String> garantirUsuario() async => 'uid-visitante';
}

class _OracaoRepositoryFake extends Fake implements OracaoRepository {
  int chamadas = 0;
  String? autorId;
  String? autorNome;
  String? texto;
  bool? privado;
  bool? anonimo;
  bool? urgente;
  String? categoria;

  @override
  Future<void> criarPedido({
    required String autorId,
    required String autorNome,
    required String texto,
    required bool privado,
    bool anonimo = false,
    bool urgente = false,
    String? categoria,
    bool solicitaVisita = false,
    bool solicitaLigacao = false,
  }) async {
    chamadas++;
    this.autorId = autorId;
    this.autorNome = autorNome;
    this.texto = texto;
    this.privado = privado;
    this.anonimo = anonimo;
    this.urgente = urgente;
    this.categoria = categoria;
  }
}
