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

  /// Páginas públicas exigidas para transparência e publicação nas lojas.
  /// Podem ser trocadas por domínio próprio sem alterar o código.
  static const String politicaPrivacidadeUrl = String.fromEnvironment(
    'POLITICA_PRIVACIDADE_URL',
    defaultValue: 'https://nova-alianca-app.web.app/privacidade',
  );

  static const String exclusaoContaUrl = String.fromEnvironment(
    'EXCLUSAO_CONTA_URL',
    defaultValue: 'https://nova-alianca-app.web.app/excluir-conta',
  );

  static const String termosUsoUrl = String.fromEnvironment(
    'TERMOS_USO_URL',
    defaultValue: 'https://nova-alianca-app.web.app/termos',
  );

  /// Habilita recursos multi-igreja (seleção/troca de igreja). Desligado por
  /// padrão: a V1 é exclusiva da Comunidade Nova Aliança.
  static const bool multiIgrejaHabilitada = bool.fromEnvironment(
    'MULTI_IGREJA',
    defaultValue: false,
  );

  /// Provedor da Bíblia (agnóstico). Padrão: bible-api.com, gratuito e sem
  /// chave de API. A tradução padrão é a João Ferreira de Almeida (domínio
  /// público). Configuráveis por --dart-define para trocar provedor/tradução.
  static const String bibleApiBaseUrl = String.fromEnvironment(
    'BIBLE_API_BASE_URL',
    defaultValue: 'https://bible-api.com',
  );

  static const String bibleTranslation = String.fromEnvironment(
    'BIBLE_TRANSLATION',
    defaultValue: 'almeida',
  );

  /// Habilita pagamentos online (PIX dinâmico / cartão / boleto via Cloud
  /// Functions do Mercado Pago). Desligado por padrão: enquanto as Functions
  /// não estiverem publicadas, o app mantém o PIX manual honesto.
  static const bool pagamentosOnlineHabilitado = bool.fromEnvironment(
    'PAGAMENTOS_ONLINE',
    defaultValue: false,
  );

  /// Região das Cloud Functions.
  static const String functionsRegion = 'southamerica-east1';

  /// URL oficial do app (página de instalação / loja), usada na legenda e no
  /// card de compartilhamento da Palavra do Dia.
  ///
  /// PONTO DE CONFIGURAÇÃO DO LINK OFICIAL:
  ///  - Preferencialmente, defina em runtime no Firestore:
  ///    `configuracoes/app` → campo `url_oficial` (permite trocar sem publicar
  ///    nova versão). Ver [PalavraDoDia]/serviço de compartilhamento.
  ///  - Ou em tempo de build: `--dart-define=APP_URL=https://...`.
  ///
  /// Vazio por padrão de propósito: enquanto não houver endereço oficial, o
  /// compartilhamento NÃO inclui link (nunca um link falso/provisório).
  static const String appOfficialUrl = String.fromEnvironment(
    'APP_URL',
    defaultValue: '',
  );

  /// Escola de Louvor: só aparece na Home quando houver conteúdo configurado.
  /// Desligada por padrão (evita atalho morto). Ative com
  /// --dart-define=ESCOLA_LOUVOR=true quando o conteúdo estiver no Firebase.
  static const bool escolaDeLouvorHabilitada = bool.fromEnvironment(
    'ESCOLA_LOUVOR',
    defaultValue: false,
  );
}
