import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../features/eventos/data/evento_model.dart';
import '../../features/eventos/providers/eventos_providers.dart';
import '../mock/programacao_mock_data.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/leader_bottom_navigation.dart';
import '../widgets/programacao_bottom_navigation.dart';
import '../widgets/programacao_card.dart';
import '../widgets/visitor_bottom_navigation.dart';
import 'programacao_detalhes_screen.dart';

String _categoriaEvento(TipoEvento t) => switch (t) {
      TipoEvento.culto => 'Culto',
      TipoEvento.ministerio => 'Ministério',
      TipoEvento.eventoEspecial => 'Evento especial',
    };

ProgramacaoEventData _eventoParaCard(EventoModel e) => ProgramacaoEventData(
      category: _categoriaEvento(e.tipo),
      title: e.titulo,
      time: e.horario,
      location: e.local,
      reminderEnabled: false,
    );

ProgramacaoDetalhesData _eventoParaDetalhes(EventoModel e) =>
    ProgramacaoDetalhesData(
      title: e.titulo,
      dayTimeSummary: '${Formatters.data(e.data)} • ${e.horario}',
      locationSummary: e.local,
      description: e.descricao,
      date: Formatters.data(e.data),
      time: e.horario,
      audience: e.publico ? 'Aberto a todos' : 'Membros',
      locationName: e.local,
      address: '',
      hasLiveStream: false,
    );

class ProgramacaoScreen extends ConsumerStatefulWidget {
  const ProgramacaoScreen({
    super.key,
    required this.isLeader,
    this.isVisitor = false,
  });

  final bool isLeader;
  final bool isVisitor;

  @override
  ConsumerState<ProgramacaoScreen> createState() => _ProgramacaoScreenState();
}

class _ProgramacaoScreenState extends ConsumerState<ProgramacaoScreen> {
  static const _designWidth = 390.0;
  static const _background = Color(0xFFFAFAFA);
  static const _primary = Color(0xFF7A0022);
  static const _darkPrimary = Color(0xFF510014);
  static const _title = Color(0xFF1C1B1B);
  static const _body = Color(0xFF584142);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);

  int _selectedDay = ProgramacaoMockData.eventDay;

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

  void _goToNotices() {
    Navigator.pushNamed(
      context,
      widget.isLeader ? VisualRoutes.avisosLeader : VisualRoutes.avisos,
    );
  }

  Widget _buildEventos(double scale) {
    final async = ref.watch(eventosStreamProvider);
    return async.when(
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: 48 * scale),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: EdgeInsets.symmetric(vertical: 24 * scale),
        child: Text(
          'Não foi possível carregar a programação. Verifique sua conexão.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 15 * scale, color: _body),
        ),
      ),
      data: (eventos) {
        final lista =
            widget.isVisitor ? eventos.where((e) => e.publico).toList() : eventos;
        if (lista.isEmpty) {
          return _EmptyProgramacao(
            scale: scale,
            onNextEvents: () => _showMessage('Nenhum evento futuro no momento.'),
            onNotices: _goToNotices,
          );
        }
        return Column(
          children: [
            for (var index = 0; index < lista.length; index++) ...[
              ProgramacaoCard(
                event: _eventoParaCard(lista[index]),
                scale: scale,
                onReminderTap: () => _showMessage(
                  'Você receberá um lembrete por notificação.',
                ),
                onDetailsTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(
                      name: VisualRoutes.programacaoDetalhes,
                    ),
                    builder: (_) => ProgramacaoDetalhesScreen(
                      details: _eventoParaDetalhes(lista[index]),
                      isLeader: widget.isLeader,
                    ),
                  ),
                ),
              ),
              if (index < lista.length - 1) SizedBox(height: 16 * scale),
            ],
          ],
        );
      },
    );
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
                      _ProgramacaoHeader(
                        scale: scale,
                        topPadding: topPadding,
                        onCalendar: () => _showMessage(
                          'Veja a lista de eventos abaixo.',
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            20 * scale,
                            16 * scale,
                            navigationHeight + 24 * scale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _WeekHeading(
                                scale: scale,
                                onWeekChange: () => _showMessage(
                                  'Mostrando os próximos eventos.',
                                ),
                              ),
                              SizedBox(height: 24 * scale),
                              _DaySelector(
                                scale: scale,
                                selectedDay: _selectedDay,
                                onSelected: (day) {
                                  setState(() => _selectedDay = day);
                                },
                              ),
                              SizedBox(height: 22 * scale),
                              _buildEventos(scale),
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
                        : widget.isVisitor
                        ? VisitorBottomNavigation(
                            activeItem: VisitorNavItem.schedule,
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

class _ProgramacaoHeader extends StatelessWidget {
  const _ProgramacaoHeader({
    required this.scale,
    required this.topPadding,
    required this.onCalendar,
  });

  final double scale;
  final double topPadding;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * scale + topPadding,
      padding: EdgeInsets.fromLTRB(16 * scale, topPadding, 16 * scale, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _ProgramacaoScreenState._line),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 40 * scale, height: 40 * scale),
          Expanded(
            child: Text(
              'Programação',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 20 * scale,
                fontWeight: FontWeight.w600,
                height: 28 / 20,
                color: _ProgramacaoScreenState._darkPrimary,
              ),
            ),
          ),
          _HeaderButton(
            scale: scale,
            asset: ProgramacaoAssets.calendar,
            width: 34,
            height: 36,
            onTap: onCalendar,
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.scale,
    required this.asset,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final double scale;
  final String asset;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 40 * scale,
        height: 40 * scale,
        child: Center(
          child: AuthAssetImage(
            asset,
            width: width * scale,
            height: height * scale,
          ),
        ),
      ),
    );
  }
}

class _WeekHeading extends StatelessWidget {
  const _WeekHeading({required this.scale, required this.onWeekChange});

  final double scale;
  final VoidCallback onWeekChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Visão Semanal',
            style: GoogleFonts.montserrat(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              height: 28 / 20,
              color: _ProgramacaoScreenState._title,
            ),
          ),
        ),
        _WeekArrow(
          scale: scale,
          asset: ProgramacaoAssets.weekLeft,
          onTap: onWeekChange,
        ),
        SizedBox(width: 8 * scale),
        Text(
          ProgramacaoMockData.weekLabel,
          style: GoogleFonts.inter(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w600,
            height: 21 / 14,
            color: _ProgramacaoScreenState._darkPrimary,
          ),
        ),
        SizedBox(width: 8 * scale),
        _WeekArrow(
          scale: scale,
          asset: ProgramacaoAssets.weekRight,
          onTap: onWeekChange,
        ),
      ],
    );
  }
}

class _WeekArrow extends StatelessWidget {
  const _WeekArrow({
    required this.scale,
    required this.asset,
    required this.onTap,
  });

  final double scale;
  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 16 * scale,
        height: 32 * scale,
        child: Center(
          child: AuthAssetImage(asset, width: 6.2 * scale, height: 10 * scale),
        ),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.scale,
    required this.selectedDay,
    required this.onSelected,
  });

  final double scale;
  final int selectedDay;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: ProgramacaoMockData.days.length,
        separatorBuilder: (_, index) => SizedBox(width: 6.4 * scale),
        itemBuilder: (context, index) {
          final day = ProgramacaoMockData.days[index];
          final selected = day.day == selectedDay;

          return InkWell(
            onTap: () => onSelected(day.day),
            borderRadius: BorderRadius.circular(12 * scale),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 56 * scale,
              height: 72 * scale,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? _ProgramacaoScreenState._primary : null,
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.weekday,
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w400,
                      height: 16.8 / 12,
                      color: selected
                          ? Colors.white
                          : _ProgramacaoScreenState._body,
                    ),
                  ),
                  SizedBox(height: 5 * scale),
                  Text(
                    '${day.day}',
                    style: GoogleFonts.montserrat(
                      fontSize: 20 * scale,
                      fontWeight: FontWeight.w600,
                      height: 28 / 20,
                      color: selected
                          ? Colors.white
                          : _ProgramacaoScreenState._body,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyProgramacao extends StatelessWidget {
  const _EmptyProgramacao({
    required this.scale,
    required this.onNextEvents,
    required this.onNotices,
  });

  final double scale;
  final VoidCallback onNextEvents;
  final VoidCallback onNotices;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        17 * scale,
        49 * scale,
        17 * scale,
        33 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E2E1)),
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: Offset(0, 4 * scale),
            blurRadius: 24 * scale,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 104 * scale,
            height: 104 * scale,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _ProgramacaoScreenState._soft,
              shape: BoxShape.circle,
            ),
            child: AuthAssetImage(
              ProgramacaoAssets.empty,
              width: 32 * scale,
              height: 36.5 * scale,
            ),
          ),
          SizedBox(height: 24 * scale),
          Text(
            'Não há programação para este\ndia',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              height: 28 / 20,
              color: _ProgramacaoScreenState._title,
            ),
          ),
          SizedBox(height: 12 * scale),
          Text(
            'Aproveite para acompanhar os avisos e\nconteúdos da comunidade.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
              color: _ProgramacaoScreenState._body,
            ),
          ),
          SizedBox(height: 42 * scale),
          _EmptyActionButton(
            scale: scale,
            label: 'Ver próximos eventos',
            filled: true,
            onTap: onNextEvents,
          ),
          SizedBox(height: 16 * scale),
          _EmptyActionButton(
            scale: scale,
            label: 'Ir para avisos',
            filled: false,
            onTap: onNotices,
          ),
        ],
      ),
    );
  }
}

class _EmptyActionButton extends StatelessWidget {
  const _EmptyActionButton({
    required this.scale,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final double scale;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48 * scale,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: filled
              ? _ProgramacaoScreenState._primary
              : Colors.white,
          foregroundColor: filled
              ? Colors.white
              : _ProgramacaoScreenState._darkPrimary,
          side: BorderSide(
            color: _ProgramacaoScreenState._primary,
            width: filled ? 0 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w500,
            height: 21 / 14,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
