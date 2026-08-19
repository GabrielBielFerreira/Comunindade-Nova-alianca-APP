import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../../features/igrejas/providers/igreja_providers.dart';
import '../mock_data.dart';
import '../widgets/internal_header.dart';
import '../escala_tela.dart';

/// "Sobre a Comunidade" — tela interna (push) acessível a membros e liderança
/// pelo menu "Mais". Apresenta dados públicos reais da igreja ([IgrejaInfo]):
/// boas-vindas, horários de culto, endereço (abre mapa) e Instagram (abre app).
class SobreComunidadeScreen extends StatelessWidget {
  const SobreComunidadeScreen({super.key});

  static const _designWidth = 394.0;
  static const _background = Color(0xFFFAFAFA);
  static const _hero = Color(0xFF510014);
  static const _primary = Color(0xFF7A0022);
  static const _title = Color(0xFF1A1A1A);
  static const _body = Color(0xFF584142);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);

  Future<void> _abrir(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  .clamp(escalaMinima, 1.0)
                  .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;

              return Column(
                children: [
                  InternalHeader(
                    title: 'Sobre a Comunidade',
                    scale: scale,
                    topPadding: topPadding,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16 * scale,
                        20 * scale,
                        16 * scale,
                        bottomPadding + 24 * scale,
                      ),
                      child: _Content(scale: scale, abrir: _abrir),
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
}

class _Content extends ConsumerWidget {
  const _Content({required this.scale, required this.abrir});

  final double scale;
  final Future<void> Function(String url) abrir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final igreja = ref.watch(igrejaAtualDadosProvider).valueOrNull;
    final mapaUrl = igreja?.mapaUrl;
    final pastores = igreja?.pastoresExibicao ?? const <String>[];
    final enderecos = igreja?.enderecosExibicao ?? const <String>[];
    final cultos = igreja?.cultosRecorrentes ?? const <String>[];
    const naoInformado = 'Não informado';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24 * scale),
          decoration: BoxDecoration(
            color: SobreComunidadeScreen._hero,
            borderRadius: BorderRadius.circular(16 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: Offset(0, 1 * scale),
                blurRadius: 2 * scale,
              ),
            ],
          ),
          child: Column(
            children: [
              ClipOval(
                child: Image.asset(
                  HomeAssets.logo,
                  width: 64 * scale,
                  height: 64 * scale,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              SizedBox(height: 12 * scale),
              Text(
                igreja?.nome ?? naoInformado,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w700,
                  height: 28 / 22,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6 * scale),
              Text(
                igreja?.slogan ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w400,
                  height: 21 / 14,
                  color: Colors.white.withValues(alpha: 0.80),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24 * scale),
        _SectionTitle('Boas-vindas', scale: scale),
        SizedBox(height: 8 * scale),
        Text(
          'Somos uma comunidade que vive a fé em Jesus, cultivando comunhão, '
          'discipulado e propósito. Nosso desejo é que você encontre aqui um '
          'lugar de crescimento espiritual e de serviço ao Reino.',
          style: GoogleFonts.inter(
            fontSize: 15 * scale,
            fontWeight: FontWeight.w400,
            height: 23 / 15,
            color: SobreComunidadeScreen._body,
          ),
        ),
        SizedBox(height: 24 * scale),
        _SectionTitle(
          pastores.length > 1 ? 'Pastores' : 'Pastor',
          scale: scale,
        ),
        SizedBox(height: 12 * scale),
        // Sem nome confirmado, diz que não sabe — nunca elege um pastor.
        if (pastores.isEmpty)
          _InfoTile(
            scale: scale,
            icon: Icons.person_outline,
            title: naoInformado,
            subtitle: 'Liderança ainda não cadastrada no aplicativo',
          )
        else
          for (final pastor in pastores) ...[
            _InfoTile(
              scale: scale,
              icon: Icons.person_outline,
              title: pastor,
              subtitle: pastores.length > 1
                  ? 'Liderança pastoral'
                  : 'Pastor responsável',
            ),
            SizedBox(height: 10 * scale),
          ],
        SizedBox(height: 24 * scale),
        _SectionTitle('Horários de culto', scale: scale),
        SizedBox(height: 12 * scale),
        if (cultos.isEmpty)
          _InfoTile(
            scale: scale,
            icon: Icons.event,
            title: naoInformado,
            subtitle: 'Programação ainda não cadastrada',
          )
        else
          for (final culto in cultos) ...[
            _InfoTile(scale: scale, icon: Icons.event, title: culto),
            SizedBox(height: 10 * scale),
          ],
        SizedBox(height: 14 * scale),
        _SectionTitle('Onde estamos', scale: scale),
        SizedBox(height: 12 * scale),
        if (enderecos.isEmpty)
          _InfoTile(
            scale: scale,
            icon: Icons.location_on_outlined,
            title: igreja?.cidadeEstado ?? naoInformado,
            subtitle: 'Endereço ainda não cadastrado',
          )
        else
          for (var i = 0; i < enderecos.length; i++) ...[
            _InfoTile(
              scale: scale,
              icon: Icons.location_on_outlined,
              title: i == 0
                  ? (igreja?.cidadeEstado ?? 'Endereço principal')
                  : 'Outro endereço',
              subtitle: enderecos[i],
              // Link de mapa só no principal, e só se houver endereço.
              onTap: (i == 0 && mapaUrl != null) ? () => abrir(mapaUrl) : null,
            ),
            SizedBox(height: 10 * scale),
          ],
        if (igreja?.instagram != null) ...[
          SizedBox(height: 10 * scale),
          _InfoTile(
            scale: scale,
            icon: Icons.camera_alt_outlined,
            title: 'Instagram',
            subtitle: igreja!.instagram!,
            onTap: () => abrir(
              'https://instagram.com/'
              '${igreja.instagram!.replaceAll('@', '')}',
            ),
          ),
        ],
        if (igreja?.youtubeUrl != null) ...[
          SizedBox(height: 10 * scale),
          _InfoTile(
            scale: scale,
            icon: Icons.play_circle_outline,
            title: 'YouTube',
            subtitle: 'Assistir aos cultos',
            onTap: () => abrir(igreja!.youtubeUrl!),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.montserrat(
        fontSize: 16 * scale,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4 * scale,
        color: SobreComunidadeScreen._title,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.scale,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.onTap,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SobreComunidadeScreen._line),
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: Offset(0, 1 * scale),
            blurRadius: 1 * scale,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44 * scale,
            height: 44 * scale,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: SobreComunidadeScreen._soft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22 * scale,
              color: SobreComunidadeScreen._primary,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w600,
                    height: 20 / 15,
                    color: SobreComunidadeScreen._title,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w400,
                    height: 19 / 13,
                    color: SobreComunidadeScreen._muted,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 22 * scale,
              color: SobreComunidadeScreen._muted,
            ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(16 * scale),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
