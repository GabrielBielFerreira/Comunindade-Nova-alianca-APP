import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../features/igrejas/providers/igreja_providers.dart';

/// Card "Abrir painel de gestão".
///
/// Regras que este widget cumpre:
///
/// - só aparece quando `Autorizacao.podeAcessarPainel` for verdadeiro na
///   unidade em foco — o que inclui liderança ministerial, tesoureiro, editor
///   e moderador de oração, e exclui membro comum e visitante;
/// - abre [AppConfig.gestaoPanelUrl] no navegador EXTERNO;
/// - não faz login automático: o painel tem autenticação própria, e passar
///   credencial por URL seria vazá-la no histórico do navegador;
/// - quando a URL não está configurada, diz isso em vez de abrir nada.
class AbrirPainelCard extends ConsumerWidget {
  const AbrirPainelCard({super.key, required this.scale});

  final double scale;

  static const _primary = Color(0xFF7A0022);
  static const _muted = Color(0xFF6B7280);
  static const _soft = Color(0xFFF5E6EC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autorizacao = ref.watch(autorizacaoAtualProvider);

    // Sem autorização na unidade em foco o card não existe. Um membro que
    // visita outra igreja também não vê — lá ele não tem vínculo.
    if (autorizacao == null || !autorizacao.podeAcessarPainel) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16 * scale),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scale),
        child: InkWell(
          borderRadius: BorderRadius.circular(12 * scale),
          onTap: () => _abrir(context),
          child: Container(
            padding: EdgeInsets.all(16 * scale),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: Row(
              children: [
                Container(
                  width: 40 * scale,
                  height: 40 * scale,
                  decoration: const BoxDecoration(
                    color: _soft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.dashboard_outlined,
                    size: 20 * scale,
                    color: _primary,
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Abrir painel de gestão',
                        style: GoogleFonts.montserrat(
                          fontSize: 15 * scale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        'Abre no navegador, com login próprio',
                        style: GoogleFonts.inter(
                          fontSize: 12 * scale,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new, size: 18 * scale, color: _primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrir(BuildContext context) async {
    final url = AppConfig.gestaoPanelUrl.trim();

    if (url.isEmpty) {
      _avisar(
        context,
        'O endereço do painel ainda não foi configurado nesta versão do '
        'aplicativo. Fale com a equipe responsável.',
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      _avisar(context, 'O endereço do painel configurado é inválido.');
      return;
    }

    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && context.mounted) {
      _avisar(context, 'Não foi possível abrir o navegador.');
    }
  }

  void _avisar(BuildContext context, String mensagem) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
      );
  }
}
