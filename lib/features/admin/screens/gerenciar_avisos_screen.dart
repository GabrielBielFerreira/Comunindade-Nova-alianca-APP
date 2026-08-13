import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../avisos/data/aviso_model.dart';
import '../../avisos/providers/avisos_providers.dart';
import 'aviso_form_screen.dart';

/// Gestão de Avisos dentro do app: a liderança publica, edita, despublica e
/// remove avisos — sem depender de um painel externo. As regras do Firestore
/// já restringem a escrita à liderança.
class GerenciarAvisosScreen extends ConsumerWidget {
  const GerenciarAvisosScreen({super.key});

  void _mostrar(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _abrirForm(BuildContext context, {AvisoModel? aviso}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AvisoFormScreen(aviso: aviso)),
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
      BuildContext context, WidgetRef ref, AvisoModel a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Excluir aviso'),
        content: Text('Remover "${a.titulo}" definitivamente?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(d).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _executar(
      context,
      () => ref.read(avisosRepositoryProvider).excluir(a.id),
      sucesso: 'Aviso excluído.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(avisosGerenciarStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Gerenciar avisos',
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
        label: const Text('Novo aviso'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar os avisos. Verifique sua conexão e '
              'seu perfil de liderança.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground),
            ),
          ),
        ),
        data: (avisos) {
          if (avisos.isEmpty) {
            return _VazioAvisos(onCriar: () => _abrirForm(context));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: avisos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _AvisoCard(
              aviso: avisos[i],
              onEditar: () => _abrirForm(context, aviso: avisos[i]),
              onExcluir: () => _confirmarExcluir(context, ref, avisos[i]),
              onAlternarAtivo: () => _executar(
                context,
                () => ref
                    .read(avisosRepositoryProvider)
                    .definirAtivo(avisos[i].id, !avisos[i].ativo),
                sucesso: avisos[i].ativo
                    ? 'Aviso despublicado.'
                    : 'Aviso publicado.',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AvisoCard extends StatelessWidget {
  const _AvisoCard({
    required this.aviso,
    required this.onEditar,
    required this.onExcluir,
    required this.onAlternarAtivo,
  });

  final AvisoModel aviso;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final VoidCallback onAlternarAtivo;

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
              if (aviso.isUrgente) ...[
                const _Etiqueta(
                    texto: 'Urgente',
                    cor: AppColors.error,
                    fundo: AppColors.errorSoft),
                const SizedBox(width: 6),
              ],
              _Etiqueta(
                texto: aviso.ativo ? 'Publicado' : 'Rascunho',
                cor: aviso.ativo ? AppColors.success : AppColors.mutedForeground,
                fundo: aviso.ativo
                    ? AppColors.successSoft
                    : AppColors.surfaceMuted,
              ),
              const Spacer(),
              Text(
                Formatters.data(aviso.publicadoEm),
                style: const TextStyle(
                    color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            aviso.titulo,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            aviso.conteudo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAlternarAtivo,
                  icon: Icon(
                    aviso.ativo
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                  label: Text(aviso.ativo ? 'Despublicar' : 'Publicar'),
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

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.cor, required this.fundo});

  final String texto;
  final Color cor;
  final Color fundo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(
            color: cor, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _VazioAvisos extends StatelessWidget {
  const _VazioAvisos({required this.onCriar});

  final VoidCallback onCriar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.campaign_outlined,
                size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: 16),
            const Text(
              'Nenhum aviso ainda.\nCrie o primeiro para os membros.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCriar,
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add),
              label: const Text('Novo aviso'),
            ),
          ],
        ),
      ),
    );
  }
}
