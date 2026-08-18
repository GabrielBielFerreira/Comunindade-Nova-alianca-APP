import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/fcm_service.dart';
import '../data/auth_service.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

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

  /// Cadastro vinculado a uma unidade. Sem igreja nao ha vinculo, e sem
  /// vinculo o cadastro nao aparece para nenhuma lideranca aprovar.
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required IgrejaId igrejaId,
    QualificacaoUsuario? qualificacao,
  }) {
    return _auth.cadastrar(
      email: email,
      senha: senha,
      nome: nome,
      telefone: telefone,
      igrejaId: igrejaId,
      qualificacao: qualificacao,
    );
  }

  Future<void> recuperarSenha(String email) {
    return _auth.esqueciSenha(email);
  }

  /// Indica se a conta atual já entra por e-mail/senha (senão, só Google).
  bool get possuiSenha => _auth.possuiSenhaEmail;

  /// Define/adiciona senha de e-mail na conta atual (sem remover o Google).
  Future<void> definirSenha(String senha) => _auth.definirSenha(senha);

  /// Retorna `false` se o usuário cancelar o fluxo do Google (sem erro).
  /// [igrejaId] so e usado no PRIMEIRO acesso; nos seguintes e ignorado.
  /// Sem ele, um primeiro acesso lanca [IgrejaObrigatoriaNoCadastro] e a tela
  /// leva o usuario a escolher a unidade antes de concluir.
  Future<bool> entrarComGoogle({IgrejaId? igrejaId}) async {
    final cred = await _auth.entrarComGoogle(igrejaId: igrejaId);
    return cred != null;
  }

  /// Garante um uid (sessão existente ou anônima) para ações abertas a
  /// visitantes, como enviar pedido de oração.
  Future<String> garantirUsuario() => _auth.garantirUsuario();

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
