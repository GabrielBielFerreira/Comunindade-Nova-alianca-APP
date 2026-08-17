import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock_data.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';
import '../escala_tela.dart';

class SelectChurchScreen extends StatefulWidget {
  const SelectChurchScreen({super.key});

  static const _referenceWidth = 390.0;

  static double _scaleFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final effectiveWidth = math.min(width, _referenceWidth);
    return (effectiveWidth / _referenceWidth).clamp(escalaMinima, 1.0).toDouble();
  }

  @override
  State<SelectChurchScreen> createState() => _SelectChurchScreenState();
}

class _SelectChurchScreenState extends State<SelectChurchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChurchOptionData> get _filteredChurches {
    final query = _normalize(_query);
    if (query.isEmpty) {
      return SelectChurchMockData.churches;
    }

    return SelectChurchMockData.churches
        .where((church) {
          final haystack = _normalize('${church.name} ${church.address}');
          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final scale = SelectChurchScreen._scaleFor(context);
    final churches = _filteredChurches;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SelectChurchTopBar(scale: scale),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16 * scale,
                          16 * scale,
                          16 * scale,
                          0,
                        ),
                        child: Column(
                          children: [
                            _SearchBox(
                              scale: scale,
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() => _query = value);
                              },
                            ),
                            SizedBox(height: 16 * scale),
                            _LocationButton(scale: scale),
                            SizedBox(height: 24 * scale),
                            for (final church in churches) ...[
                              _ChurchCard(
                                church: church,
                                scale: scale,
                                onTap: () =>
                                    _showChurchDetails(context, church),
                              ),
                              SizedBox(height: 16 * scale),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showChurchDetails(BuildContext context, ChurchOptionData church) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      isScrollControlled: true,
      useSafeArea: false,
      builder: (_) => _ChurchDetailsSheet(
        church: church,
        onConfirm: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(VisualRoutes.welcomeAccess);
        },
      ),
    );
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }
}

class _SelectChurchTopBar extends StatelessWidget {
  const _SelectChurchTopBar({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * scale,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8 * scale,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 48 * scale,
                height: 48 * scale,
                child: Center(
                  child: AuthAssetImage(
                    ChurchAssets.back,
                    width: 16 * scale,
                    height: 16 * scale,
                  ),
                ),
              ),
            ),
          ),
          Text(
            SelectChurchMockData.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              height: 28 / 20,
              color: AuthColors.nearBlack,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.scale,
    required this.controller,
    required this.onChanged,
  });

  final double scale;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AuthColors.border),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Row(
        children: [
          SizedBox(width: 16 * scale),
          AuthAssetImage(
            ChurchAssets.search,
            width: 18 * scale,
            height: 18 * scale,
          ),
          SizedBox(width: 22 * scale),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: AuthColors.primary,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.inter(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w400,
                height: 24 / 16,
                color: AuthColors.nearBlack,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: SelectChurchMockData.searchHint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w400,
                  height: 24 / 16,
                  color: AuthColors.muted,
                ),
              ),
            ),
          ),
          SizedBox(width: 16 * scale),
        ],
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52 * scale,
      decoration: BoxDecoration(
        color: AuthColors.primary.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AuthAssetImage(
            ChurchAssets.location,
            width: 18.25 * scale,
            height: 18.25 * scale,
          ),
          SizedBox(width: 8 * scale),
          Text(
            SelectChurchMockData.locationButton,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              color: AuthColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChurchCard extends StatelessWidget {
  const _ChurchCard({
    required this.church,
    required this.scale,
    required this.onTap,
  });

  final ChurchOptionData church;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8 * scale),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(17 * scale),
          decoration: BoxDecoration(
            border: Border.all(color: AuthColors.border),
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                        color: AuthColors.nearBlack,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      church.address,
                      style: GoogleFonts.inter(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w400,
                        height: 22.75 / 14,
                        color: AuthColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16 * scale),
              AuthAssetImage(
                ChurchAssets.chevron,
                width: 7.42 * scale,
                height: 12 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChurchDetailsSheet extends StatelessWidget {
  const _ChurchDetailsSheet({required this.church, required this.onConfirm});

  final ChurchOptionData church;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final scale = SelectChurchScreen._scaleFor(context);
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
            style: GoogleFonts.inter(
              fontSize: 22 * scale,
              fontWeight: FontWeight.w700,
              height: 33 / 22,
              color: const Color(0xFF454555),
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
            color: AuthColors.primary.withValues(alpha: 0.2),
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
                  color: AuthColors.nearBlack,
                ),
              ),
              SizedBox(height: 8 * scale),
              Text(
                church.address,
                style: GoogleFonts.inter(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w400,
                  height: 22.75 / 16,
                  color: AuthColors.muted,
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
          color: const Color(0xFFE5E7EB),
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
          color: AuthColors.primary,
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
          border: Border.all(color: AuthColors.primary, width: 2 * scale),
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 17 * scale,
              fontWeight: FontWeight.w700,
              height: 25.5 / 17,
              color: AuthColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
