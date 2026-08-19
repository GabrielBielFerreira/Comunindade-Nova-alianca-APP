import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Ambiente do painel, escolhido em tempo de build:
///
/// ```
/// flutter run   -d chrome --dart-define=APP_ENV=emulator
/// flutter build web --release --dart-define=APP_ENV=production
/// ```
///
/// O padrão é `production`: um build sem a flag NUNCA aponta para localhost.
enum AmbientePainel {
  emulator,
  production;

  static const String _bruto = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  /// Decisão de ambiente em tempo de COMPILAÇÃO.
  ///
  /// Precisa ser `const`, e não `final`: com um valor apenas `final` o
  /// compilador não consegue provar qual ramo do `opcoes` será usado e mantém
  /// os DOIS no bundle. O resultado era um `main.dart.js` de produção
  /// carregando `demo-nova-alianca`, `fake-api-key` e `localhost` como dados
  /// mortos — inofensivos em execução, mas suficientes para cegar a
  /// verificação que procura exatamente essas marcas num artefato publicado.
  ///
  /// Por ser `const`, a comparação é literal: use exatamente `emulator`,
  /// `emulador`, `dev` ou `local`. Qualquer outra grafia cai em produção, que
  /// falha alto por falta das variáveis em vez de conectar no lugar errado.
  static const bool emuladorEmTempoDeBuild =
      _bruto == 'emulator' ||
      _bruto == 'emulador' ||
      _bruto == 'dev' ||
      _bruto == 'local';

  /// Derivado do mesmo `const`, para rótulo e configuração nunca divergirem.
  static const AmbientePainel atual = emuladorEmTempoDeBuild
      ? AmbientePainel.emulator
      : AmbientePainel.production;

  bool get isEmulador => this == AmbientePainel.emulator;
  bool get isProducao => this == AmbientePainel.production;

  String get rotulo => switch (this) {
    AmbientePainel.emulator => 'AMBIENTE LOCAL (EMULADOR)',
    AmbientePainel.production => 'Produção',
  };
}

/// Atalho de leitura para a interface.
final AmbientePainel ambienteAtual = AmbientePainel.atual;

/// Projeto Firebase real do produto.
const String projetoFirebaseProducao = 'nova-alianca-app';

/// Configuração do Firebase para o painel.
class ConfiguracaoFirebase {
  const ConfiguracaoFirebase._();

  static const String regiaoFunctions = 'southamerica-east1';

  // ── Emulador ────────────────────────────────────────────────────────
  static const String host = 'localhost';
  static const int portaAuth = 9099;
  static const int portaFirestore = 8080;
  static const int portaFunctions = 5001;

  /// Projeto de demonstração: o prefixo `demo-` faz o Firebase operar sem
  /// backend real. Nada aqui é credencial de produção.
  static const String projectIdDemo = 'demo-nova-alianca';

  static const FirebaseOptions opcoesEmulador = FirebaseOptions(
    apiKey: 'fake-api-key-emulador',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: projectIdDemo,
    storageBucket: '$projectIdDemo.appspot.com',
  );

  // ── Produção ────────────────────────────────────────────────────────
  //
  // Injetadas em tempo de build a partir da saída do `flutterfire configure`
  // para o app Web de `nova-alianca-app`. Não ficam no repositório: um build
  // de produção sem elas falha de forma explícita, em vez de silenciosamente
  // apontar para o lugar errado.
  //
  //   flutter build web --release \
  //     --dart-define=APP_ENV=production \
  //     --dart-define=FB_API_KEY=... \
  //     --dart-define=FB_APP_ID=... \
  //     --dart-define=FB_SENDER_ID=... \
  //     --dart-define=FB_PROJECT_ID=nova-alianca-app \
  //     --dart-define=FB_AUTH_DOMAIN=nova-alianca-app.firebaseapp.com \
  //     --dart-define=FB_STORAGE_BUCKET=nova-alianca-app.firebasestorage.app
  static const String _apiKey = String.fromEnvironment('FB_API_KEY');
  static const String _appId = String.fromEnvironment('FB_APP_ID');
  static const String _senderId = String.fromEnvironment('FB_SENDER_ID');
  static const String _projectId = String.fromEnvironment('FB_PROJECT_ID');
  static const String _authDomain = String.fromEnvironment('FB_AUTH_DOMAIN');
  static const String _storageBucket = String.fromEnvironment(
    'FB_STORAGE_BUCKET',
  );

  static bool get producaoConfigurada =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _senderId.isNotEmpty &&
      _projectId.isNotEmpty &&
      _authDomain.isNotEmpty &&
      _storageBucket.isNotEmpty;

  static FirebaseOptions get opcoesProducao {
    if (!producaoConfigurada) {
      throw StateError(
        'Configuração de produção ausente.\n'
        'Gere os valores com `flutterfire configure --project=nova-alianca-app` '
        'e passe-os por --dart-define (FB_API_KEY, FB_APP_ID, FB_SENDER_ID, '
        'FB_PROJECT_ID, FB_AUTH_DOMAIN, FB_STORAGE_BUCKET).\n'
        'Para desenvolvimento local use --dart-define=APP_ENV=emulator.',
      );
    }
    // Fail-closed: valores presentes mas apontando para o emulador/projeto
    // errado são tão perigosos quanto valores ausentes.
    if (_projectId != projetoFirebaseProducao) {
      throw StateError(
        'FB_PROJECT_ID e "$_projectId", esperado "$projetoFirebaseProducao". '
        'Um painel de producao nao pode subir apontando para outro projeto.',
      );
    }
    if (_apiKey.contains('fake')) {
      throw StateError('FB_API_KEY e a chave falsa do emulador.');
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _senderId,
      projectId: _projectId,
      authDomain: _authDomain,
      storageBucket: _storageBucket,
    );
  }

  /// A condicao e `const`: o compilador remove do bundle o ramo que nao vale
  /// para este build.
  static FirebaseOptions get opcoes =>
      AmbientePainel.emuladorEmTempoDeBuild ? opcoesEmulador : opcoesProducao;

  /// Liga os SDKs ao Emulator Suite. Só roda em `APP_ENV=emulator`.
  static Future<void> conectarAoEmulador() async {
    await FirebaseAuth.instance.useAuthEmulator(host, portaAuth);

    FirebaseFirestore.instance.useFirestoreEmulator(host, portaFirestore);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );

    FirebaseFunctions.instanceFor(
      region: regiaoFunctions,
    ).useFunctionsEmulator(host, portaFunctions);
  }
}
