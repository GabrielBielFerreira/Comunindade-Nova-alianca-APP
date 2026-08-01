import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_controller.dart';
import '../../visual/visual_router.dart';

/// Exibida quando o usuário está autenticado mas com cadastro `pendente`.
class AguardandoAprovacaoScreen extends ConsumerWidget {
  const AguardandoAprovacaoScreen({super.key});

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
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.aguardandoAprovacao,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.aguardandoAprovacaoDesc,
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
