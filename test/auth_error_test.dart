import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/features/auth/data/auth_error.dart';

void main() {
  group('mensagemErroAuth', () {
    test('credenciais inválidas orientam login por e-mail ou Google', () {
      final msg = mensagemErroAuth(
        FirebaseAuthException(code: 'invalid-credential'),
      );
      // Mantém a mensagem de credencial incorreta e, como contas criadas com
      // "Continuar com Google" não têm senha, orienta explicitamente o Google.
      expect(msg, contains('E-mail ou senha incorretos'));
      expect(msg, contains('Google'));
    });

    test('e-mail já em uso', () {
      final msg = mensagemErroAuth(
        FirebaseAuthException(code: 'email-already-in-use'),
      );
      expect(msg, contains('Já existe uma conta'));
    });

    test('sem rede', () {
      final msg = mensagemErroAuth(
        FirebaseAuthException(code: 'network-request-failed'),
      );
      expect(msg, contains('conexão'));
    });

    test('código desconhecido usa mensagem genérica', () {
      final msg = mensagemErroAuth(
        FirebaseAuthException(code: 'algo-estranho'),
      );
      expect(msg, 'Não foi possível concluir. Tente novamente.');
    });

    test('erro não-Firebase usa mensagem inesperada', () {
      final msg = mensagemErroAuth(Exception('boom'));
      expect(msg, contains('inesperado'));
    });

    test('nunca vaza o código técnico', () {
      final msg = mensagemErroAuth(
        FirebaseAuthException(code: 'too-many-requests'),
      );
      expect(msg.contains('too-many-requests'), isFalse);
    });
  });
}
