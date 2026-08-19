import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../avisos/data/ministerio_model.dart';
import '../../ministerios/providers/ministerios_providers.dart';
import 'ministerio_form_screen.dart';

/// Gestão de Ministérios dentro do app: criar, editar, ativar/desativar e
/// excluir. Escrita restrita à liderança pelas regras do Firestore.
class GerenciarMinisteriosScreen extends ConsumerWidget {
  const GerenciarMinisteriosScreen({super.key});

  void _mostrar(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _abrirForm(BuildContext context,
      {MinisterioModel? ministerio}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => MinisterioFormScreen(ministerio: ministerio)),
    );
  }

  Future<void> _executar(
    BuildContext context,
    Future<void> Function() acao, {
    required String sucesso,
  }) async {
    String mensagem;
    try {
      await acao();
      mensagem = sucesso;
    } on FirebaseException catch (e) {
      mensagem = e.code == 'permission-denied'
          ? 'Sem permissão para esta ação. Confirme seu perfil de liderança.'
          : 'Falha no servidor (${e.code}). Tente novamente.';
    } catch (_) {
      mensagem = 'Sem conexão ou falha temporária. Tente novamente.';
    }
    if (!context.mounted) return;
    _mostrar(context, mensagem);
  }

  Future<void> _confirmarExcluir(
      BuildContext context, WidgetRef ref, MinisterioModel m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir ministério'),
        content: Text('Remover "${m.nome}" definitivamente?'),
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
    await _executar(
      context,
      // Inativa em vez de apagar: escalas, autoria e histórico dependem do
      // documento do ministério.
      () => ref.read(ministeriosRepositoryProvider).definirAtivo(m.id, false),
      sucesso: 'Ministério inativado.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ministeriosGerenciarProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Gerenciar ministérios',
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
        label: const Text('Novo ministério'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar os ministérios. Verifique sua '
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
            itemBuilder: (context, i) => _MinisterioCard(
              ministerio: lista[i],
              onEditar: () => _abrirForm(context, ministerio: lista[i]),
              onExcluir: () => _confirmarExcluir(context, ref, lista[i]),
              onAlternarAtivo: () => _executar(
                context,
                () => ref
                    .read(ministeriosRepositoryProvider)
                    .definirAtivo(lista[i].id, !lista[i].ativo),
                sucesso: lista[i].ativo
                    ? 'Ministério desativado.'
                    : 'Ministério ativado.',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MinisterioCard extends StatelessWidget {
  const _MinisterioCard({
    required this.ministerio,
    required this.onEditar,
    required this.onExcluir,
    required this.onAlternarAtivo,
  });

  final MinisterioModel ministerio;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final VoidCallback onAlternarAtivo;

  @override
  Widget build(BuildContext context) {
    final ativo = ministerio.ativo;
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
                  color: ativo ? AppColors.successSoft : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  ativo ? 'Ativo' : 'Inativo',
                  style: TextStyle(
                    color: ativo
                        ? AppColors.success
                        : AppColors.mutedForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (ministerio.membrosCount > 0)
                Text(
                  '${ministerio.membrosCount} '
                  '${ministerio.membrosCount == 1 ? 'membro' : 'membros'}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ministerio.nome,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            ministerio.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppColors.mutedForeground, fontSize: 13),
          ),
          if (ministerio.liderNome.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Líder: ${ministerio.liderNome}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAlternarAtivo,
                  icon: Icon(
                    ativo
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                  label: Text(ativo ? 'Desativar' : 'Ativar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.foreground,
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
            const Icon(Icons.groups_outlined,
                size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: 16),
            const Text(
              'Nenhum ministério ainda.\nCrie o primeiro.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCriar,
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add),
              label: const Text('Novo ministério'),
            ),
          ],
        ),
      ),
    );
  }
}
