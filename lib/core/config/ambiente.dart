import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Ambiente de execução, escolhido em tempo de build:
///
/// ```
/// flutter run   --dart-define=APP_ENV=emulator
/// flutter build --dart-define=APP_ENV=production
/// ```
///
/// O padrão é `production`: um build feito sem a flag NUNCA aponta para
/// localhost por acidente. O emulador é sempre uma escolha explícita.
enum Ambiente {
  emulator,
  production;

  static const String _bruto = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static final Ambiente atual = switch (_bruto.toLowerCase().trim()) {
    'emulator' || 'emulador' || 'dev' || 'local' => Ambiente.emulator,
    _ => Ambiente.production,
  };

  bool get isEmulador => this == Ambiente.emulator;
  bool get isProducao => this == Ambiente.production;

  String get rotulo => switch (this) {
        Ambiente.emulator => 'AMBIENTE LOCAL (EMULADOR)',
        Ambiente.production => 'Produção',
      };
}

/// Projeto Firebase real do produto.
const String projetoFirebaseProducao = 'nova-alianca-app';

/// Recusa iniciar um build de produção com configuração de emulador.
///
/// Complementa `scripts/verificar_producao.js`: a trava de build impede gerar
/// o artefato errado; esta impede que um artefato errado, gerado fora do fluxo
/// oficial, converse com o projeto errado em silêncio.
///
/// Em `APP_ENV=emulator` não faz nada — ali apontar para `demo-` é o correto.
void exigirConfiguracaoDeProducao(FirebaseOptions opcoes) {
  if (Ambiente.atual.isEmulador) return;

  final problemas = <String>[
    if (opcoes.projectId != projetoFirebaseProducao)
      'projectId e "${opcoes.projectId}", esperado "$projetoFirebaseProducao"',
    if (opcoes.apiKey.contains('fake')) 'apiKey e a chave falsa do emulador',
    if (opcoes.projectId.startsWith('demo-'))
      'projectId aponta para um projeto de demonstracao',
  ];

  if (problemas.isEmpty) return;

  throw StateError(
    'Build marcado como PRODUCAO com configuracao invalida:\n'
    '  - ${problemas.join('\n  - ')}\n'
    'Gere a configuracao real com:\n'
    '  flutterfire configure --project=$projetoFirebaseProducao\n'
    'Ou rode explicitamente contra o emulador:\n'
    '  --dart-define=APP_ENV=emulator',
  );
}

/// Endereço do Emulator Suite. Só é usado quando [Ambiente.atual] é `emulator`.
class HostsEmulador {
  const HostsEmulador._();

  /// No Android, `localhost` aponta para o próprio aparelho/emulador Android;
  /// `10.0.2.2` é o atalho do AVD para a máquina hospedeira.
  static String get host {
    const configurado = String.fromEnvironment('EMULATOR_HOST');
    if (configurado.isNotEmpty) return configurado;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static const int auth = 9099;
  static const int firestore = 8080;
  static const int functions = 5001;
  static const int storage = 9199;

  /// Projeto de demonstração. O prefixo `demo-` faz o Firebase operar sem
  /// backend real, então nada aqui alcança produção.
  static const String projectIdDemo = 'demo-nova-alianca';

  static const FirebaseOptions opcoesDemo = FirebaseOptions(
    apiKey: 'fake-api-key-emulador',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: projectIdDemo,
    storageBucket: '$projectIdDemo.appspot.com',
  );
}

/// Liga os SDKs ao Emulator Suite. Chamada apenas em `APP_ENV=emulator`.
Future<void> conectarAoEmulador() async {
  final host = HostsEmulador.host;

  await FirebaseAuth.instance.useAuthEmulator(host, HostsEmulador.auth);

  FirebaseFirestore.instance.useFirestoreEmulator(host, HostsEmulador.firestore);
  // Persistência desligada evita cache local mascarar erro de regra durante
  // os testes manuais.
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: false);

  FirebaseFunctions.instanceFor(region: 'southamerica-east1')
      .useFunctionsEmulator(host, HostsEmulador.functions);
}
