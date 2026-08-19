import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../campanhas/data/campanha_model.dart';
import '../../campanhas/providers/campanhas_providers.dart';
import 'campanha_form_screen.dart';

/// Gestão de Campanhas dentro do app: criar, editar, excluir. Escrita restrita
/// à liderança pelas regras do Firestore.
class GerenciarCampanhasScreen extends ConsumerWidget {
  const GerenciarCampanhasScreen({super.key});

  void _mostrar(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _abrirForm(BuildContext context,
      {CampanhaModel? campanha}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CampanhaFormScreen(campanha: campanha)),
    );
  }

  Future<void> _confirmarExcluir(
      BuildContext context, WidgetRef ref, CampanhaModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir campanha'),
        content: Text('Remover "${c.titulo}" definitivamente?'),
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
      // Encerra em vez de apagar: o histórico da campanha é preservado.
      await ref
          .read(campanhasRepositoryProvider)
          .definirStatus(c.id, 'encerrada');
      mensagem = 'Campanha encerrada.';
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
    final async = ref.watch(campanhasGerenciarProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Gerenciar campanhas',
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
        label: const Text('Nova campanha'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar as campanhas. Verifique sua conexão '
              'e seu perfil de liderança.',
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
            itemBuilder: (context, i) => _CampanhaCard(
              campanha: lista[i],
              onEditar: () => _abrirForm(context, campanha: lista[i]),
              onExcluir: () => _confirmarExcluir(context, ref, lista[i]),
            ),
          );
        },
      ),
    );
  }
}

class _CampanhaCard extends StatelessWidget {
  const _CampanhaCard({
    required this.campanha,
    required this.onEditar,
    required this.onExcluir,
  });

  final CampanhaModel campanha;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final ativa = campanha.status == StatusCampanha.ativa;
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ativa ? AppColors.successSoft : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  ativa ? 'Ativa' : 'Encerrada',
                  style: TextStyle(
                    color: ativa
                        ? AppColors.success
                        : AppColors.mutedForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                Formatters.data(campanha.dataInicio),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            campanha.titulo,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: campanha.progresso,
              minHeight: 8,
              backgroundColor: AppColors.surfaceMuted,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${Formatters.moeda(campanha.arrecadadoReais)} de '
            '${Formatters.moeda(campanha.metaReais)}',
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
            const Icon(Icons.volunteer_activism_outlined,
                size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma campanha ainda.\nCrie a primeira.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCriar,
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add),
              label: const Text('Nova campanha'),
            ),
          ],
        ),
      ),
    );
  }
}
