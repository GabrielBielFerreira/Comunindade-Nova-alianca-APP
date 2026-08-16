import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../features/notificacoes/data/notificacao_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/notificacoes/providers/notificacoes_providers.dart';
import '../widgets/internal_header.dart';

/// Central de Notificações (membro e liderança) — separada de Avisos.
///
/// Lista as notificações pessoais do usuário (Firestore), com estado
/// lido/não lido. A entrega de push (FCM) que cria estes registros depende de
/// Cloud Functions no backend (ver STATUS_FINAL_CNA_APP.md).
class NotificacoesScreen extends ConsumerWidget {
  const NotificacoesScreen({super.key});

  static const _designWidth = 394.0;
  static const _background = Color(0xFFFAFAFA);
  static const _muted = Color(0xFF6B7280);
  static const _primary = Color(0xFF7A0022);
  static const _soft = Color(0xFFF5E6EC);
  static const _line = Color(0xFFE5E7EB);
  static const _title = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificacoesStreamProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = (constraints.maxWidth / _designWidth)
                  .clamp(0.86, 1.0)
                  .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;

              return Column(
                children: [
                  InternalHeader(
                    title: 'Notificações',
                    scale: scale,
                    topPadding: topPadding,
                  ),
                  Expanded(
                    child: async.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => _vazio(scale, 'Não foi possível carregar.'),
                      data: (lista) {
                        if (lista.isEmpty) {
                          return _vazio(scale, 'Nenhuma notificação');
                        }
                        return ListView.separated(
                          padding: EdgeInsets.all(16 * scale),
                          itemCount: lista.length,
                          separatorBuilder: (_, _) => SizedBox(height: 10 * scale),
                          itemBuilder: (context, i) =>
                              _NotificacaoTile(notificacao: lista[i], scale: scale),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _vazio(double scale, String texto) => Center(
        child: Text(
          texto,
          style: GoogleFonts.inter(
            fontSize: 16 * scale,
            color: _muted,
          ),
        ),
      );
}

class _NotificacaoTile extends ConsumerWidget {
  const _NotificacaoTile({required this.notificacao, required this.scale});

  final NotificacaoModel notificacao;
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final naoLida = !notificacao.lida;
    return Material(
      color: naoLida ? NotificacoesScreen._soft : Colors.white,
      borderRadius: BorderRadius.circular(12 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(12 * scale),
        onTap: () {
          final uid = ref.read(authStateProvider).valueOrNull?.uid;
          if (naoLida && uid != null) {
            ref
                .read(notificacoesRepositoryProvider)
                .marcarLida(uid, notificacao.id);
          }
        },
        child: Container(
          padding: EdgeInsets.all(14 * scale),
          decoration: BoxDecoration(
            border: Border.all(color: NotificacoesScreen._line),
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (naoLida)
                Container(
                  margin: EdgeInsets.only(top: 6 * scale, right: 10 * scale),
                  width: 8 * scale,
                  height: 8 * scale,
                  decoration: const BoxDecoration(
                    color: NotificacoesScreen._primary,
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificacao.titulo,
                      style: GoogleFonts.inter(
                        fontSize: 15 * scale,
                        fontWeight:
                            naoLida ? FontWeight.w700 : FontWeight.w500,
                        color: NotificacoesScreen._title,
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      notificacao.corpo,
                      style: GoogleFonts.inter(
                        fontSize: 13 * scale,
                        color: NotificacoesScreen._muted,
                      ),
                    ),
                    SizedBox(height: 6 * scale),
                    Text(
                      Formatters.dataRelativa(notificacao.criadoEm),
                      style: GoogleFonts.inter(
                        fontSize: 11 * scale,
                        color: NotificacoesScreen._muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
