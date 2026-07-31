import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock/contribuicao_mock_data.dart';
import '../mock_data.dart';
import '../models/contribuicao_visual_model.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/leader_bottom_navigation.dart';
import 'historico_contribuicoes_screen.dart';

class StatusContribuicaoScreen extends StatelessWidget {
  const StatusContribuicaoScreen({
    super.key,
    required this.isLeader,
    this.contributionType = 'Dízimo',
    this.valueLabel = 'R\$ 0,00',
    this.paymentMethod = 'PIX',
    this.identifier = 'CNA-2026-0001',
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
  static const _soft = Color(0xFFF5E6EC);
  static const _success = Color(0xFF004419);
  static const _successIcon = Color(0xFF002B0E);
  static const _successSoft = Color(0xFFDCFCE7);

  final bool isLeader;
  final String contributionType;
  final String valueLabel;
  final String paymentMethod;
  final String identifier;
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
                  .clamp(0.86, 1.0)
                  .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;
              final navHeight = 72 * scale + bottomPadding;
              final contribution = ContribuicaoVisualModel(
                id: identifier,
                type: campaign == null ? contributionType : 'Campanha',
                campaignName: campaign?.title,
                valueLabel: valueLabel,
                method: paymentMethod,
                status: ContribuicaoVisualStatus.aprovado,
                dateLabel: 'Agora',
                church: HomeMockData.communityName,
              );

              return Stack(
                children: [
                  Column(
                    children: [
                      _StatusHeader(
                        scale: scale,
                        topPadding: topPadding,
                        isLeader: isLeader,
                        contribution: contribution,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            32 * scale,
                            16 * scale,
                            navHeight + 28 * scale,
                          ),
                          child: Column(
                            children: [
                              _SuccessBlock(scale: scale),
                              SizedBox(height: 32 * scale),
                              _StatusSummaryCard(
                                scale: scale,
                                type: campaign == null
                                    ? contributionType
                                    : 'Campanha',
                                valueLabel: valueLabel,
                                paymentMethod: paymentMethod,
                                identifier: identifier,
                                campaign: campaign,
                              ),
                              SizedBox(height: 32 * scale),
                              _StatusActions(
                                scale: scale,
                                isLeader: isLeader,
                                contribution: contribution,
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
                        : _StatusBottomNavigation(
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

  static void openHistory(
    BuildContext context, {
    required bool isLeader,
    required ContribuicaoVisualModel contribution,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoricoContribuicoesScreen(
          isLeader: isLeader,
          highlightedContribution: contribution,
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.scale,
    required this.topPadding,
    required this.isLeader,
    required this.contribution,
  });

  final double scale;
  final double topPadding;
  final bool isLeader;
  final ContribuicaoVisualModel contribution;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * scale + topPadding,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(color: Colors.white),
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
                  size: 28 * scale,
                  color: StatusContribuicaoScreen._primaryDark,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Contribuição',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w700,
                  height: 32 / 24,
                  color: StatusContribuicaoScreen._primaryDark,
                ),
              ),
            ),
            SizedBox(
              width: 40 * scale,
              height: 40 * scale,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => StatusContribuicaoScreen.openHistory(
                  context,
                  isLeader: isLeader,
                  contribution: contribution,
                ),
                icon: Icon(
                  Icons.history_rounded,
                  size: 27 * scale,
                  color: StatusContribuicaoScreen._primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBlock extends StatelessWidget {
  const _SuccessBlock({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96 * scale,
          height: 96 * scale,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: StatusContribuicaoScreen._successSoft,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: Offset(0, 1 * scale),
                blurRadius: 1.5 * scale,
              ),
            ],
          ),
          child: Icon(
            Icons.check_rounded,
            size: 58 * scale,
            color: StatusContribuicaoScreen._successIcon,
          ),
        ),
        SizedBox(height: 24 * scale),
        Text(
          'Contribuição registrada',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 24 * scale,
            fontWeight: FontWeight.w700,
            height: 32 / 24,
            color: StatusContribuicaoScreen._success,
          ),
        ),
        SizedBox(height: 8 * scale),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 384 * scale),
          child: Text(
            'Obrigado pela sua generosidade. A\nconfirmação da sua contribuição já está\ndisponível no histórico.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w400,
              height: 24 / 16,
              color: StatusContribuicaoScreen._body,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  const _StatusSummaryCard({
    required this.scale,
    required this.type,
    required this.valueLabel,
    required this.paymentMethod,
    required this.identifier,
    required this.campaign,
  });

  final double scale;
  final String type;
  final String valueLabel;
  final String paymentMethod;
  final String identifier;
  final ContribuicaoCampaignData? campaign;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: StatusContribuicaoScreen._line),
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
            padding: EdgeInsets.only(bottom: 13 * scale),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: StatusContribuicaoScreen._line),
              ),
            ),
            child: Text(
              'Resumo da Contribuição',
              style: GoogleFonts.montserrat(
                fontSize: 20 * scale,
                fontWeight: FontWeight.w600,
                height: 28 / 20,
                color: StatusContribuicaoScreen._title,
              ),
            ),
          ),
          SizedBox(height: 16 * scale),
          _StatusSummaryRow(scale: scale, label: 'Tipo', value: type),
          SizedBox(height: 16 * scale),
          _StatusSummaryRow(
            scale: scale,
            label: 'Valor',
            value: valueLabel,
            valueColor: StatusContribuicaoScreen._primaryDark,
            valueFontSize: 20,
            valueFontFamily: _StatusValueFont.montserrat,
          ),
          SizedBox(height: 16 * scale),
          _StatusSummaryRow(
            scale: scale,
            label: 'Método',
            value: paymentMethod,
          ),
          if (campaign != null) ...[
            SizedBox(height: 16 * scale),
            _StatusSummaryRow(
              scale: scale,
              label: 'Campanha',
              value: campaign!.title,
            ),
          ],
          SizedBox(height: 16 * scale),
          _StatusSummaryRow(
            scale: scale,
            label: 'Identificador',
            value: identifier,
            valueColor: StatusContribuicaoScreen._mutedBrown,
            valueFontSize: 12,
            valueFontFamily: _StatusValueFont.mono,
          ),
        ],
      ),
    );
  }
}

enum _StatusValueFont { inter, montserrat, mono }

class _StatusSummaryRow extends StatelessWidget {
  const _StatusSummaryRow({
    required this.scale,
    required this.label,
    required this.value,
    this.valueColor = StatusContribuicaoScreen._title,
    this.valueFontSize = 14,
    this.valueFontFamily = _StatusValueFont.inter,
  });

  final double scale;
  final String label;
  final String value;
  final Color valueColor;
  final double valueFontSize;
  final _StatusValueFont valueFontFamily;

  @override
  Widget build(BuildContext context) {
    final valueStyle = switch (valueFontFamily) {
      _StatusValueFont.montserrat => GoogleFonts.montserrat(
        fontSize: valueFontSize * scale,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: valueColor,
      ),
      _StatusValueFont.mono => TextStyle(
        fontFamily: 'monospace',
        fontSize: valueFontSize * scale,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        color: valueColor,
      ),
      _ => GoogleFonts.inter(
        fontSize: valueFontSize * scale,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
        color: valueColor,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w400,
            height: 20 / 14,
            color: StatusContribuicaoScreen._body,
          ),
        ),
        SizedBox(width: 16 * scale),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}

class _StatusActions extends StatelessWidget {
  const _StatusActions({
    required this.scale,
    required this.isLeader,
    required this.contribution,
  });

  final double scale;
  final bool isLeader;
  final ContribuicaoVisualModel contribution;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48 * scale,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                isLeader
                    ? VisualRoutes.contribuirLeader
                    : VisualRoutes.contribuir,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: StatusContribuicaoScreen._primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10 * scale),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
              ),
            ),
            child: const Text('Voltar para Contribuir'),
          ),
        ),
        SizedBox(height: 16 * scale),
        SizedBox(
          width: double.infinity,
          height: 52 * scale,
          child: OutlinedButton(
            onPressed: () => StatusContribuicaoScreen.openHistory(
              context,
              isLeader: isLeader,
              contribution: contribution,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: StatusContribuicaoScreen._primary,
              side: const BorderSide(
                width: 2,
                color: StatusContribuicaoScreen._primary,
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
            child: const Text('Ver histórico'),
          ),
        ),
      ],
    );
  }
}

class _StatusBottomNavigation extends StatelessWidget {
  const _StatusBottomNavigation({
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
        border: Border(top: BorderSide(color: StatusContribuicaoScreen._line)),
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
              child: _StatusNavigationItem(
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

class _StatusNavigationItem extends StatelessWidget {
  const _StatusNavigationItem({
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
        ? StatusContribuicaoScreen._primary
        : StatusContribuicaoScreen._body;
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
            VisualRoutes.homeMember,
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
                  color: StatusContribuicaoScreen._soft,
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
