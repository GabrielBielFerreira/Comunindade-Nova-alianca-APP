class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o e-mail';
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$', caseSensitive: false);
    if (!regex.hasMatch(value.trim())) return 'E-mail inválido';
    return null;
  }

  static String? senha(String? value) {
    if (value == null || value.isEmpty) return 'Informe a senha';
    if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }

  static String? confirmarSenha(String? value, String senha) {
    if (value == null || value.isEmpty) return 'Confirme a senha';
    if (value != senha) return 'As senhas não coincidem';
    return null;
  }

  static String? nome(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o nome completo';
    if (value.trim().split(' ').length < 2) return 'Informe nome e sobrenome';
    return null;
  }

  static String? telefone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o telefone';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Telefone inválido';
    return null;
  }

  static String? obrigatorio(String? value, {String campo = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) return '$campo é obrigatório';
    return null;
  }

  static String? valor(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o valor';
    final limpo = value.replaceAll(RegExp(r'[^\d,.]'), '').replaceAll(',', '.');
    final num = double.tryParse(limpo);
    if (num == null || num <= 0) return 'Valor inválido';
    return null;
  }
}
