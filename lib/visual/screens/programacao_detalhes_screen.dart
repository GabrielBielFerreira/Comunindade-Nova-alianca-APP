import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/igreja_info.dart';
import '../mock/programacao_mock_data.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/leader_bottom_navigation.dart';
import '../widgets/programacao_bottom_navigation.dart';

class ProgramacaoDetalhesScreen extends StatefulWidget {
  const ProgramacaoDetalhesScreen({
    super.key,
    required this.details,
    required this.isLeader,
  });

  final ProgramacaoDetalhesData details;
  final bool isLeader;

  @override
  State<ProgramacaoDetalhesScreen> createState() =>
      _ProgramacaoDetalhesScreenState();
}

class _ProgramacaoDetalhesScreenState extends State<ProgramacaoDetalhesScreen> {
  static const _designWidth = 394.0;
  static const _background = Color(0xFFFAFAFA);
  static const _primary = Color(0xFF7A0022);
  static const _darkPrimary = Color(0xFF510014);
  static const _liveBorder = Color(0xFF9B1335);
  static const _title = Color(0xFF1C1B1B);
  static const _body = Color(0xFF584142);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);

  bool _reminderEnabled = false;

  void _showMessage(String message) {
    final bottomMargin = MediaQuery.paddingOf(context).bottom + 76;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
        ),
      );
  }

  /// Abre o mapa no endereço do evento (ou da igreja, se não houver endereço).
  Future<void> _abrirMapa() async {
    final endereco = widget.details.address.trim().isNotEmpty
        ? widget.details.address
        : (widget.details.locationName.trim().isNotEmpty
            ? widget.details.locationName
            : IgrejaInfo.endereco);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(endereco)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                  .clamp(0.86, 1.0)
                  .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;
              final navigationHeight = 72 * scale + bottomPadding;

              return Stack(
                children: [
                  Column(
                    children: [
                      _DetailsHeader(
                        scale: scale,
                        topPadding: topPadding,
                        onBack: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            widget.details.hasLiveStream
                                ? 24 * scale
                                : 18 * scale,
                            16 * scale,
                            navigationHeight + 48 * scale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.details.hasLiveStream) ...[
                                _LiveCallout(
                                  scale: scale,
                                  onWatch: () => _showMessage(
                                    'Transmissão indisponível no momento.',
                                  ),
                                ),
                                SizedBox(height: 24 * scale),
                              ],
                              _EventHeading(
                                details: widget.details,
                                scale: scale,
                              ),
                              SizedBox(height: 24 * scale),
                              _AboutSection(
                                description: widget.details.description,
                                scale: scale,
                              ),
                              SizedBox(height: 24 * scale),
                              _InformationCard(
                                details: widget.details,
                                scale: scale,
                              ),
                              SizedBox(height: 24 * scale),
                              _LocationCard(
                                details: widget.details,
                                scale: scale,
                                onMap: _abrirMapa,
                              ),
                              SizedBox(height: 32 * scale),
                              _ActionButton(
                                scale: scale,
                                label: _reminderEnabled
                                    ? 'Lembrete ativado'
                                    : 'Lembrar-me',
                                iconAsset: ProgramacaoAssets.detailsBell,
                                filled: !_reminderEnabled,
                                onTap: () {
                                  setState(
                                    () => _reminderEnabled = !_reminderEnabled,
                                  );
                                  _showMessage(
                                    'Você receberá um lembrete por notificação.',
                                  );
                                },
                              ),
                              SizedBox(height: 16 * scale),
                              _ActionButton(
                                scale: scale,
                                label: 'Compartilhar',
                                iconAsset: ProgramacaoAssets.detailsShare,
                                filled: false,
                                onTap: () => Share.share(
                                  '${widget.details.title}\n'
                                  '${widget.details.dayTimeSummary}\n'
                                  '${widget.details.locationSummary}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: widget.isLeader
                        ? LeaderBottomNavigation(
                            activeItem: LeaderNavItem.schedule,
                            scale: scale,
                            bottomPadding: bottomPadding,
                          )
                        : ProgramacaoBottomNavigation(
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

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({
    required this.scale,
    required this.topPadding,
    required this.onBack,
  });

  final double scale;
  final double topPadding;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * scale + topPadding,
      padding: EdgeInsets.fromLTRB(16 * scale, topPadding, 16 * scale, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _ProgramacaoDetalhesScreenState._line),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              width: 40 * scale,
              height: 40 * scale,
              child: Center(
                child: AuthAssetImage(
                  ProgramacaoAssets.detailsBack,
                  width: 16 * scale,
                  height: 16 * scale,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Detalhes',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 20 * scale,
                fontWeight: FontWeight.w600,
                height: 28 / 20,
                color: _ProgramacaoDetalhesScreenState._darkPrimary,
              ),
            ),
          ),
          SizedBox(width: 40 * scale, height: 40 * scale),
        ],
      ),
    );
  }
}

class _LiveCallout extends StatelessWidget {
  const _LiveCallout({required this.scale, required this.onWatch});

  final double scale;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(26 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _ProgramacaoDetalhesScreenState._liveBorder,
          width: 2 * scale,
        ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: 4 * scale,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDAD6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8 * scale,
                  height: 8 * scale,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8 * scale),
                Text(
                  'AO VIVO',
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                    color: const Color(0xFF93000A),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            'A transmissão já começou',
            style: GoogleFonts.montserrat(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              height: 28 / 20,
              color: _ProgramacaoDetalhesScreenState._title,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            'Acompanhe o culto ao vivo pelos canais oficiais da Comunidade '
            'Nova Aliança.',
            style: GoogleFonts.inter(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w400,
              height: 24 / 16,
              color: _ProgramacaoDetalhesScreenState._muted,
            ),
          ),
          SizedBox(height: 16 * scale),
          SizedBox(
            width: double.infinity,
            height: 48 * scale,
            child: FilledButton.icon(
              onPressed: onWatch,
              icon: AuthAssetImage(
                ProgramacaoAssets.detailsCast,
                width: 20 * scale,
                height: 16 * scale,
              ),
              label: const Text('Assistir ao vivo'),
              style: FilledButton.styleFrom(
                backgroundColor: _ProgramacaoDetalhesScreenState._primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventHeading extends StatelessWidget {
  const _EventHeading({required this.details, required this.scale});

  final ProgramacaoDetalhesData details;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          details.title,
          style: GoogleFonts.montserrat(
            fontSize: 36 * scale,
            fontWeight: FontWeight.w500,
            height: 44 / 36,
            letterSpacing: -0.72 * scale,
            color: _ProgramacaoDetalhesScreenState._darkPrimary,
          ),
        ),
        SizedBox(height: 8 * scale),
        _SummaryRow(
          scale: scale,
          asset: ProgramacaoAssets.detailsSummaryCalendar,
          width: 13.5,
          height: 15,
          text: details.dayTimeSummary,
        ),
        SizedBox(height: 8 * scale),
        _SummaryRow(
          scale: scale,
          asset: ProgramacaoAssets.detailsSummaryLocation,
          width: 12,
          height: 15,
          text: details.locationSummary,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.scale,
    required this.asset,
    required this.width,
    required this.height,
    required this.text,
  });

  final double scale;
  final String asset;
  final double width;
  final double height;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AuthAssetImage(asset, width: width * scale, height: height * scale),
        SizedBox(width: 8 * scale),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w400,
            height: 20 / 14,
            color: _ProgramacaoDetalhesScreenState._body,
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.description, required this.scale});

  final String description;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sobre',
          style: GoogleFonts.montserrat(
            fontSize: 20 * scale,
            fontWeight: FontWeight.w600,
            height: 28 / 20,
            color: _ProgramacaoDetalhesScreenState._title,
          ),
        ),
        SizedBox(height: 8 * scale),
        Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w400,
            height: 24 / 16,
            color: _ProgramacaoDetalhesScreenState._body,
          ),
        ),
      ],
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.details, required this.scale});

  final ProgramacaoDetalhesData details;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        25 * scale,
        33 * scale,
        25 * scale,
        25 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _ProgramacaoDetalhesScreenState._line),
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: Offset(0, 1 * scale),
            blurRadius: 1 * scale,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMAÇÕES DA PROGRAMAÇÃO',
            style: GoogleFonts.montserrat(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w700,
              height: 16 / 12,
              letterSpacing: 2.16 * scale,
              color: _ProgramacaoDetalhesScreenState._muted,
            ),
          ),
          SizedBox(height: 16 * scale),
          _InformationRow(
            scale: scale,
            asset: ProgramacaoAssets.detailsInfoCalendar,
            iconWidth: 18,
            iconHeight: 20,
            label: 'Data',
            value: details.date,
          ),
          SizedBox(height: 16 * scale),
          _InformationRow(
            scale: scale,
            asset: ProgramacaoAssets.detailsInfoClock,
            iconWidth: 20,
            iconHeight: 20,
            label: 'Horário',
            value: details.time,
          ),
          SizedBox(height: 16 * scale),
          _InformationRow(
            scale: scale,
            asset: ProgramacaoAssets.detailsInfoPeople,
            iconWidth: 22,
            iconHeight: 16,
            label: 'Público',
            value: details.audience,
          ),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.scale,
    required this.asset,
    required this.iconWidth,
    required this.iconHeight,
    required this.label,
    required this.value,
  });

  final double scale;
  final String asset;
  final double iconWidth;
  final double iconHeight;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40 * scale,
          height: 40 * scale,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _ProgramacaoDetalhesScreenState._soft,
            shape: BoxShape.circle,
          ),
          child: AuthAssetImage(
            asset,
            width: iconWidth * scale,
            height: iconHeight * scale,
          ),
        ),
        SizedBox(width: 16 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w400,
                  height: 16 / 12,
                  color: _ProgramacaoDetalhesScreenState._muted,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w400,
                  height: 24 / 16,
                  color: _ProgramacaoDetalhesScreenState._title,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.details,
    required this.scale,
    required this.onMap,
  });

  final ProgramacaoDetalhesData details;
  final double scale;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        23 * scale,
        17 * scale,
        17 * scale,
        17 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _ProgramacaoDetalhesScreenState._line),
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: Offset(0, 1 * scale),
            blurRadius: 1.5 * scale,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40 * scale,
            height: 40 * scale,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _ProgramacaoDetalhesScreenState._soft,
              shape: BoxShape.circle,
            ),
            child: AuthAssetImage(
              ProgramacaoAssets.detailsLocation,
              width: 16 * scale,
              height: 24 * scale,
            ),
          ),
          SizedBox(width: 16 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.locationName.trim().isNotEmpty
                      ? details.locationName
                      : 'Local a confirmar',
                  style: GoogleFonts.inter(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w400,
                    height: 20 / 16,
                    color: _ProgramacaoDetalhesScreenState._title,
                  ),
                ),
                if (details.address.trim().isNotEmpty) ...[
                  SizedBox(height: 4 * scale),
                  Text(
                    details.address,
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w400,
                      height: 20 / 12,
                      color: _ProgramacaoDetalhesScreenState._title,
                    ),
                  ),
                ],
                SizedBox(height: 4 * scale),
                InkWell(
                  onTap: onMap,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4 * scale),
                    child: Text(
                      'Ver no mapa',
                      style: GoogleFonts.inter(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w500,
                        height: 20 / 14,
                        color: _ProgramacaoDetalhesScreenState._darkPrimary,
                      ),
                    ),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.scale,
    required this.label,
    required this.iconAsset,
    required this.filled,
    required this.onTap,
  });

  final double scale;
  final String label;
  final String iconAsset;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = filled
        ? Colors.white
        : _ProgramacaoDetalhesScreenState._body;

    return SizedBox(
      width: double.infinity,
      height: 48 * scale,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: ColorFiltered(
          colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
          child: AuthAssetImage(
            iconAsset,
            width: filled ? 16 * scale : 18 * scale,
            height: 20 * scale,
          ),
        ),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: filled
              ? _ProgramacaoDetalhesScreenState._primary
              : Colors.white,
          foregroundColor: foreground,
          side: BorderSide(
            color: filled
                ? _ProgramacaoDetalhesScreenState._primary
                : _ProgramacaoDetalhesScreenState._line,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10 * scale),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w500,
            height: 20 / 14,
          ),
        ),
      ),
    );
  }
}
