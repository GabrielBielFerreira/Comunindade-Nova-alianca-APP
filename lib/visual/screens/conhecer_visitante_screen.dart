import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/igreja_info.dart';
import '../mock_data.dart';
import '../widgets/visitor_bottom_navigation.dart';

/// Tela "Conhecer" do visitante (Sobre nós).
///
/// Placeholder on-brand com dados públicos da igreja ([IgrejaInfo]).
/// Usa a [VisitorBottomNavigation] (item "Conhecer" ativo), mantendo o
/// visitante dentro da sua própria navegação.
class ConhecerVisitanteScreen extends StatelessWidget {
  const ConhecerVisitanteScreen({super.key});

  static const _designWidth = 394.0;
  static const _background = Color(0xFFFAFAFA);
  static const _topTitle = Color(0xFF510014);
  static const _hero = Color(0xFF510014);
  static const _primary = Color(0xFF7A0022);
  static const _title = Color(0xFF1A1A1A);
  static const _body = Color(0xFF584142);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);

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
                  .clamp(0.86, 1.0)
                  .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;
              final navHeight = 72 * scale + bottomPadding;

              return Stack(
                children: [
                  Column(
                    children: [
                      _Header(scale: scale, topPadding: topPadding),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            20 * scale,
                            16 * scale,
                            navHeight + 20 * scale,
                          ),
                          child: _Content(scale: scale),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: VisitorBottomNavigation(
                      activeItem: VisitorNavItem.conhecer,
                      scale: scale,
                      bottomPadding: bottomPadding,
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

class _Header extends StatelessWidget {
  const _Header({required this.scale, required this.topPadding});

  final double scale;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * scale + topPadding,
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ConhecerVisitanteScreen._line)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8 * scale),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(
                Icons.arrow_back,
                size: 22 * scale,
                color: ConhecerVisitanteScreen._topTitle,
              ),
            ),
            SizedBox(width: 4 * scale),
            Text(
              'Conhecer',
              style: GoogleFonts.montserrat(
                fontSize: 18 * scale,
                fontWeight: FontWeight.w700,
                color: ConhecerVisitanteScreen._topTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cartão hero com logo + nome + slogan.
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24 * scale),
          decoration: BoxDecoration(
            color: ConhecerVisitanteScreen._hero,
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
                IgrejaInfo.nome,
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
                IgrejaInfo.slogan,
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
          'É uma alegria ter você por aqui! Somos uma comunidade que vive '
          'a fé em Jesus, cultivando comunhão, discipulado e propósito. '
          'Venha nos visitar em um de nossos cultos — você será muito '
          'bem-vindo(a).',
          style: GoogleFonts.inter(
            fontSize: 15 * scale,
            fontWeight: FontWeight.w400,
            height: 23 / 15,
            color: ConhecerVisitanteScreen._body,
          ),
        ),
        SizedBox(height: 24 * scale),
        _SectionTitle('Horários de culto', scale: scale),
        SizedBox(height: 12 * scale),
        for (final culto in IgrejaInfo.cultos) ...[
          _InfoTile(
            scale: scale,
            icon: Icons.event,
            title: culto['nome'] ?? '',
            subtitle:
                '${_formatDay(culto['dia'])} • ${culto['horario'] ?? ''}',
          ),
          SizedBox(height: 10 * scale),
        ],
        SizedBox(height: 14 * scale),
        _SectionTitle('Onde estamos', scale: scale),
        SizedBox(height: 12 * scale),
        _InfoTile(
          scale: scale,
          icon: Icons.location_on_outlined,
          title: IgrejaInfo.cidadeEstado,
          subtitle: IgrejaInfo.endereco,
        ),
        SizedBox(height: 10 * scale),
        _InfoTile(
          scale: scale,
          icon: Icons.camera_alt_outlined,
          title: 'Instagram',
          subtitle: IgrejaInfo.instagram,
        ),
      ],
    );
  }

  static String _formatDay(String? dia) {
    switch (dia) {
      case 'domingo':
        return 'Domingo';
      case 'segunda':
        return 'Segunda-feira';
      case 'terca':
        return 'Terça-feira';
      case 'quarta':
        return 'Quarta-feira';
      case 'quinta':
        return 'Quinta-feira';
      case 'sexta':
        return 'Sexta-feira';
      case 'sabado':
        return 'Sábado';
      default:
        return dia ?? '';
    }
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
        color: ConhecerVisitanteScreen._title,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.scale,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ConhecerVisitanteScreen._line),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44 * scale,
            height: 44 * scale,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: ConhecerVisitanteScreen._soft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22 * scale,
              color: ConhecerVisitanteScreen._primary,
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
                    color: ConhecerVisitanteScreen._title,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w400,
                    height: 19 / 13,
                    color: ConhecerVisitanteScreen._muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
