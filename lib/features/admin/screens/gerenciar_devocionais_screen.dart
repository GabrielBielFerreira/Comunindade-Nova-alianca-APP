import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../devocionais/data/devocional_model.dart';
import '../../devocionais/providers/devocionais_providers.dart';
import 'devocional_form_screen.dart';

/// Gestão de Devocionais dentro do app: criar, editar, excluir. Escrita
/// restrita à liderança pelas regras do Firestore.
class GerenciarDevocionaisScreen extends ConsumerWidget {
  const GerenciarDevocionaisScreen({super.key});

  void _mostrar(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _abrirForm(BuildContext context,
      {DevocionalModel? devocional}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => DevocionalFormScreen(devocional: devocional)),
    );
  }

  Future<void> _confirmarExcluir(
      BuildContext context, WidgetRef ref, DevocionalModel d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir devocional'),
        content: Text('Remover "${d.titulo}" definitivamente?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    String mensagem;
    try {
      await ref.read(devocionaisRepositoryProvider).excluir(d.id);
      mensagem = 'Devocional excluído.';
    } on FirebaseException catch (e) {
      mensagem = e.code == 'permission-denied'
          ? 'Sem permissão para esta ação. Confirme seu perfil de liderança.'
          : 'Falha no servidor (${e.code}). Tente novamente.';
    } catch (_) {
      mensagem = 'Sem conexão ou falha temporária. Tente novamente.';
    }
    if (context.mounted) _mostrar(context, mensagem);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(devocionaisStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Gerenciar devocionais',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _abrirForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo devocional'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar os devocionais. Verifique sua '
              'conexão e seu perfil de liderança.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground),
            ),
          ),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return _Vazio(onCriar: () => _abrirForm(context));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: lista.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _DevocionalCard(
              devocional: lista[i],
              onEditar: () => _abrirForm(context, devocional: lista[i]),
              onExcluir: () => _confirmarExcluir(context, ref, lista[i]),
            ),
          );
        },
      ),
    );
  }
}

class _DevocionalCard extends StatelessWidget {
  const _DevocionalCard({
    required this.devocional,
    required this.onEditar,
    required this.onExcluir,
  });

  final DevocionalModel devocional;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (devocional.destaque) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Destaque',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                Formatters.data(devocional.data),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          if (devocional.destaque) const SizedBox(height: 8),
          Text(
            devocional.titulo,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            devocional.referencia?.isNotEmpty == true
                ? '${devocional.autor} · ${devocional.referencia}'
                : devocional.autor,
            style: const TextStyle(
                color: AppColors.mutedForeground, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onExcluir,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
                tooltip: 'Excluir',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio({required this.onCriar});

  final VoidCallback onCriar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined,
                size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: 16),
            const Text(
              'Nenhum devocional ainda.\nPublique o primeiro.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCriar,
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add),
              label: const Text('Novo devocional'),
            ),
          ],
        ),
      ),
    );
  }
}
