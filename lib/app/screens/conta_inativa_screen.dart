import '../../features/igrejas/providers/igreja_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_controller.dart';
import '../../visual/visual_router.dart';

/// Exibida quando o usuário está autenticado mas com status `inativo`.
class ContaInativaScreen extends ConsumerWidget {
  const ContaInativaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.errorSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 44,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Conta inativa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sua conta está inativa. Entre em contato com a liderança da '
                '${ref.watch(nomeIgrejaEmFocoProvider)} para reativá-la.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.mutedForeground,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await ref.read(authActionsProvider).sair();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      VisualRoutes.entraconta,
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  AppStrings.sair,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
