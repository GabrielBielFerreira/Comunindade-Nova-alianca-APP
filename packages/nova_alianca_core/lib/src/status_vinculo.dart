import 'normalizacao.dart';

/// Situação do vínculo de uma pessoa com uma unidade.
enum StatusVinculo {
  /// Cadastro aguardando aprovação da liderança da unidade.
  pendente,

  /// Vínculo ativo. Único status que concede qualquer acesso.
  aprovado,

  /// Vínculo encerrado. O documento é PRESERVADO (histórico), mas não concede
  /// acesso algum — nem para quem tinha perfil de liderança.
  inativo;

  String get valor => name;

  static StatusVinculo deTexto(String? bruto) {
    if (bruto == null) return StatusVinculo.pendente;
    final chave = normalizarChave(bruto);
    for (final status in StatusVinculo.values) {
      if (status.name == chave) return status;
    }
    return StatusVinculo.pendente;
  }

  bool get isAprovado => this == StatusVinculo.aprovado;

  String get rotulo => switch (this) {
        StatusVinculo.pendente => 'Pendente',
        StatusVinculo.aprovado => 'Aprovado',
        StatusVinculo.inativo => 'Inativo',
      };
}
