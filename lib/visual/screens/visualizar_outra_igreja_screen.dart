import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock_data.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/internal_header.dart';

/// Tela "Visualizar outra igreja" (membro e liderança — idêntica para ambos).
///
/// Tela interna (push), sem bottom navigation. Dados simulados.
class VisualizarOutraIgrejaScreen extends StatefulWidget {
  const VisualizarOutraIgrejaScreen({super.key});

  static const churches = <ChurchOptionData>[
    ChurchOptionData(
      name: 'Nova Aliança Olinda',
      address:
          'Av. Leopoldino Canuto de Melo, 846 - Caixa D\'Água, Olinda - PE, 53210-250',
    ),
    ChurchOptionData(
      name: 'Nova Aliança Petrolina',
      address: 'Rua 47, número 180 - São Gonçalo',
    ),
  ];

  @override
  State<VisualizarOutraIgrejaScreen> createState() =>
      _VisualizarOutraIgrejaScreenState();
}

class _VisualizarOutraIgrejaScreenState
    extends State<VisualizarOutraIgrejaScreen> {
  static const _designWidth = 394.0;
  static const _background = Color(0xFFFAFAFA);
  static const _primary = Color(0xFF7A0022);
  static const _title = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChurchOptionData> get _filteredChurches {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return VisualizarOutraIgrejaScreen.churches;
    }
    return VisualizarOutraIgrejaScreen.churches
        .where(
          (church) =>
              church.name.toLowerCase().contains(query) ||
              church.address.toLowerCase().contains(query),
        )
        .toList();
  }

  void _showFutureMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Abre o bottom sheet de confirmação. Ao confirmar, fecha o sheet com o
  /// nome da igreja e devolve esse nome para a tela de Configurações.
  Future<void> _showChurchDetails(ChurchOptionData church) async {
    final selectedName = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      isScrollControlled: true,
      builder: (sheetContext) => _ChurchDetailsSheet(
        church: church,
        onConfirm: () => Navigator.of(sheetContext).pop(church.name),
      ),
    );

    if (selectedName != null && mounted) {
      Navigator.of(context).pop(selectedName);
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
                  .clamp(0.86, 1.0)
                  .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;
              final churches = _filteredChurches;

              return Column(
                children: [
                  InternalHeader(
                    title: 'Visualizar outra igreja',
                    scale: scale,
                    topPadding: topPadding,
                    uppercaseTitle: false,
                    titleSize: 18,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16 * scale,
                        16 * scale,
                        16 * scale,
                        bottomPadding + 24 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SearchField(
                            scale: scale,
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _query = value),
                          ),
                          SizedBox(height: 12 * scale),
                          _LocationButton(
                            scale: scale,
                            onTap: () => _showFutureMessage(
                              'Localização atual será conectada futuramente',
                            ),
                          ),
                          SizedBox(height: 12 * scale),
                          _InfoCard(scale: scale),
                          SizedBox(height: 20 * scale),
                          if (churches.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 32 * scale,
                              ),
                              child: Center(
                                child: Text(
                                  'Nenhuma igreja encontrada',
                                  style: GoogleFonts.inter(
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w400,
                                    color: _muted,
                                  ),
                                ),
                              ),
                            )
                          else
                            for (var index = 0;
                                index < churches.length;
                                index++) ...[
                              _ChurchCard(
                                scale: scale,
                                church: churches[index],
                                onTap: () =>
                                    _showChurchDetails(churches[index]),
                              ),
                              if (index < churches.length - 1)
                                SizedBox(height: 12 * scale),
                            ],
                        ],
                      ),
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.scale,
    required this.controller,
    required this.onChanged,
  });

  final double scale;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w400,
        color: _VisualizarOutraIgrejaScreenState._title,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintText: 'Busque o nome ou endereço da igreja...',
        hintStyle: GoogleFonts.inter(
          fontSize: 14 * scale,
          fontWeight: FontWeight.w400,
          color: _VisualizarOutraIgrejaScreenState._muted,
        ),
        prefixIcon: Icon(
          Icons.search,
          size: 20 * scale,
          color: _VisualizarOutraIgrejaScreenState._muted,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 14 * scale),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12 * scale),
          borderSide: const BorderSide(
            color: _VisualizarOutraIgrejaScreenState._line,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12 * scale),
          borderSide: const BorderSide(
            color: _VisualizarOutraIgrejaScreenState._line,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12 * scale),
          borderSide: const BorderSide(
            color: _VisualizarOutraIgrejaScreenState._primary,
          ),
        ),
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _VisualizarOutraIgrejaScreenState._soft,
      borderRadius: BorderRadius.circular(12 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12 * scale),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14 * scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.my_location,
                size: 20 * scale,
                color: _VisualizarOutraIgrejaScreenState._primary,
              ),
              SizedBox(width: 8 * scale),
              Text(
                'Usar localização atual',
                style: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                  color: _VisualizarOutraIgrejaScreenState._primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _VisualizarOutraIgrejaScreenState._line),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20 * scale,
            color: _VisualizarOutraIgrejaScreenState._muted,
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Text(
              'Esta troca altera apenas o que você vê no app. '
              'Sua igreja vinculada continua a mesma.',
              style: GoogleFonts.inter(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w400,
                height: 21 / 14,
                color: _VisualizarOutraIgrejaScreenState._muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChurchCard extends StatelessWidget {
  const _ChurchCard({
    required this.scale,
    required this.church,
    required this.onTap,
  });

  final double scale;
  final ChurchOptionData church;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12 * scale),
        child: Container(
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            border: Border.all(color: _VisualizarOutraIgrejaScreenState._line),
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      church.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w600,
                        height: 22 / 16,
                        color: _VisualizarOutraIgrejaScreenState._title,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      church.address,
                      style: GoogleFonts.inter(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w400,
                        height: 19 / 13,
                        color: _VisualizarOutraIgrejaScreenState._muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12 * scale),
              Icon(
                Icons.chevron_right_rounded,
                size: 22 * scale,
                color: _VisualizarOutraIgrejaScreenState._muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet de confirmação da igreja — mesmo padrão do
/// `select_church_screen.dart`, adaptado às cores desta tela.
class _ChurchDetailsSheet extends StatelessWidget {
  const _ChurchDetailsSheet({required this.church, required this.onConfirm});

  final ChurchOptionData church;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final scale =
        (MediaQuery.sizeOf(context).width /
                _VisualizarOutraIgrejaScreenState._designWidth)
            .clamp(0.86, 1.0)
            .toDouble();
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final sheetHeight = math.min(
      554 * scale + bottomPadding,
      screenHeight * 0.8,
    );

    return Container(
      width: double.infinity,
      height: sheetHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: Offset(0, 25 * scale),
            blurRadius: 50 * scale,
            spreadRadius: -12 * scale,
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24 * scale,
            24 * scale,
            24 * scale,
            (24 * scale) + bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHeader(scale: scale),
              SizedBox(height: 24 * scale),
              _ChurchInfoRow(church: church, scale: scale),
              SizedBox(height: 24 * scale),
              _ChurchMap(scale: scale),
              SizedBox(height: 24 * scale),
              _SheetPrimaryButton(
                text: SelectChurchMockData.confirmChoice,
                scale: scale,
                onTap: onConfirm,
              ),
              SizedBox(height: 12 * scale),
              _SheetOutlineButton(
                text: SelectChurchMockData.backToList,
                scale: scale,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 33 * scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            SelectChurchMockData.modalTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 22 * scale,
              fontWeight: FontWeight.w700,
              height: 33 / 22,
              color: _VisualizarOutraIgrejaScreenState._title,
            ),
          ),
          Positioned(
            right: -2 * scale,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(
                width: 36 * scale,
                height: 36 * scale,
                child: Center(
                  child: AuthAssetImage(
                    ChurchAssets.modalClose,
                    width: 28 * scale,
                    height: 28 * scale,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChurchInfoRow extends StatelessWidget {
  const _ChurchInfoRow({required this.church, required this.scale});

  final ChurchOptionData church;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44 * scale,
          height: 44 * scale,
          decoration: BoxDecoration(
            color: _VisualizarOutraIgrejaScreenState._soft,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AuthAssetImage(
              ChurchAssets.modalLocation,
              width: 20 * scale,
              height: 20 * scale,
            ),
          ),
        ),
        SizedBox(width: 16 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                church.name,
                style: GoogleFonts.montserrat(
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.w600,
                  height: 28 / 20,
                  color: _VisualizarOutraIgrejaScreenState._title,
                ),
              ),
              SizedBox(height: 8 * scale),
              Text(
                church.address,
                style: GoogleFonts.inter(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w400,
                  height: 22.75 / 16,
                  color: _VisualizarOutraIgrejaScreenState._muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChurchMap extends StatelessWidget {
  const _ChurchMap({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16 * scale),
      child: Container(
        height: 180 * scale,
        decoration: BoxDecoration(
          color: _VisualizarOutraIgrejaScreenState._line,
          border: Border.all(color: const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(16 * scale),
        ),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Image.asset(
              ChurchAssets.map,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            AuthAssetImage(
              ChurchAssets.mapPin,
              width: 40 * scale,
              height: 40 * scale,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  const _SheetPrimaryButton({
    required this.text,
    required this.scale,
    required this.onTap,
  });

  final String text;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52 * scale,
        decoration: BoxDecoration(
          color: _VisualizarOutraIgrejaScreenState._primary,
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 17 * scale,
              fontWeight: FontWeight.w700,
              height: 25.5 / 17,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetOutlineButton extends StatelessWidget {
  const _SheetOutlineButton({
    required this.text,
    required this.scale,
    required this.onTap,
  });

  final String text;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52 * scale,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _VisualizarOutraIgrejaScreenState._primary,
            width: 2 * scale,
          ),
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 17 * scale,
              fontWeight: FontWeight.w700,
              height: 25.5 / 17,
              color: _VisualizarOutraIgrejaScreenState._primary,
            ),
          ),
        ),
      ),
    );
  }
}
