import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Configuração EXCLUSIVA de desenvolvimento local (Firebase Emulator Suite).
///
/// ⚠️ NÃO são credenciais de produção. O `projectId` começa com `demo-`, o que
/// faz o Firebase operar em modo demonstração: qualquer tentativa de alcançar
/// um serviço real falha por construção. A `apiKey` abaixo é um literal
/// aceito apenas pelo emulador — nada aqui dá acesso a dado real.
///
/// A configuração de produção virá de `firebase_options.dart` gerado pelo
/// FlutterFire e continuará fora do controle de versão.
class ConfiguracaoEmulador {
  const ConfiguracaoEmulador._();

  /// Prefixo `demo-` = projeto de demonstração, sem backend real.
  static const String projectId = 'demo-nova-alianca';

  static const FirebaseOptions opcoes = FirebaseOptions(
    apiKey: 'fake-api-key-emulador',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: projectId,
    storageBucket: '$projectId.appspot.com',
  );

  static const String host = 'localhost';
  static const int portaAuth = 9099;
  static const int portaFirestore = 8080;
  static const int portaFunctions = 5001;
  static const String regiaoFunctions = 'southamerica-east1';

  /// Aponta todos os SDKs para o Emulator Suite.
  static Future<void> conectar() async {
    await FirebaseAuth.instance.useAuthEmulator(host, portaAuth);

    FirebaseFirestore.instance.useFirestoreEmulator(host, portaFirestore);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );

    FirebaseFunctions.instanceFor(region: regiaoFunctions)
        .useFunctionsEmulator(host, portaFunctions);
  }
}

/// Ambiente de execução do painel.
///
/// Só existe `emulador` por enquanto: o painel ainda não tem configuração de
/// produção, e inventar uma seria pior que não ter.
enum AmbientePainel {
  emulador;

  bool get isEmulador => this == AmbientePainel.emulador;

  String get rotulo => switch (this) {
        AmbientePainel.emulador => 'AMBIENTE LOCAL (EMULADOR)',
      };
}

const AmbientePainel ambienteAtual = AmbientePainel.emulador;
