import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/root_gate.dart';
import 'core/services/navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'features/palavra_dia/palavra_dia_watcher.dart';
import 'firebase_options.dart';
import 'visual/visual_router.dart';

/// Handler de mensagens FCM recebidas com o app em background/terminado.
/// Precisa ser uma função top-level anotada com vm:entry-point.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // O sistema já exibe a notificação; aqui apenas garantimos o isolate.
  // Processamento adicional (ex.: pré-carregar dados) pode ser feito aqui.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega os dados de localização pt_BR usados por DateFormat/NumberFormat
  // em todo o app (formatters, Palavra do Dia, agenda...). Sem isto, qualquer
  // tela que formata data/moeda com o locale 'pt_BR' lança LocaleDataException
  // e quebra — foi o que travou a Home. Precisa vir ANTES do runApp.
  await initializeDateFormatting('pt_BR', null);

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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Relatório de erros em produção (desligado em modo debug para não poluir).
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Erros de widget/framework do Flutter.
    FlutterError.onError = crashlytics.recordFlutterFatalError;

    // Erros assíncronos não capturados (fora da árvore de widgets).
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
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
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      // Localização pt-BR: traduz componentes nativos do Material (date picker,
      // seletor de hora, tooltips de navegação) para o português.
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
          // Mantém a Palavra do Dia atualizada (abrir/retornar/virada do dia).
          child: PalavraDiaWatcher(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
