import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock_data.dart';
import '../models/contribuicao_visual_model.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/leader_bottom_navigation.dart';

enum _ContributionFilter { todos, aprovadas, pendentes, recusadas, canceladas }

class HistoricoContribuicoesScreen extends StatefulWidget {
  const HistoricoContribuicoesScreen({
    super.key,
    required this.isLeader,
    this.highlightedContribution,
  });

  static const _designWidth = 390.0;
  static const _background = Color(0xFFFAFAFA);
  static const _primary = Color(0xFF7A0022);
  static const _primaryDark = Color(0xFF510014);
  static const _figmaPrimaryDark = Color(0xFF510014);
  static const _title = Color(0xFF1C1B1B);
  static const _body = Color(0xFF6B7280);
  static const _mutedBrown = Color(0xFF584142);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);
  static const _approvedText = Color(0xFF16A34A);
  static const _approvedBg = Color(0xFFDCFCE7);
  static const _pendingText = Color(0xFFD97706);
  static const _pendingBg = Color(0xFFFEF08A);
  static const _refusedText = Color(0xFFC0392B);
  static const _refusedBg = Color(0xFFFEE2E2);
  static const _cancelledText = Color(0xFF6B7280);
  static const _cancelledBg = Color(0xFFF3F4F6);

  // Sem dados fabricados: o histórico mostra apenas contribuições reais. Como
  // a confirmação do PIX manual é feita pela tesouraria (fora do app) e o
  // backend de pagamentos online ainda não está publicado, a lista começa
  // vazia e exibe o estado vazio honesto.
  static const _baseContributions = <ContribuicaoVisualModel>[];

  final bool isLeader;
  final ContribuicaoVisualModel? highlightedContribution;

  @override
  State<HistoricoContribuicoesScreen> createState() =>
      _HistoricoContribuicoesScreenState();
}

class _HistoricoContribuicoesScreenState
    extends State<HistoricoContribuicoesScreen> {
  _ContributionFilter _selectedFilter = _ContributionFilter.todos;
  late final List<ContribuicaoVisualModel> _contributions;

  @override
  void initState() {
    super.initState();
    final current = widget.highlightedContribution;
    _contributions = [
      ?current,
      ...HistoricoContribuicoesScreen._baseContributions.where(
        (item) => item.id != current?.id,
      ),
    ];
  }

  List<ContribuicaoVisualModel> get _filteredContributions {
    return switch (_selectedFilter) {
      _ContributionFilter.todos => _contributions,
      _ContributionFilter.aprovadas =>
        _contributions
            .where((item) => item.status == ContribuicaoVisualStatus.aprovado)
            .toList(),
      _ContributionFilter.pendentes =>
        _contributions
            .where((item) => item.status == ContribuicaoVisualStatus.pendente)
            .toList(),
      _ContributionFilter.recusadas =>
        _contributions
            .where((item) => item.status == ContribuicaoVisualStatus.recusado)
            .toList(),
      _ContributionFilter.canceladas =>
        _contributions
            .where((item) => item.status == ContribuicaoVisualStatus.cancelado)
            .toList(),
    };
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
        backgroundColor: HistoricoContribuicoesScreen._background,
        body: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale =
                  (constraints.maxWidth /
                          HistoricoContribuicoesScreen._designWidth)
                      .clamp(0.86, 1.0)
                      .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;
              final navHeight = 72 * scale + bottomPadding;
              final visibleContributions = _filteredContributions;

              return Stack(
                children: [
                  Column(
                    children: [
                      _HistoryHeader(scale: scale, topPadding: topPadding),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            24 * scale,
                            16 * scale,
                            navHeight + 24 * scale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HistoryIntro(scale: scale),
                              SizedBox(height: 24 * scale),
                              _FilterChips(
                                scale: scale,
                                selectedFilter: _selectedFilter,
                                onSelected: (filter) =>
                                    setState(() => _selectedFilter = filter),
                              ),
                              SizedBox(height: 24 * scale),
                              if (visibleContributions.isEmpty)
                                _EmptyState(
                                  scale: scale,
                                  isLeader: widget.isLeader,
                                )
                              else
                                Column(
                                  children: [
                                    for (final contribution
                                        in visibleContributions) ...[
                                      _ContributionCard(
                                        scale: scale,
                                        contribution: contribution,
                                        onTap: () => _showContributionDetails(
                                          contribution,
                                          scale,
                                        ),
                                      ),
                                      SizedBox(height: 16 * scale),
                                    ],
                                  ],
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
                            activeItem: LeaderNavItem.contribute,
                            scale: scale,
                            bottomPadding: bottomPadding,
                          )
                        : _HistoryBottomNavigation(
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

  void _showContributionDetails(
    ContribuicaoVisualModel contribution,
    double scale,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ContributionDetailsSheet(
          scale: scale,
          contribution: contribution,
          isLeader: widget.isLeader,
          parentContext: context,
        );
      },
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.scale, required this.topPadding});

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
              width: 40 * scale,
              height: 40 * scale,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 28 * scale,
                  color: HistoricoContribuicoesScreen._primaryDark,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Histórico',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w700,
                  height: 32 / 24,
                  color: HistoricoContribuicoesScreen._title,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryIntro extends StatelessWidget {
  const _HistoryIntro({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minhas contribuições',
          style: GoogleFonts.montserrat(
            fontSize: 24 * scale,
            fontWeight: FontWeight.w700,
            height: 32 / 24,
            color: HistoricoContribuicoesScreen._title,
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          'Acompanhe o status das suas contribuições.',
          style: GoogleFonts.inter(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w400,
            height: 24 / 16,
            color: HistoricoContribuicoesScreen._mutedBrown,
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.scale,
    required this.selectedFilter,
    required this.onSelected,
  });

  final double scale;
  final _ContributionFilter selectedFilter;
  final ValueChanged<_ContributionFilter> onSelected;

  static const _labels = <_ContributionFilter, String>{
    _ContributionFilter.todos: 'Todos',
    _ContributionFilter.aprovadas: 'Aprovadas',
    _ContributionFilter.pendentes: 'Pendentes',
    _ContributionFilter.recusadas: 'Recusadas',
    _ContributionFilter.canceladas: 'Canceladas',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: _labels.length,
        separatorBuilder: (_, _) => SizedBox(width: 8 * scale),
        itemBuilder: (context, index) {
          final filter = _labels.keys.elementAt(index);
          final selected = filter == selectedFilter;
          return GestureDetector(
            onTap: () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 9 * scale,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? HistoricoContribuicoesScreen._figmaPrimaryDark
                    : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: selected
                    ? null
                    : Border.all(color: HistoricoContribuicoesScreen._line),
              ),
              child: Text(
                _labels[filter]!,
                style: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                  color: selected
                      ? Colors.white
                      : HistoricoContribuicoesScreen._mutedBrown,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({
    required this.scale,
    required this.contribution,
    required this.onTap,
  });

  final double scale;
  final ContribuicaoVisualModel contribution;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12 * scale),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(17 * scale),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: HistoricoContribuicoesScreen._line),
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
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ContributionIcon(scale: scale, contribution: contribution),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contribution.type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.w600,
                            height: 28 / 20,
                            color: HistoricoContribuicoesScreen._title,
                          ),
                        ),
                        if (contribution.campaignName != null) ...[
                          SizedBox(height: 1 * scale),
                          Text(
                            contribution.campaignName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w400,
                              height: 16 / 12,
                              color: HistoricoContribuicoesScreen._body,
                            ),
                          ),
                        ],
                        SizedBox(height: 2 * scale),
                        _PaymentMethodLine(
                          scale: scale,
                          method: contribution.method,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  _StatusPill(scale: scale, status: contribution.status),
                ],
              ),
              SizedBox(height: 13 * scale),
              Container(
                padding: EdgeInsets.only(top: 9 * scale),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: HistoricoContribuicoesScreen._line),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      contribution.dateLabel,
                      style: GoogleFonts.inter(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                        color: HistoricoContribuicoesScreen._mutedBrown,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      contribution.valueLabel,
                      style: GoogleFonts.montserrat(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.w600,
                        height: 28 / 20,
                        color: HistoricoContribuicoesScreen._title,
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

class _ContributionIcon extends StatelessWidget {
  const _ContributionIcon({required this.scale, required this.contribution});

  final double scale;
  final ContribuicaoVisualModel contribution;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40 * scale,
      height: 40 * scale,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: HistoricoContribuicoesScreen._soft,
        shape: BoxShape.circle,
      ),
      child: Icon(
        contribution.type == 'Campanha'
            ? Icons.account_balance_rounded
            : Icons.volunteer_activism_rounded,
        size: 23 * scale,
        color: HistoricoContribuicoesScreen._primaryDark,
      ),
    );
  }
}

class _PaymentMethodLine extends StatelessWidget {
  const _PaymentMethodLine({required this.scale, required this.method});

  final double scale;
  final String method;

  @override
  Widget build(BuildContext context) {
    final isPix = method.toLowerCase().contains('pix');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _methodIcon(method),
          size: 13 * scale,
          color: isPix
              ? HistoricoContribuicoesScreen._approvedText
              : HistoricoContribuicoesScreen._body,
        ),
        SizedBox(width: 4 * scale),
        Text(
          method,
          style: GoogleFonts.inter(
            fontSize: 12 * scale,
            fontWeight: FontWeight.w400,
            height: 16 / 12,
            color: HistoricoContribuicoesScreen._body,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.scale, required this.status});

  final double scale;
  final ContribuicaoVisualStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 2 * scale),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: GoogleFonts.montserrat(
          fontSize: 12 * scale,
          fontWeight: FontWeight.w700,
          height: 16 / 12,
          letterSpacing: 2.16 * scale,
          color: _statusColor(status),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scale, required this.isLeader});

  final double scale;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: HistoricoContribuicoesScreen._line),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      child: Column(
        children: [
          Container(
            width: 72 * scale,
            height: 72 * scale,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: HistoricoContribuicoesScreen._soft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 34 * scale,
              color: HistoricoContribuicoesScreen._primaryDark,
            ),
          ),
          SizedBox(height: 18 * scale),
          Text(
            'Nenhuma contribuição encontrada',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w700,
              height: 28 / 20,
              color: HistoricoContribuicoesScreen._title,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            'Quando houver contribuições com este status, elas aparecerão aqui.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
              color: HistoricoContribuicoesScreen._body,
            ),
          ),
          SizedBox(height: 20 * scale),
          SizedBox(
            width: double.infinity,
            height: 48 * scale,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                isLeader
                    ? VisualRoutes.contribuirLeader
                    : VisualRoutes.contribuir,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: HistoricoContribuicoesScreen._primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Fazer contribuição'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionDetailsSheet extends StatelessWidget {
  const _ContributionDetailsSheet({
    required this.scale,
    required this.contribution,
    required this.isLeader,
    required this.parentContext,
  });

  final double scale;
  final ContribuicaoVisualModel contribution;
  final bool isLeader;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.66,
      minChildSize: 0.48,
      maxChildSize: 0.86,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24 * scale),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              24 * scale,
              10 * scale,
              24 * scale,
              28 * scale,
            ),
            children: [
              Center(
                child: Container(
                  width: 44 * scale,
                  height: 4 * scale,
                  decoration: BoxDecoration(
                    color: HistoricoContribuicoesScreen._line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: 12 * scale),
              Row(
                children: [
                  SizedBox(width: 32 * scale),
                  Expanded(
                    child: Text(
                      'Detalhe da contribuição',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.w700,
                        height: 28 / 20,
                        color: HistoricoContribuicoesScreen._title,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 26 * scale,
                      color: HistoricoContribuicoesScreen._body,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12 * scale),
              _DetailLine(
                scale: scale,
                label: 'Status',
                customValue: Align(
                  alignment: Alignment.centerRight,
                  child: _StatusPill(scale: scale, status: contribution.status),
                ),
              ),
              _DetailLine(
                scale: scale,
                label: 'Tipo da contribuição',
                value: contribution.type,
              ),
              if (contribution.campaignName != null)
                _DetailLine(
                  scale: scale,
                  label: 'Campanha',
                  value: contribution.campaignName!,
                ),
              _DetailLine(
                scale: scale,
                label: 'Valor',
                value: contribution.valueLabel,
                emphasize: true,
              ),
              _DetailLine(
                scale: scale,
                label: 'Data',
                value: contribution.dateLabel,
              ),
              _DetailLine(
                scale: scale,
                label: 'Método de pagamento',
                value: contribution.method,
              ),
              _DetailLine(
                scale: scale,
                label: 'Igreja',
                value: contribution.church,
              ),
              _DetailLine(
                scale: scale,
                label: 'Identificador',
                value: contribution.id,
                mono: true,
              ),
              SizedBox(height: 20 * scale),
              _SheetActions(
                scale: scale,
                contribution: contribution,
                isLeader: isLeader,
                parentContext: parentContext,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.scale,
    required this.label,
    this.value,
    this.customValue,
    this.emphasize = false,
    this.mono = false,
  });

  final double scale;
  final String label;
  final String? value;
  final Widget? customValue;
  final bool emphasize;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12 * scale),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: HistoricoContribuicoesScreen._line),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13 * scale,
                fontWeight: FontWeight.w400,
                height: 18 / 13,
                color: HistoricoContribuicoesScreen._body,
              ),
            ),
          ),
          SizedBox(width: 16 * scale),
          Expanded(
            child:
                customValue ??
                Text(
                  value ?? '',
                  textAlign: TextAlign.right,
                  style: mono
                      ? TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w500,
                          height: 18 / 13,
                          color: HistoricoContribuicoesScreen._mutedBrown,
                        )
                      : GoogleFonts.inter(
                          fontSize: emphasize ? 18 * scale : 14 * scale,
                          fontWeight: emphasize
                              ? FontWeight.w700
                              : FontWeight.w500,
                          height: emphasize ? 24 / 18 : 20 / 14,
                          color: emphasize
                              ? HistoricoContribuicoesScreen._primaryDark
                              : HistoricoContribuicoesScreen._title,
                        ),
                ),
          ),
        ],
      ),
    );
  }
}

class _SheetActions extends StatelessWidget {
  const _SheetActions({
    required this.scale,
    required this.contribution,
    required this.isLeader,
    required this.parentContext,
  });

  final double scale;
  final ContribuicaoVisualModel contribution;
  final bool isLeader;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final actions = _actionsForStatus(contribution.status);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48 * scale,
          child: ElevatedButton(
            onPressed: () => _runAction(context, actions.primary),
            style: ElevatedButton.styleFrom(
              backgroundColor: HistoricoContribuicoesScreen._primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10 * scale),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(actions.primary),
          ),
        ),
        SizedBox(height: 12 * scale),
        SizedBox(
          width: double.infinity,
          height: 48 * scale,
          child: OutlinedButton(
            onPressed: () => _runAction(context, actions.secondary),
            style: OutlinedButton.styleFrom(
              foregroundColor: HistoricoContribuicoesScreen._primary,
              side: const BorderSide(
                color: HistoricoContribuicoesScreen._primary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10 * scale),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(actions.secondary),
          ),
        ),
      ],
    );
  }

  void _runAction(BuildContext context, String action) {
    switch (action) {
      case 'Copiar identificador':
        Clipboard.setData(ClipboardData(text: contribution.id));
        _showMessage(parentContext, 'Identificador copiado');
      case 'Verificar pagamento':
        _showMessage(
          parentContext,
          'Pagamento em análise. A confirmação aparecerá no histórico.',
        );
      case 'Fechar':
        Navigator.pop(context);
      default:
        Navigator.pop(context);
        Navigator.pushNamed(
          parentContext,
          isLeader ? VisualRoutes.contribuirLeader : VisualRoutes.contribuir,
        );
    }
  }

  static _SheetActionLabels _actionsForStatus(ContribuicaoVisualStatus status) {
    return switch (status) {
      ContribuicaoVisualStatus.aprovado => const _SheetActionLabels(
        'Copiar identificador',
        'Fazer nova contribuição',
      ),
      ContribuicaoVisualStatus.pendente => const _SheetActionLabels(
        'Verificar pagamento',
        'Copiar identificador',
      ),
      ContribuicaoVisualStatus.recusado => const _SheetActionLabels(
        'Tentar novamente',
        'Escolher outro método',
      ),
      ContribuicaoVisualStatus.cancelado => const _SheetActionLabels(
        'Fazer nova contribuição',
        'Fechar',
      ),
    };
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}

class _SheetActionLabels {
  const _SheetActionLabels(this.primary, this.secondary);

  final String primary;
  final String secondary;
}

class _HistoryBottomNavigation extends StatelessWidget {
  const _HistoryBottomNavigation({
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
        border: Border(
          top: BorderSide(color: HistoricoContribuicoesScreen._line),
        ),
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
              child: _HistoryNavigationItem(
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

class _HistoryNavigationItem extends StatelessWidget {
  const _HistoryNavigationItem({
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
        ? HistoricoContribuicoesScreen._primary
        : HistoricoContribuicoesScreen._body;
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
                  color: HistoricoContribuicoesScreen._soft,
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

IconData _methodIcon(String method) {
  final normalized = method.toLowerCase();
  if (normalized.contains('cart')) {
    return Icons.credit_card_rounded;
  }
  if (normalized.contains('boleto')) {
    return Icons.receipt_long_rounded;
  }
  return Icons.qr_code_2_rounded;
}

String _statusLabel(ContribuicaoVisualStatus status) {
  return switch (status) {
    ContribuicaoVisualStatus.aprovado => 'Aprovado',
    ContribuicaoVisualStatus.pendente => 'Pendente',
    ContribuicaoVisualStatus.recusado => 'Recusado',
    ContribuicaoVisualStatus.cancelado => 'Cancelado',
  };
}

Color _statusColor(ContribuicaoVisualStatus status) {
  return switch (status) {
    ContribuicaoVisualStatus.aprovado =>
      HistoricoContribuicoesScreen._approvedText,
    ContribuicaoVisualStatus.pendente =>
      HistoricoContribuicoesScreen._pendingText,
    ContribuicaoVisualStatus.recusado =>
      HistoricoContribuicoesScreen._refusedText,
    ContribuicaoVisualStatus.cancelado =>
      HistoricoContribuicoesScreen._cancelledText,
  };
}

Color _statusBackground(ContribuicaoVisualStatus status) {
  return switch (status) {
    ContribuicaoVisualStatus.aprovado =>
      HistoricoContribuicoesScreen._approvedBg,
    ContribuicaoVisualStatus.pendente =>
      HistoricoContribuicoesScreen._pendingBg,
    ContribuicaoVisualStatus.recusado =>
      HistoricoContribuicoesScreen._refusedBg,
    ContribuicaoVisualStatus.cancelado =>
      HistoricoContribuicoesScreen._cancelledBg,
  };
}
