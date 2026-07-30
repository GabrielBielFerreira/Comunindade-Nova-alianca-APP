import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../data/devocional_model.dart';
import '../providers/devocionais_providers.dart';

class DevocionaisScreen extends ConsumerWidget {
  const DevocionaisScreen({super.key});

  void _abrir(BuildContext context, DevocionalModel d) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DevocionalDetalheScreen(devocional: d)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(devocionaisStreamProvider);
    final destaque = ref.watch(devocionalDestaqueProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text('Devocionais',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700, color: AppColors.primary)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Não foi possível carregar os devocionais.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedForeground)),
          ),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories_outlined,
                        size: 48, color: AppColors.mutedForeground),
                    SizedBox(height: 16),
                    Text('Nenhum devocional publicado ainda.',
                        style: TextStyle(color: AppColors.mutedForeground)),
                  ],
                ),
              ),
            );
          }
          final outros =
              lista.where((d) => d.id != destaque?.id).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (destaque != null) ...[
                _DestaqueCard(devocional: destaque, onTap: () => _abrir(context, destaque)),
                const SizedBox(height: 20),
                if (outros.isNotEmpty)
                  Text('Anteriores',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground)),
                const SizedBox(height: 8),
              ],
              for (final d in outros)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    title: Text(d.titulo,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    subtitle: Text('${d.autor} • ${Formatters.data(d.data)}',
                        style: const TextStyle(color: AppColors.mutedForeground)),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.mutedForeground),
                    onTap: () => _abrir(context, d),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DestaqueCard extends StatelessWidget {
  const _DestaqueCard({required this.devocional, required this.onTap});
  final DevocionalModel devocional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DEVOCIONAL DO DIA',
                  style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(devocional.titulo,
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(devocional.corpo,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, height: 1.5)),
              const SizedBox(height: 12),
              Text('${devocional.autor} • ${Formatters.data(devocional.data)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class DevocionalDetalheScreen extends StatelessWidget {
  const DevocionalDetalheScreen({super.key, required this.devocional});
  final DevocionalModel devocional;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text('Devocional',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700, color: AppColors.primary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar',
            onPressed: () => Share.share(
                '${devocional.titulo}\n\n${devocional.corpo}\n\n— ${devocional.autor}'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(devocional.titulo,
              style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 6),
          Text('${devocional.autor} • ${Formatters.data(devocional.data)}',
              style: const TextStyle(color: AppColors.mutedForeground)),
          if (devocional.referencia != null &&
              devocional.referencia!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(devocional.referencia!,
                style: const TextStyle(
                    color: AppColors.primary, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 20),
          Text(devocional.corpo,
              style: const TextStyle(
                  fontSize: 17, height: 1.7, color: AppColors.foreground)),
        ],
      ),
    );
  }
}
