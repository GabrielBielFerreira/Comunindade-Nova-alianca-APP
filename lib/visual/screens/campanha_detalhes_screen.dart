import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock/contribuicao_mock_data.dart';
import '../widgets/internal_header.dart';

/// Detalhes de uma campanha. O botão "Contribuir para esta campanha" retorna a
/// campanha selecionada ([ContribuicaoCampaignData]) para a tela Contribuir,
/// que segue o fluxo normal já vinculando a contribuição à campanha
/// ([ContribuicaoCampaignData.campanhaId]).
class CampanhaDetalhesScreen extends StatelessWidget {
  const CampanhaDetalhesScreen({super.key, required this.campaign});

  final ContribuicaoCampaignData campaign;

  static const _designWidth = 390.0;
  static const _background = Color(0xFFFAFAFA);
  static const _primary = Color(0xFF7A0022);
  static const _primaryDark = Color(0xFF510014);
  static const _title = Color(0xFF1C1B1B);
  static const _body = Color(0xFF584142);
  static const _muted = Color(0xFF6B7280);
  static const _soft = Color(0xFFF5E6EC);
  static const _accent = Color(0xFFC0392B);

  @override
  Widget build(BuildContext context) {
    final buttonColor = campaign.urgent ? _accent : _primaryDark;
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
          child: Builder(
            builder: (context) {
              final scale = (MediaQuery.sizeOf(context).width / _designWidth)
                  .clamp(0.86, 1.0)
                  .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;

              return Column(
                children: [
                  InternalHeader(
                    title: 'Campanha',
                    scale: scale,
                    topPadding: topPadding,
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
                          _CampaignImage(scale: scale, campaign: campaign),
                          SizedBox(height: 20 * scale),
                          if (campaign.urgent) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * scale,
                                vertical: 4 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: _accent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'URGENTE',
                                style: GoogleFonts.inter(
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6 * scale,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 10 * scale),
                          ],
                          Text(
                            campaign.title,
                            style: GoogleFonts.montserrat(
                              fontSize: 24 * scale,
                              fontWeight: FontWeight.w700,
                              height: 30 / 24,
                              color: _title,
                            ),
                          ),
                          SizedBox(height: 16 * scale),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: campaign.progress,
                              minHeight: 10 * scale,
                              backgroundColor: const Color(0xFFE5E2E1),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(buttonColor),
                            ),
                          ),
                          SizedBox(height: 8 * scale),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                campaign.progressLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 13 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: _primary,
                                ),
                              ),
                              Text(
                                campaign.trailingLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 13 * scale,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24 * scale),
                          if ((campaign.description ?? '').trim().isNotEmpty) ...[
                            Text(
                              'SOBRE A CAMPANHA',
                              style: GoogleFonts.montserrat(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5 * scale,
                                color: _title,
                              ),
                            ),
                            SizedBox(height: 8 * scale),
                            Text(
                              campaign.description!,
                              style: GoogleFonts.inter(
                                fontSize: 15 * scale,
                                height: 23 / 15,
                                color: _body,
                              ),
                            ),
                            SizedBox(height: 24 * scale),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 54 * scale,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).pop(campaign),
                              icon: Icon(
                                Icons.volunteer_activism_outlined,
                                size: 18 * scale,
                                color: Colors.white,
                              ),
                              label: const Text('Contribuir para esta campanha'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12 * scale),
                                ),
                                textStyle: GoogleFonts.inter(
                                  fontSize: 15 * scale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
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

class _CampaignImage extends StatelessWidget {
  const _CampaignImage({required this.scale, required this.campaign});

  final double scale;
  final ContribuicaoCampaignData campaign;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16 * scale);
    final placeholder = Container(
      height: 180 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CampanhaDetalhesScreen._soft,
        borderRadius: radius,
      ),
      child: Icon(
        Icons.volunteer_activism_rounded,
        size: 48 * scale,
        color: CampanhaDetalhesScreen._primary,
      ),
    );

    final url = campaign.imageUrl;
    if (url == null || url.trim().isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url,
        height: 180 * scale,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: 180 * scale,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
