import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../eventos/data/evento_model.dart';
import '../../eventos/providers/eventos_providers.dart';
import 'evento_form_screen.dart';

/// Gestão da Programação dentro do app: a liderança cria, edita e remove
/// eventos. Escrita restrita à liderança pelas regras do Firestore.
class GerenciarEventosScreen extends ConsumerWidget {
  const GerenciarEventosScreen({super.key});

  void _mostrar(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _abrirForm(BuildContext context, {EventoModel? evento}) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EventoFormScreen(evento: evento)));
  }

  Future<void> _confirmarCancelamento(
    BuildContext context,
    WidgetRef ref,
    EventoModel e,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(e.cancelado ? 'Reativar evento' : 'Cancelar evento'),
        content: Text(
          e.cancelado
              ? 'Recolocar "${e.titulo}" na programação pública?'
              : 'Cancelar "${e.titulo}" e preservá-lo no histórico?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(d).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: e.cancelado
                  ? AppColors.primary
                  : AppColors.error,
            ),
            child: Text(e.cancelado ? 'Reativar' : 'Cancelar evento'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    String mensagem;
    try {
      // Cancela em vez de apagar: o histórico da programação é preservado.
      await ref
          .read(eventosRepositoryProvider)
          .definirCancelado(e.id, !e.cancelado);
      mensagem = e.cancelado ? 'Evento reativado.' : 'Evento cancelado.';
    } on FirebaseException catch (err) {
      mensagem = err.code == 'permission-denied'
          ? 'Sem permissão para esta ação. Confirme seu perfil de liderança.'
          : 'Falha no servidor (${err.code}). Tente novamente.';
    } catch (_) {
      mensagem = 'Sem conexão ou falha temporária. Tente novamente.';
    }
    if (context.mounted) _mostrar(context, mensagem);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(eventosGerenciarStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Gerenciar programação',
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
        label: const Text('Novo evento'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar a programação. Verifique sua conexão '
              'e seu perfil de liderança.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground),
            ),
          ),
        ),
        data: (eventos) {
          if (eventos.isEmpty) {
            return _VazioEventos(onCriar: () => _abrirForm(context));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: eventos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _EventoCard(
              evento: eventos[i],
              onEditar: () => _abrirForm(context, evento: eventos[i]),
              onExcluir: () => _confirmarCancelamento(context, ref, eventos[i]),
            ),
          );
        },
      ),
    );
  }
}

class _EventoCard extends StatelessWidget {
  const _EventoCard({
    required this.evento,
    required this.onEditar,
    required this.onExcluir,
  });

  final EventoModel evento;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final passado = evento.data.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    );
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
              _Etiqueta(
                texto: evento.cancelado
                    ? 'Cancelado'
                    : (passado ? 'Encerrado' : 'Próximo'),
                cor: evento.cancelado
                    ? AppColors.error
                    : (passado ? AppColors.mutedForeground : AppColors.success),
                fundo: evento.cancelado
                    ? AppColors.errorSoft
                    : (passado
                          ? AppColors.surfaceMuted
                          : AppColors.successSoft),
              ),
              if (!evento.publico) ...[
                const SizedBox(width: 6),
                const _Etiqueta(
                  texto: 'Só membros',
                  cor: AppColors.primary,
                  fundo: AppColors.primarySoft,
                ),
              ],
              const Spacer(),
              Text(
                '${Formatters.data(evento.data)} • ${evento.horario}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            evento.titulo,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            evento.local,
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 13,
            ),
          ),
          if (evento.responsavelNome.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Responsável: ${evento.responsavelNome}',
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
              IconButton(
                onPressed: onExcluir,
                icon: Icon(
                  evento.cancelado
                      ? Icons.undo_outlined
                      : Icons.cancel_outlined,
                ),
                color: evento.cancelado ? AppColors.primary : AppColors.error,
                tooltip: evento.cancelado ? 'Reativar' : 'Cancelar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({
    required this.texto,
    required this.cor,
    required this.fundo,
  });

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
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _VazioEventos extends StatelessWidget {
  const _VazioEventos({required this.onCriar});

  final VoidCallback onCriar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_outlined,
              size: 48,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum evento na programação.\nAdicione o primeiro.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCriar,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add),
              label: const Text('Novo evento'),
            ),
          ],
        ),
      ),
    );
  }
}
