import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock/avisos_mock_data.dart';
import 'auth_widgets.dart';

class AvisoCard extends StatelessWidget {
  const AvisoCard({
    super.key,
    required this.notice,
    required this.scale,
    required this.onDetails,
    required this.onScale,
  });

  static const _primary = Color(0xFF7A0022);
  static const _title = Color(0xFF111111);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);

  final AvisoData notice;
  final double scale;
  final VoidCallback onDetails;
  final VoidCallback onScale;

  @override
  Widget build(BuildContext context) {
    final imageAsset = notice.imageAsset;

    return Container(
      height: 191 * scale,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            left: 0,
            right: null,
            child: Container(width: 4 * scale, color: _primary),
          ),
          if (imageAsset == null)
            _TextNoticeContent(
              notice: notice,
              scale: scale,
              onDetails: onDetails,
              onScale: onScale,
            )
          else
            _ImageNoticeContent(
              notice: notice,
              scale: scale,
              onDetails: onDetails,
              imageAsset: imageAsset,
            ),
        ],
      ),
    );
  }
}

class _TextNoticeContent extends StatelessWidget {
  const _TextNoticeContent({
    required this.notice,
    required this.scale,
    required this.onDetails,
    required this.onScale,
  });

  final AvisoData notice;
  final double scale;
  final VoidCallback onDetails;
  final VoidCallback onScale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        17 * scale,
        16 * scale,
        17 * scale,
        13 * scale,
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BadgeAndTime(notice: notice, scale: scale),
              SizedBox(height: 8 * scale),
              Text(
                notice.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _titleStyle(scale),
              ),
              SizedBox(height: 4 * scale),
              Text(
                notice.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: _bodyStyle(scale),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              children: [
                if (notice.showScaleAction)
                  InkWell(
                    onTap: onScale,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 3 * scale),
                      child: Row(
                        children: [
                          AuthAssetImage(
                            AvisosMockData.escalaIconAsset,
                            width: 15 * scale,
                            height: 15 * scale,
                          ),
                          SizedBox(width: 8 * scale),
                          Text(
                            'Ver escala',
                            style: GoogleFonts.inter(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w500,
                              height: 21 / 14,
                              color: AvisoCard._title,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                _DetailsButton(scale: scale, onTap: onDetails),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageNoticeContent extends StatelessWidget {
  const _ImageNoticeContent({
    required this.notice,
    required this.scale,
    required this.onDetails,
    required this.imageAsset,
  });

  final AvisoData notice;
  final double scale;
  final VoidCallback onDetails;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              17 * scale,
              16 * scale,
              10 * scale,
              13 * scale,
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryBadge(label: notice.category, scale: scale),
                    SizedBox(height: 9 * scale),
                    Text(
                      notice.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _titleStyle(scale),
                    ),
                    SizedBox(height: 5 * scale),
                    Text(
                      notice.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: _bodyStyle(scale),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Row(
                    children: [
                      Text(notice.publishedAt, style: _timeStyle(scale)),
                      const Spacer(),
                      _DetailsButton(scale: scale, onTap: onDetails),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(11 * scale),
            bottomRight: Radius.circular(11 * scale),
          ),
          child: Image.asset(
            imageAsset,
            width: 100 * scale,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) =>
                SizedBox(width: 100 * scale),
          ),
        ),
      ],
    );
  }
}

class _BadgeAndTime extends StatelessWidget {
  const _BadgeAndTime({required this.notice, required this.scale});

  final AvisoData notice;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CategoryBadge(label: notice.category, scale: scale),
        const Spacer(),
        Text(notice.publishedAt, style: _timeStyle(scale)),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 3 * scale,
      ),
      decoration: BoxDecoration(
        color: AvisoCard._soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12 * scale,
          fontWeight: FontWeight.w700,
          height: 18 / 12,
          color: const Color(0xFF510014),
        ),
      ),
    );
  }
}

class _DetailsButton extends StatelessWidget {
  const _DetailsButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 2 * scale,
          vertical: 3 * scale,
        ),
        child: Text(
          'Detalhes',
          style: GoogleFonts.inter(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w500,
            height: 21 / 14,
            color: AvisoCard._primary,
          ),
        ),
      ),
    );
  }
}

TextStyle _titleStyle(double scale) {
  return GoogleFonts.montserrat(
    fontSize: 20 * scale,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    color: AvisoCard._title,
  );
}

TextStyle _bodyStyle(double scale) {
  return GoogleFonts.inter(
    fontSize: 14 * scale,
    fontWeight: FontWeight.w400,
    height: 21 / 14,
    color: AvisoCard._muted,
  );
}

TextStyle _timeStyle(double scale) {
  return GoogleFonts.inter(
    fontSize: 12 * scale,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
    color: AvisoCard._muted,
  );
}
