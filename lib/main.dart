import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/root_gate.dart';
import 'core/theme/app_theme.dart';
import 'visual/visual_router.dart';

// Descomentar após rodar `flutterfire configure` (gera lib/firebase_options.dart):
// import 'firebase_options.dart';

/// Handler de mensagens FCM recebidas com o app em background/terminado.
/// Precisa ser uma função top-level anotada com vm:entry-point.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // O sistema já exibe a notificação; aqui apenas garantimos o isolate.
  // Processamento adicional (ex.: pré-carregar dados) pode ser feito aqui.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Firebase é obrigatório em produção. Enquanto google-services.json /
  // firebase_options.dart não estiverem configurados, a inicialização falha —
  // o app ainda abre (degradado) e o RootGate exibe a tela pública.
  try {
    // Após `flutterfire configure`, prefira:
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Falha ao inicializar o Firebase: $e');
  }

  runApp(const ProviderScope(child: NovaAliancaApp()));
}

class NovaAliancaApp extends StatelessWidget {
  const NovaAliancaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nova Aliança',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // A rota raiz '/' é o RootGate (decide a tela por sessão/perfil). As
      // demais rotas nomeadas vêm do mapa visual; a tela de login continua
      // acessível em '/login' (VisualRoutes.login).
      initialRoute: VisualRoutes.entraconta,
      routes: {
        ...visualRoutes,
        VisualRoutes.entraconta: (_) => const RootGate(),
      },
      builder: (context, child) {
        // Acessibilidade: respeita o tamanho de fonte do sistema, mas limita a
        // faixa para preservar o layout aprovado (substitui o antigo
        // TextScaler.noScaling, que ignorava a preferência do usuário).
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
