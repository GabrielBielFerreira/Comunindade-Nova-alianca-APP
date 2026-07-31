import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/fcm_service.dart';
import '../data/auth_service.dart';
import '../data/usuario_model.dart';
import 'auth_provider.dart';

/// Ações de autenticação usadas pela camada de apresentação.
///
/// Centraliza login, cadastro, recuperação de senha e logout, garantindo que
/// o logout também desative o token FCM do dispositivo. As telas chamam estes
/// métodos dentro de try/catch e traduzem erros com [mensagemErroAuth].
class AuthActions {
  AuthActions(this._auth);

  final AuthService _auth;

  Future<void> login({required String email, required String senha}) {
    return _auth.login(email, senha);
  }

  Future<void> cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    QualificacaoUsuario? qualificacao,
  }) {
    return _auth.cadastrar(
      email: email,
      senha: senha,
      nome: nome,
      telefone: telefone,
      qualificacao: qualificacao,
    );
  }

  Future<void> recuperarSenha(String email) {
    return _auth.esqueciSenha(email);
  }

  /// Retorna `false` se o usuário cancelar o fluxo do Google (sem erro).
  Future<bool> entrarComGoogle() async {
    final cred = await _auth.entrarComGoogle();
    return cred != null;
  }

  /// Logout completo: desativa o token FCM do dispositivo antes de encerrar a
  /// sessão para não continuar recebendo notificações após sair.
  Future<void> sair() async {
    // A desativação do token FCM depende de rede (getToken + Firestore) e pode
    // demorar/travar; ela NUNCA deve bloquear o logout. Limitamos o tempo e
    // ignoramos falhas — o token é reconciliado no próximo login.
    try {
      await FcmService.desativarToken()
          .timeout(const Duration(seconds: 3), onTimeout: () {});
    } catch (_) {
      // Timeout/falha ao desativar token não deve impedir o logout.
    }
    await _auth.logout();
  }
}

final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref.watch(authServiceProvider));
});
