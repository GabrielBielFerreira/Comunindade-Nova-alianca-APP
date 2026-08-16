import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/emulador.dart';
import 'rotas.dart';

/// Painel administrativo da rede Nova Aliança (Flutter Web).
///
/// Nesta fase o painel roda EXCLUSIVAMENTE contra o Firebase Emulator Suite.
/// Não há configuração de produção: `firebase_options.dart` ainda não foi
/// gerado, e inventar credenciais seria pior que não tê-las.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: ConfiguracaoEmulador.opcoes);
  await ConfiguracaoEmulador.conectar();

  runApp(const ProviderScope(child: PainelApp()));
}

class PainelApp extends ConsumerWidget {
  const PainelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Painel Nova Aliança',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7A0022),
          brightness: Brightness.light,
        ),
      ),
    );
  }
}
