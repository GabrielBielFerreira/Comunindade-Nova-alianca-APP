import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock/contribuicao_mock_data.dart';
import '../mock_data.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/leader_bottom_navigation.dart';
import '../escala_tela.dart';

abstract class PagamentoExternoKind {
  const PagamentoExternoKind._();

  static const cartao = 'cartao';
  static const boleto = 'boleto';
}

class PagamentoExternoScreen extends StatelessWidget {
  const PagamentoExternoScreen({
    super.key,
    required this.isLeader,
    required this.kind,
    this.contributionType = 'D\u00EDzimo',
    this.valueLabel = 'R\$ 250,00',
    this.campaign,
  });

  static const _designWidth = 390.0;
  static const _background = Color(0xFFFAFAFA);
  static const _primary = Color(0xFF7A0022);
  static const _primaryDark = Color(0xFF510014);
  static const _title = Color(0xFF1C1B1B);
  static const _body = Color(0xFF6B7280);
  static const _mutedBrown = Color(0xFF584142);
  static const _line = Color(0xFFE5E7EB);
  static const _lineWarm = Color(0xFFEAE7E7);
  static const _infoBackground = Color(0xFFF6F3F2);
  static const _soft = Color(0xFFF5E6EC);
  static const _cardIconBlue = Color(0xFF0EA5E9);

  final bool isLeader;
  final String kind;
  final String contributionType;
  final String valueLabel;
  final ContribuicaoCampaignData? campaign;

  bool get _isCard => kind == PagamentoExternoKind.cartao;
  String get _titleText =>
      _isCard ? 'Pagamento por Cart\u00E3o' : 'Pagamento por Boleto';
  String get _methodName => _isCard ? 'Cart\u00E3o' : 'Boleto';
  IconData get _methodIcon =>
      _isCard ? Icons.credit_card_rounded : Icons.receipt_long_rounded;
  Color get _methodIconColor => _isCard ? _cardIconBlue : _primaryDark;

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
              final navHeight = 72 * scale + bottomPadding;

              return Stack(
                children: [
                  Column(
                    children: [
                      _ExternalPaymentHeader(
                        scale: scale,
                        topPadding: topPadding,
                        title: _titleText,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            24 * scale,
                            16 * scale,
                            navHeight + 32 * scale,
                          ),
                          child: Column(
                            children: [
                              _ExternalSummaryCard(
                                scale: scale,
                                type: campaign == null
                                    ? contributionType
                                    : 'Campanha',
                                valueLabel: valueLabel,
                              ),
                              SizedBox(height: 24 * scale),
                              _ExternalRedirectCard(
                                scale: scale,
                                icon: _methodIcon,
                                iconColor: _methodIconColor,
                              ),
                              SizedBox(height: 56 * scale),
                              SizedBox(
                                width: double.infinity,
                                height: 52 * scale,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _showFuturePaymentMessage(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        8 * scale,
                                      ),
                                    ),
                                    textStyle: GoogleFonts.inter(
                                      fontSize: 16 * scale,
                                      fontWeight: FontWeight.w400,
                                      height: 24 / 16,
                                    ),
                                  ),
                                  child: const Text('Continuar para pagamento'),
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
                    child: isLeader
                        ? LeaderBottomNavigation(
                            activeItem: LeaderNavItem.contribute,
                            scale: scale,
                            bottomPadding: bottomPadding,
                          )
                        : _ExternalPaymentBottomNavigation(
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

  void _showFuturePaymentMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Pagamento por ${_methodName.toLowerCase()} ser\u00E1 conectado futuramente',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _ExternalPaymentHeader extends StatelessWidget {
  const _ExternalPaymentHeader({
    required this.scale,
    required this.topPadding,
    required this.title,
  });

  final double scale;
  final double topPadding;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * scale + topPadding,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: PagamentoExternoScreen._line)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        child: Row(
          children: [
            SizedBox(
              width: 40 * scale,
              height: 40 * scale,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 26 * scale,
                  color: PagamentoExternoScreen._primaryDark,
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w600,
                  height: 32 / 22,
                  color: PagamentoExternoScreen._primaryDark,
                ),
              ),
            ),
            SizedBox(width: 40 * scale),
          ],
        ),
      ),
    );
  }
}

class _ExternalSummaryCard extends StatelessWidget {
  const _ExternalSummaryCard({
    required this.scale,
    required this.type,
    required this.valueLabel,
  });

  final double scale;
  final String type;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        25 * scale,
        25 * scale,
        25 * scale,
        28 * scale,
      ),
      decoration: _externalCardDecoration(scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo da Contribui\u00E7\u00E3o',
            style: GoogleFonts.montserrat(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              height: 28 / 20,
              color: PagamentoExternoScreen._title,
            ),
          ),
          SizedBox(height: 24 * scale),
          _ExternalSummaryRow(
            scale: scale,
            label: 'Tipo',
            value: type,
            showDivider: true,
          ),
          SizedBox(height: 18 * scale),
          _ExternalSummaryRow(
            scale: scale,
            label: 'Valor',
            value: valueLabel,
            valueColor: PagamentoExternoScreen._primaryDark,
          ),
        ],
      ),
    );
  }
}

class _ExternalSummaryRow extends StatelessWidget {
  const _ExternalSummaryRow({
    required this.scale,
    required this.label,
    required this.value,
    this.valueColor,
    this.showDivider = false,
  });

  final double scale;
  final String label;
  final String value;
  final Color? valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: showDivider ? 18 * scale : 0),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: PagamentoExternoScreen._lineWarm),
              ),
            )
          : null,
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w400,
              height: 24 / 16,
              color: PagamentoExternoScreen._mutedBrown,
            ),
          ),
          const Spacer(),
          Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w500,
              height: 24 / 16,
              color: valueColor ?? PagamentoExternoScreen._title,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExternalRedirectCard extends StatelessWidget {
  const _ExternalRedirectCard({
    required this.scale,
    required this.icon,
    required this.iconColor,
  });

  final double scale;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 178 * scale),
      padding: EdgeInsets.fromLTRB(
        25 * scale,
        28 * scale,
        25 * scale,
        28 * scale,
      ),
      decoration: BoxDecoration(
        color: PagamentoExternoScreen._infoBackground,
        border: Border.all(color: PagamentoExternoScreen._line),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(
        children: [
          Container(
            width: 64 * scale,
            height: 64 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: Offset(0, 1 * scale),
                  blurRadius: 1.5 * scale,
                ),
              ],
            ),
            child: Icon(icon, size: 26 * scale, color: iconColor),
          ),
          SizedBox(height: 18 * scale),
          Text(
            'Voc\u00EA ser\u00E1 direcionado para o ambiente\nseguro de Pagamento',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w400,
              height: 1.35,
              color: PagamentoExternoScreen._title,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _externalCardDecoration(double scale) {
  return BoxDecoration(
    color: Colors.white,
    border: Border.all(color: PagamentoExternoScreen._line),
    borderRadius: BorderRadius.circular(12 * scale),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        offset: Offset(0, 1 * scale),
        blurRadius: 1.5 * scale,
      ),
    ],
  );
}

class _ExternalPaymentBottomNavigation extends StatelessWidget {
  const _ExternalPaymentBottomNavigation({
    required this.scale,
    required this.bottomPadding,
  });

  final double scale;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72 * scale + bottomPadding,
      padding: EdgeInsets.fromLTRB(4 * scale, 0, 4 * scale, bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: PagamentoExternoScreen._line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, -1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final item in HomeMockData.bottomNavigation)
            SizedBox(
              width: item.width * scale,
              height: 56 * scale,
              child: _ExternalPaymentNavigationItem(
                item: item,
                scale: scale,
                selected: item.asset == HomeAssets.contribute,
              ),
            ),
        ],
      ),
    );
  }
}

class _ExternalPaymentNavigationItem extends StatelessWidget {
  const _ExternalPaymentNavigationItem({
    required this.item,
    required this.scale,
    required this.selected,
  });

  final HomeBottomNavigationData item;
  final double scale;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? PagamentoExternoScreen._primary
        : PagamentoExternoScreen._body;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          child: AuthAssetImage(
            item.asset,
            width: item.iconWidth * scale,
            height: item.iconHeight * scale,
          ),
        ),
        SizedBox(height: 2 * scale),
        Text(
          item.label,
          maxLines: 1,
          style: GoogleFonts.inter(
            fontSize: item.fontSize * scale,
            fontWeight: FontWeight.w500,
            height: item.fontSize == 11 ? 13 / 11 : 16.8 / 12,
            color: color,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (selected) return;

        if (item.label == 'In\u00EDcio') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            VisualRoutes.entraconta,
            (route) => false,
          );
          return;
        }
        if (item.label == 'Avisos') {
          Navigator.pushNamed(context, VisualRoutes.avisos);
          return;
        }
        if (item.label == 'Programa\u00E7\u00E3o') {
          Navigator.pushNamed(context, VisualRoutes.programacao);
          return;
        }
        if (item.label == 'Ora\u00E7\u00E3o') {
          Navigator.pushNamed(context, VisualRoutes.oracao);
          return;
        }
        if (item.asset == HomeAssets.profile) {
          Navigator.pushNamed(context, VisualRoutes.perfil);
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Tela visual ser\u00E1 conectada futuramente'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: Center(
        child: selected
            ? Container(
                width: 61 * scale,
                height: 41 * scale,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PagamentoExternoScreen._soft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: content,
              )
            : SizedBox(
                height: 44.8 * scale,
                child: Center(child: content),
              ),
      ),
    );
  }
}
