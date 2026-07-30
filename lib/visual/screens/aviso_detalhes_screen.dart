import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock/avisos_mock_data.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/avisos_bottom_navigation.dart';
import '../widgets/leader_bottom_navigation.dart';

class AvisoDetalhesScreen extends StatelessWidget {
  const AvisoDetalhesScreen({
    super.key,
    required this.notice,
    required this.isLeader,
  });

  static const _designWidth = 390.0;
  static const _primary = Color(0xFF7A0022);
  static const _darkPrimary = Color(0xFF510014);
  static const _background = Color(0xFFFAFAFA);
  static const _title = Color(0xFF1A1C1C);
  static const _body = Color(0xFF584142);
  static const _line = Color(0xFFE5E7EB);
  static const _softBorder = Color(0x33DFBFC0);
  static const _soft = Color(0xFFF5E6EC);

  final AvisoData notice;
  final bool isLeader;

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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

              return Column(
                children: [
                  _DetailsHeader(
                    scale: scale,
                    topPadding: topPadding,
                    onBack: () => Navigator.pop(context),
                    onShare: () => _showMessage(
                      context,
                      'Compartilhamento será conectado futuramente',
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16 * scale,
                        24 * scale,
                        16 * scale,
                        24 * scale,
                      ),
                      child: _DetailsContent(
                        notice: notice,
                        scale: scale,
                        onDownload: () => _showMessage(
                          context,
                          'Download será conectado futuramente',
                        ),
                        onSchedule: () => Navigator.pushNamed(
                          context,
                          isLeader
                              ? VisualRoutes.programacaoLeader
                              : VisualRoutes.programacao,
                        ),
                        onLocation: () => _showMessage(
                          context,
                          'Localização será conectada futuramente',
                        ),
                      ),
                    ),
                  ),
                  if (isLeader)
                    LeaderBottomNavigation(
                      activeItem: LeaderNavItem.notices,
                      scale: scale,
                      bottomPadding: bottomPadding,
                    )
                  else
                    MemberAvisosBottomNavigation(
                      scale: scale,
                      bottomPadding: bottomPadding,
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
    required this.onShare,
  });

  final double scale;
  final double topPadding;
  final VoidCallback onBack;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * scale + topPadding,
      padding: EdgeInsets.fromLTRB(16 * scale, topPadding, 16 * scale, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AvisoDetalhesScreen._line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _HeaderButton(
            scale: scale,
            asset: AvisosMockData.detailsBackAsset,
            width: 16,
            height: 16,
            onTap: onBack,
          ),
          Text(
            'Detalhes',
            style: GoogleFonts.montserrat(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              height: 28 / 20,
              color: AvisoDetalhesScreen._darkPrimary,
            ),
          ),
          _HeaderButton(
            scale: scale,
            asset: AvisosMockData.detailsShareAsset,
            width: 18,
            height: 20,
            onTap: onShare,
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

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({
    required this.notice,
    required this.scale,
    required this.onDownload,
    required this.onSchedule,
    required this.onLocation,
  });

  final AvisoData notice;
  final double scale;
  final VoidCallback onDownload;
  final VoidCallback onSchedule;
  final VoidCallback onLocation;

  @override
  Widget build(BuildContext context) {
    final imageAsset = notice.imageAsset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NoticeHeading(notice: notice, scale: scale),
        if (imageAsset != null) ...[
          SizedBox(height: 23 * scale),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: 300 * scale,
              maxHeight: 448.06 * scale,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(12 * scale),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 358 / 448.06,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12 * scale),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: 23 * scale),
        Text(
          notice.detailDescription,
          style: GoogleFonts.inter(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w400,
            height: 25.6 / 16,
            color: AvisoDetalhesScreen._body,
          ),
        ),
        SizedBox(height: 23 * scale),
        _InformationCard(notice: notice, scale: scale),
        if (notice.attachments.isNotEmpty) ...[
          SizedBox(height: 23 * scale),
          Text(
            'MATERIAIS E ARQUIVOS',
            style: GoogleFonts.montserrat(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w700,
              height: 16.8 / 12,
              letterSpacing: 0.6 * scale,
              color: AvisoDetalhesScreen._body,
            ),
          ),
          SizedBox(height: 16 * scale),
          for (var index = 0; index < notice.attachments.length; index++) ...[
            _AttachmentCard(
              attachment: notice.attachments[index],
              scale: scale,
              onDownload: onDownload,
            ),
            if (index < notice.attachments.length - 1)
              SizedBox(height: 8 * scale),
          ],
        ],
        SizedBox(height: 23 * scale),
        _DetailsActions(
          scale: scale,
          onSchedule: onSchedule,
          onLocation: onLocation,
        ),
      ],
    );
  }
}

class _NoticeHeading extends StatelessWidget {
  const _NoticeHeading({required this.notice, required this.scale});

  final AvisoData notice;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 4 * scale,
          ),
          decoration: BoxDecoration(
            color: AvisoDetalhesScreen._soft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            notice.category,
            style: GoogleFonts.montserrat(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w700,
              height: 16.8 / 12,
              letterSpacing: 2.16 * scale,
              color: AvisoDetalhesScreen._darkPrimary,
            ),
          ),
        ),
        SizedBox(height: 7 * scale),
        Text(
          notice.title,
          style: GoogleFonts.montserrat(
            fontSize: 24 * scale,
            fontWeight: FontWeight.w700,
            height: 28.8 / 24,
            color: AvisoDetalhesScreen._title,
          ),
        ),
        SizedBox(height: 7 * scale),
        Row(
          children: [
            AuthAssetImage(
              AvisosMockData.detailsPublishedAsset,
              width: 11.67 * scale,
              height: 11.67 * scale,
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              child: Text(
                notice.publishedMetadata,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w400,
                  height: 16.8 / 12,
                  color: AvisoDetalhesScreen._body,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.notice, required this.scale});

  final AvisoData notice;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        17 * scale,
        18 * scale,
        17 * scale,
        17 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AvisoDetalhesScreen._softBorder),
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InformationItem(
                  label: 'DATA',
                  value: notice.detailDate,
                  asset: AvisosMockData.detailsCalendarAsset,
                  iconWidth: 10.5,
                  iconHeight: 11.67,
                  scale: scale,
                ),
              ),
              SizedBox(width: 16 * scale),
              Expanded(
                child: _InformationItem(
                  label: 'HORÁRIO',
                  value: notice.detailTime,
                  asset: AvisosMockData.detailsClockAsset,
                  iconWidth: 11.67,
                  iconHeight: 11.67,
                  scale: scale,
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),
          Container(
            width: double.infinity,
            height: 1,
            color: AvisoDetalhesScreen._softBorder,
          ),
          SizedBox(height: 16 * scale),
          _InformationItem(
            label: 'LOCAL',
            value: notice.detailLocation,
            asset: AvisosMockData.detailsHomeAsset,
            iconWidth: 9.33,
            iconHeight: 10.5,
            scale: scale,
          ),
          SizedBox(height: 16 * scale),
          _InformationItem(
            label: 'ENDEREÇO',
            value: notice.detailAddress,
            asset: AvisosMockData.detailsLocationAsset,
            iconWidth: 9.33,
            iconHeight: 11.67,
            scale: scale,
          ),
        ],
      ),
    );
  }
}

class _InformationItem extends StatelessWidget {
  const _InformationItem({
    required this.label,
    required this.value,
    required this.asset,
    required this.iconWidth,
    required this.iconHeight,
    required this.scale,
  });

  final String label;
  final String value;
  final String asset;
  final double iconWidth;
  final double iconHeight;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AuthAssetImage(
              asset,
              width: iconWidth * scale,
              height: iconHeight * scale,
            ),
            SizedBox(width: 4 * scale),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w400,
                height: 16.8 / 12,
                letterSpacing: 0.6 * scale,
                color: AvisoDetalhesScreen._body,
              ),
            ),
          ],
        ),
        SizedBox(height: 4 * scale),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w500,
            height: 19.6 / 14,
            color: AvisoDetalhesScreen._title,
          ),
        ),
      ],
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    required this.attachment,
    required this.scale,
    required this.onDownload,
  });

  final AvisoAttachmentData attachment;
  final double scale;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AvisoDetalhesScreen._softBorder),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Row(
        children: [
          AuthAssetImage(
            AvisosMockData.detailsFileAsset,
            width: 16 * scale,
            height: 20 * scale,
          ),
          SizedBox(width: 16 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                    height: 19.6 / 14,
                    color: AvisoDetalhesScreen._title,
                  ),
                ),
                Text(
                  attachment.details,
                  style: GoogleFonts.inter(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w400,
                    height: 16.8 / 12,
                    color: AvisoDetalhesScreen._body,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onDownload,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: EdgeInsets.all(8 * scale),
              child: AuthAssetImage(
                AvisosMockData.detailsDownloadAsset,
                width: 16 * scale,
                height: 16 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsActions extends StatelessWidget {
  const _DetailsActions({
    required this.scale,
    required this.onSchedule,
    required this.onLocation,
  });

  final double scale;
  final VoidCallback onSchedule;
  final VoidCallback onLocation;

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
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          _ActionButton(
            scale: scale,
            label: 'Ver na programação',
            iconAsset: AvisosMockData.detailsCalendarAsset,
            filled: true,
            onTap: onSchedule,
          ),
          SizedBox(height: 8 * scale),
          _ActionButton(
            scale: scale,
            label: 'Abrir localização',
            iconAsset: AvisosMockData.detailsLocationAsset,
            filled: false,
            onTap: onLocation,
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
    return SizedBox(
      width: double.infinity,
      height: 52 * scale,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: ColorFiltered(
          colorFilter: ColorFilter.mode(
            filled ? Colors.white : AvisoDetalhesScreen._primary,
            BlendMode.srcIn,
          ),
          child: AuthAssetImage(
            iconAsset,
            width: 16 * scale,
            height: 18 * scale,
          ),
        ),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: filled ? AvisoDetalhesScreen._primary : Colors.white,
          foregroundColor: filled ? Colors.white : AvisoDetalhesScreen._primary,
          side: BorderSide(
            color: AvisoDetalhesScreen._primary,
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
      ),
    );
  }
}
