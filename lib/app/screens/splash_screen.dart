import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tela de carregamento exibida enquanto o estado de autenticação e o perfil
/// do usuário são resolvidos.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.mensagem});

  final String? mensagem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            if (mensagem != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  mensagem!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
