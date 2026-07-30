import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../visual/visual_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../avisos/data/ministerio_model.dart';
import '../providers/ministerios_providers.dart';

/// Meu Ministério — membro vinculado vê descrição, liderança e atalhos;
/// sem vínculo, vê mensagem e opção de demonstrar interesse.
/// Não exibe informações administrativas a membros comuns.
class MeuMinisterioScreen extends ConsumerWidget {
  const MeuMinisterioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioProvider);
    final temVinculo =
        usuario?.ministerioId != null && usuario!.ministerioId!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text('Meu Ministério',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700, color: AppColors.primary)),
      ),
      body: temVinculo
          ? _ComVinculo(ref: ref)
          : const _SemVinculo(),
    );
  }
}

class _ComVinculo extends StatelessWidget {
  const _ComVinculo({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(meuMinisterioProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(
        child: Text('Não foi possível carregar seu ministério.'),
      ),
      data: (m) {
        if (m == null) return const _SemVinculo();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(m.nome,
                style: GoogleFonts.montserrat(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
            const SizedBox(height: 12),
            Text(m.descricao,
                style: const TextStyle(
                    fontSize: 15, height: 1.5, color: AppColors.foreground)),
            const SizedBox(height: 24),
            _AtalhoMinisterio(
              icone: Icons.campaign_outlined,
              titulo: 'Avisos do ministério',
              onTap: () =>
                  Navigator.pushNamed(context, VisualRoutes.avisos),
            ),
            const SizedBox(height: 12),
            _AtalhoMinisterio(
              icone: Icons.event_outlined,
              titulo: 'Programação',
              onTap: () =>
                  Navigator.pushNamed(context, VisualRoutes.programacao),
            ),
          ],
        );
      },
    );
  }
}

class _AtalhoMinisterio extends StatelessWidget {
  const _AtalhoMinisterio(
      {required this.icone, required this.titulo, required this.onTap});
  final IconData icone;
  final String titulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        leading: Icon(icone, color: AppColors.primary),
        title: Text(titulo,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        trailing:
            const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
        onTap: onTap,
      ),
    );
  }
}

class _SemVinculo extends ConsumerWidget {
  const _SemVinculo();

  Future<void> _demonstrarInteresse(
      BuildContext context, WidgetRef ref) async {
    final usuario = ref.read(usuarioProvider);
    if (usuario == null) return;
    final ministerios = ref.read(ministeriosProvider).valueOrNull ?? [];

    final escolhido = await showModalBottomSheet<MinisterioModel?>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Em qual ministério você tem interesse?',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            if (ministerios.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum ministério cadastrado ainda.'),
              ),
            for (final m in ministerios)
              ListTile(
                title: Text(m.nome),
                onTap: () => Navigator.of(sheetCtx).pop(m),
              ),
          ],
        ),
      ),
    );
    if (escolhido == null) return;

    try {
      await ref.read(ministeriosRepositoryProvider).registrarInteresse(
            uid: usuario.uid,
            nome: usuario.nome,
            ministerioId: escolhido.id,
            ministerioNome: escolhido.nome,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Interesse em "${escolhido.nome}" registrado!')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível registrar agora.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined,
                size: 56, color: AppColors.mutedForeground),
            const SizedBox(height: 16),
            Text('Você ainda não faz parte de um ministério',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.foreground)),
            const SizedBox(height: 8),
            const Text(
              'Sirva na Comunidade Nova Aliança! Demonstre interesse e a '
              'liderança entrará em contato.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => _demonstrarInteresse(context, ref),
              child: const Text('Tenho interesse'),
            ),
          ],
        ),
      ),
    );
  }
}
