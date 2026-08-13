import 'package:firebase_auth/firebase_auth.dart';

/// Converte erros técnicos do Firebase Auth em mensagens amigáveis em PT-BR.
///
/// Nunca expõe códigos internos do Firebase ao usuário final. Use em toda a
/// camada de apresentação de autenticação (login, cadastro, recuperação).
String mensagemErroAuth(Object erro) {
  if (erro is FirebaseAuthException) {
    switch (erro.code) {
      case 'invalid-email':
        return 'E-mail inválido. Verifique e tente novamente.';
      case 'user-disabled':
        return 'Esta conta está desativada. Fale com a liderança.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        // Caso frequente: a conta foi criada com "Continuar com Google" e não
        // tem senha de e-mail. Digitar e-mail/senha sempre cai aqui. Por isso
        // orientamos explicitamente o botão do Google em vez de só "incorretos".
        return 'E-mail ou senha incorretos. Se você criou a conta com o '
            'Google, entre pelo botão "Continuar com Google".';
      case 'email-already-in-use':
        return 'Já existe uma conta com este e-mail.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'operation-not-allowed':
        return 'Cadastro por e-mail está indisponível no momento.';
      case 'requires-recent-login':
        return 'Por segurança, entre novamente com o Google e repita a '
            'operação.';
      case 'provider-already-linked':
      case 'credential-already-in-use':
        return 'Esta conta já tem uma senha de acesso cadastrada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente de novo.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede.';
      default:
        return 'Não foi possível concluir. Tente novamente.';
    }
  }
  return 'Ocorreu um erro inesperado. Tente novamente.';
}
