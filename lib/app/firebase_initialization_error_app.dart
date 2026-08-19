import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Tela segura exibida quando a configuração ou a inicialização obrigatória do
/// Firebase falha. Não recebe a exceção para impedir vazamento de detalhes de
/// configuração, chaves ou infraestrutura na interface de produção.
class FirebaseInitializationErrorApp extends StatelessWidget {
  const FirebaseInitializationErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nova Aliança',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined, size: 56),
                  SizedBox(height: 24),
                  Text(
                    'Não foi possível iniciar o aplicativo',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Os serviços essenciais não puderam ser carregados. '
                    'Feche e abra o aplicativo novamente. Se o problema '
                    'continuar, entre em contato com o suporte.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
