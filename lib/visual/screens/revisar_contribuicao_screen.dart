import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock/contribuicao_mock_data.dart';
import '../mock_data.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/leader_bottom_navigation.dart';
import 'pagamento_boleto_screen.dart';
import 'pagamento_cartao_screen.dart';
import 'pagamento_pix_screen.dart';
import '../escala_tela.dart';

class RevisarContribuicaoScreen extends StatelessWidget {
  const RevisarContribuicaoScreen({
    super.key,
    required this.isLeader,
    this.contributionType = 'Dízimo',
    this.valueLabel = 'R\$ 250,00',
    this.paymentMethod = 'Pix',
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
  static const _soft = Color(0xFFF5E6EC);
  static const _green = Color(0xFF16A34A);

  final bool isLeader;
  final String contributionType;
  final String valueLabel;
  final String paymentMethod;
  final ContribuicaoCampaignData? campaign;

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
              final actionHeight = 139 * scale;

              return Stack(
                children: [
                  Column(
                    children: [
                      _ReviewHeader(scale: scale, topPadding: topPadding),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            24 * scale,
                            16 * scale,
                            navHeight + actionHeight + 24 * scale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ContributionSummaryCard(
                                scale: scale,
                                type: campaign == null
                                    ? contributionType
                                    : 'Campanha',
                                valueLabel: valueLabel,
                                destination:
                                    campaign?.title ??
                                    HomeMockData.communityName,
                                method: paymentMethod,
                              ),
                              SizedBox(height: 24 * scale),
                              _SecurityCard(scale: scale),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ReviewActionArea(
                          scale: scale,
                          method: paymentMethod,
                          onContinue: () => _continuePayment(context),
                          onEdit: () => _editContribution(context),
                        ),
                        isLeader
                            ? LeaderBottomNavigation(
                                activeItem: LeaderNavItem.contribute,
                                scale: scale,
                                bottomPadding: bottomPadding,
                              )
                            : _ReviewBottomNavigation(
                                scale: scale,
                                bottomPadding: bottomPadding,
                              ),
                      ],
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

  void _continuePayment(BuildContext context) {
    final label = _methodLabel(paymentMethod);
    final Widget screen = switch (label) {
      'Pix' => PagamentoPixScreen(
        isLeader: isLeader,
        contributionType: contributionType,
        valueLabel: valueLabel,
        campaign: campaign,
      ),
      'Cartão' => PagamentoCartaoScreen(
        isLeader: isLeader,
        contributionType: contributionType,
        valueLabel: valueLabel,
        campaign: campaign,
      ),
      'Boleto' => PagamentoBoletoScreen(
        isLeader: isLeader,
        contributionType: contributionType,
        valueLabel: valueLabel,
        campaign: campaign,
      ),
      _ => PagamentoPixScreen(
        isLeader: isLeader,
        contributionType: contributionType,
        valueLabel: valueLabel,
        campaign: campaign,
      ),
    };

    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _editContribution(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  static String _methodLabel(String method) {
    final normalized = method.toLowerCase();
    if (normalized.contains('cart')) {
      return 'Cartão';
    }
    if (normalized.contains('boleto')) {
      return 'Boleto';
    }
    return 'Pix';
  }

  static IconData _methodIcon(String method) {
    final label = _methodLabel(method);
    if (label == 'Cartão') {
      return Icons.credit_card_rounded;
    }
    if (label == 'Boleto') {
      return Icons.receipt_long_rounded;
    }
    return Icons.qr_code_2_rounded;
  }

  static Color _methodColor(String method) {
    return _methodLabel(method) == 'Pix' ? _green : _primaryDark;
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.scale, required this.topPadding});

  final double scale;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * scale + topPadding,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(color: Colors.white),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16 * scale, 0, 56 * scale, 0),
        child: Row(
          children: [
            SizedBox(
              width: 32 * scale,
              height: 40 * scale,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 24 * scale,
                  color: RevisarContribuicaoScreen._primaryDark,
                ),
              ),
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              child: Text(
                'Revisar contribuição',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w700,
                  height: 32 / 24,
                  color: RevisarContribuicaoScreen._primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributionSummaryCard extends StatelessWidget {
  const _ContributionSummaryCard({
    required this.scale,
    required this.type,
    required this.valueLabel,
    required this.destination,
    required this.method,
  });

  final double scale;
  final String type;
  final String valueLabel;
  final String destination;
  final String method;

  @override
  Widget build(BuildContext context) {
    final methodLabel = RevisarContribuicaoScreen._methodLabel(method);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: RevisarContribuicaoScreen._line),
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: Offset(0, 1 * scale),
            blurRadius: 1.5 * scale,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 17 * scale),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: RevisarContribuicaoScreen._lineWarm),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'VALOR DA CONTRIBUIÇÃO',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                    letterSpacing: 0.7 * scale,
                    color: RevisarContribuicaoScreen._mutedBrown,
                  ),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  valueLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 36 * scale,
                    fontWeight: FontWeight.w600,
                    height: 44 / 36,
                    letterSpacing: -0.72 * scale,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24 * scale),
          _SummaryLine(scale: scale, label: 'Tipo', value: type),
          SizedBox(height: 16 * scale),
          _SummaryLine(scale: scale, label: 'Destino', value: destination),
          SizedBox(height: 16 * scale),
          Text(
            'Método de Pagamento',
            style: GoogleFonts.inter(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w400,
              height: 16 / 12,
              color: RevisarContribuicaoScreen._mutedBrown,
            ),
          ),
          SizedBox(height: 14 * scale),
          Row(
            children: [
              Icon(
                RevisarContribuicaoScreen._methodIcon(method),
                size: 20 * scale,
                color: RevisarContribuicaoScreen._methodColor(method),
              ),
              SizedBox(width: 8 * scale),
              Text(
                methodLabel,
                style: GoogleFonts.inter(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w500,
                  height: 24 / 16,
                  color: RevisarContribuicaoScreen._title,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.scale,
    required this.label,
    required this.value,
  });

  final double scale;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12 * scale,
            fontWeight: FontWeight.w400,
            height: 16 / 12,
            color: RevisarContribuicaoScreen._mutedBrown,
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w500,
            height: 24 / 16,
            color: RevisarContribuicaoScreen._title,
          ),
        ),
      ],
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17 * scale),
      decoration: BoxDecoration(
        color: RevisarContribuicaoScreen._soft,
        border: Border.all(color: const Color(0x4DEACDD6)),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36 * scale,
            height: 36 * scale,
            margin: EdgeInsets.only(top: 4 * scale),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: Offset(0, 1 * scale),
                  blurRadius: 1 * scale,
                ),
              ],
            ),
            child: Icon(
              Icons.shield_rounded,
              size: 22 * scale,
              color: RevisarContribuicaoScreen._primary,
            ),
          ),
          SizedBox(width: 16 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pagamento seguro',
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                    color: RevisarContribuicaoScreen._primary,
                  ),
                ),
                SizedBox(height: 3 * scale),
                Text(
                  'Confirme os dados da sua contribuição abaixo para avançar ou edite as informações se necessário.',
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w400,
                    height: 22.75 / 14,
                    color: RevisarContribuicaoScreen._mutedBrown,
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

class _ReviewActionArea extends StatelessWidget {
  const _ReviewActionArea({
    required this.scale,
    required this.method,
    required this.onContinue,
    required this.onEdit,
  });

  final double scale;
  final String method;
  final VoidCallback onContinue;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        17 * scale,
        16 * scale,
        16 * scale,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: RevisarContribuicaoScreen._lineWarm),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 49 * scale,
            child: ElevatedButton.icon(
              onPressed: onContinue,
              label: Text(
                RevisarContribuicaoScreen._methodLabel(method) == 'Pix'
                    ? 'Continuar para PIX'
                    : 'Continuar pagamento',
              ),
              icon: Icon(Icons.open_in_new_rounded, size: 16 * scale),
              iconAlignment: IconAlignment.end,
              style: ElevatedButton.styleFrom(
                backgroundColor: RevisarContribuicaoScreen._primary,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
          SizedBox(height: 8 * scale),
          SizedBox(
            width: double.infinity,
            height: 50 * scale,
            child: OutlinedButton(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                foregroundColor: RevisarContribuicaoScreen._primary,
                side: const BorderSide(
                  color: RevisarContribuicaoScreen._primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                ),
              ),
              child: const Text('Editar contribuição'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewBottomNavigation extends StatelessWidget {
  const _ReviewBottomNavigation({
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
        border: Border(top: BorderSide(color: RevisarContribuicaoScreen._line)),
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
              child: _ReviewNavigationItem(
                item: item,
                scale: scale,
                selected: item.label == 'Contribuir',
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewNavigationItem extends StatelessWidget {
  const _ReviewNavigationItem({
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
        ? RevisarContribuicaoScreen._primary
        : RevisarContribuicaoScreen._body;
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
        if (selected) {
          return;
        }

        if (item.label == 'Início') {
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

        if (item.label == 'Programação') {
          Navigator.pushNamed(context, VisualRoutes.programacao);
          return;
        }

        if (item.label == 'Oração') {
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
              content: Text('Tela visual será conectada futuramente'),
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
                  color: RevisarContribuicaoScreen._soft,
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
