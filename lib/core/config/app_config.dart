/// Configuração de ambiente do app, injetada em tempo de build com
/// `--dart-define` (nunca contém segredos — apenas URLs/flags públicas).
///
/// Exemplo:
///   flutter run --dart-define=GESTAO_PANEL_URL=https://painel.exemplo.com
class AppConfig {
  AppConfig._();

  /// URL externa do Painel de Gestão (tela Gestão → "Abrir painel de gestão").
  /// Vazia por padrão até ser configurada pela liderança/TI.
  static const String gestaoPanelUrl = String.fromEnvironment(
    'GESTAO_PANEL_URL',
    defaultValue: '',
  );

  /// Habilita recursos multi-igreja (seleção/troca de igreja). Desligado por
  /// padrão: a V1 é exclusiva da Comunidade Nova Aliança.
  static const bool multiIgrejaHabilitada = bool.fromEnvironment(
    'MULTI_IGREJA',
    defaultValue: false,
  );
}
