import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_theme.dart';

/// Tela de placeholder usada durante o desenvolvimento.
/// Substituída pela implementação real em fases posteriores.
class PlaceholderTela extends StatelessWidget {
  final String titulo;
  final IconData? icone;

  const PlaceholderTela({
    super.key,
    required this.titulo,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo.toUpperCase())),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone ?? Icons.construction_rounded,
              size: 64,
              color: AppColors.primarySoft,
            ),
            const SizedBox(height: 16),
            Text(
              titulo.toUpperCase(),
              style: AppTextTheme.h3.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Em desenvolvimento',
              style: AppTextTheme.bodySm.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
