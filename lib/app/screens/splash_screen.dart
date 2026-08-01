import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tela de carregamento exibida enquanto o estado de autenticação e o perfil
/// do usuário são resolvidos.
class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    this.mensagem,
    this.onTentarNovamente,
    this.onSair,
  });

  final String? mensagem;

  /// Quando informado, exibe "Tentar novamente" (falha ao carregar o perfil).
  final VoidCallback? onTentarNovamente;

  /// Quando informado, exibe "Sair" — evita que o usuário fique preso na tela.
  final VoidCallback? onSair;

  @override
  Widget build(BuildContext context) {
    // "Tentar novamente" só existe no estado de ERRO — nele, não faz sentido
    // manter o indicador girando para sempre.
    final erro = onTentarNovamente != null;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (erro)
                const Icon(Icons.cloud_off_rounded,
                    color: Colors.white, size: 44)
              else
                const CircularProgressIndicator(color: Colors.white),
              if (mensagem != null) ...[
                const SizedBox(height: 20),
                Text(
                  mensagem!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
              if (onTentarNovamente != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onTentarNovamente,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('Tentar novamente'),
                ),
              ],
              if (onSair != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onSair,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Sair'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
