import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock/programacao_mock_data.dart';
import 'auth_widgets.dart';

class ProgramacaoCard extends StatelessWidget {
  const ProgramacaoCard({
    super.key,
    required this.event,
    required this.scale,
    required this.onReminderTap,
    required this.onDetailsTap,
  });

  static const _primary = Color(0xFF7A0022);
  static const _title = Color(0xFF1C1B1B);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);

  final ProgramacaoEventData event;
  final double scale;
  final VoidCallback onReminderTap;
  final VoidCallback onDetailsTap;

  @override
  Widget build(BuildContext context) {
    final reminderColor = event.reminderEnabled ? _primary : _muted;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        17 * scale,
        17 * scale,
        17 * scale,
        16 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: Offset(0, 1 * scale),
            blurRadius: 2 * scale,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w700,
                    height: 16.8 / 12,
                    letterSpacing: 1.2 * scale,
                    color: const Color(0xFF510014),
                  ),
                ),
              ),
              InkWell(
                onTap: onReminderTap,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3 * scale,
                    vertical: 2 * scale,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        event.reminderEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        size: 23 * scale,
                        color: reminderColor,
                      ),
                      SizedBox(width: 5 * scale),
                      Text(
                        'Lembrete',
                        style: GoogleFonts.inter(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w400,
                          height: 21 / 14,
                          color: reminderColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * scale),
          Text(
            event.title,
            style: GoogleFonts.montserrat(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              height: 28 / 20,
              color: _title,
            ),
          ),
          SizedBox(height: 9 * scale),
          Row(
            children: [
              AuthAssetImage(
                ProgramacaoAssets.time,
                width: 16 * scale,
                height: 16 * scale,
              ),
              SizedBox(width: 8 * scale),
              Text(
                event.time,
                style: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w400,
                  height: 21 / 14,
                  color: _title,
                ),
              ),
            ],
          ),
          SizedBox(height: 9 * scale),
          Row(
            children: [
              AuthAssetImage(
                ProgramacaoAssets.location,
                width: 16 * scale,
                height: 16 * scale,
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  event.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w400,
                    height: 21 / 14,
                    color: _title,
                  ),
                ),
              ),
              InkWell(
                onTap: onDetailsTap,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: EdgeInsets.all(2 * scale),
                  child: Icon(
                    Icons.open_in_new_rounded,
                    size: 28 * scale,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
