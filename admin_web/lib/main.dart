import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/ambiente.dart';
import 'rotas.dart';
import 'ui/tema.dart';

/// Painel administrativo da rede Nova Aliança (Flutter Web).
///
/// O ambiente vem de `--dart-define=APP_ENV`. O padrão é produção, de modo que
/// um build feito sem a flag jamais aponta para o emulador — e um build local
/// jamais grava em produção por descuido.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: ConfiguracaoFirebase.opcoes);

  // Condicao `const`: num build de producao este bloco inteiro sai do bundle.
  if (AmbientePainel.emuladorEmTempoDeBuild) {
    await ConfiguracaoFirebase.conectarAoEmulador();
    debugPrint('Painel conectado ao EMULADOR (${ConfiguracaoFirebase.host}).');
  }

  runApp(const ProviderScope(child: PainelApp()));
}

class PainelApp extends ConsumerWidget {
  const PainelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Painel de Gestão — Nova Aliança',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: TemaPainel.claro(),
    );
  }
}
