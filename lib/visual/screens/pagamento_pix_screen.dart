import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/igreja_info.dart';
import '../../features/contribuir/data/pix_payload.dart';
import '../mock/contribuicao_mock_data.dart';
import '../mock_data.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/leader_bottom_navigation.dart';

/// PIX **manual e honesto**: mostra o QR Code e o "copia e cola" gerados a
/// partir da chave pública da igreja. Não há confirmação automática — o
/// recebimento é conferido pela tesouraria. Nenhum segredo trafega no app.
class PagamentoPixScreen extends StatelessWidget {
  const PagamentoPixScreen({
    super.key,
    required this.isLeader,
    this.contributionType = 'Dízimo',
    this.valueLabel = 'R\$ 0,00',
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
  static const _fieldBackground = Color(0xFFF6F3F2);
  static const _green = Color(0xFF16A34A);

  final bool isLeader;
  final String contributionType;
  final String valueLabel;
  final ContribuicaoCampaignData? campaign;

  double get _valorReais {
    final digits = valueLabel.replaceAll(RegExp(r'\D'), '');
    return (int.tryParse(digits) ?? 0) / 100;
  }

  String get _payload => PixPayload.gerar(
        chave: IgrejaInfo.pixChave,
        valor: _valorReais > 0 ? _valorReais : null,
        nomeRecebedor: IgrejaInfo.nome,
        cidade: 'Olinda',
        txid: campaign?.campanhaId ?? '***',
      );

  @override
  Widget build(BuildContext context) {
    final payload = _payload;
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
              final navHeight = 72 * scale + bottomPadding;

              return Stack(
                children: [
                  Column(
                    children: [
                      _PixHeader(scale: scale, topPadding: topPadding),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            24 * scale,
                            16 * scale,
                            navHeight + 48 * scale,
                          ),
                          child: Column(
                            children: [
                              _PixSummaryCard(
                                scale: scale,
                                type: campaign == null
                                    ? contributionType
                                    : 'Campanha',
                                destination:
                                    campaign?.title ?? IgrejaInfo.nome,
                                valueLabel: valueLabel,
                              ),
                              SizedBox(height: 24 * scale),
                              _PixQrCard(
                                scale: scale,
                                payload: payload,
                                onConcluir: () => _concluir(context),
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
                        : _PixBottomNavigation(
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

  void _concluir(BuildContext context) {
    // PIX manual: não simulamos confirmação. Voltamos ao início da aba
    // Contribuir com uma mensagem honesta de agradecimento.
    Navigator.of(context).popUntil((route) {
      return route.settings.name == VisualRoutes.contribuir ||
          route.settings.name == VisualRoutes.contribuirLeader ||
          route.isFirst;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Obrigado! Assim que a tesouraria confirmar o PIX, sua contribuição '
            'será registrada.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  static Future<void> copiarPayload(
      BuildContext context, String payload) async {
    await Clipboard.setData(ClipboardData(text: payload));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Código PIX copiado. Cole no app do seu banco.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _PixHeader extends StatelessWidget {
  const _PixHeader({required this.scale, required this.topPadding});

  final double scale;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * scale + topPadding,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: PagamentoPixScreen._line)),
      ),
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
                  size: 26 * scale,
                  color: PagamentoPixScreen._primaryDark,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Pagamento PIX',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w600,
                  height: 32 / 24,
                  color: PagamentoPixScreen._primaryDark,
                ),
              ),
            ),
            SizedBox(width: 40 * scale),
          ],
        ),
      ),
    );
  }
}

class _PixSummaryCard extends StatelessWidget {
  const _PixSummaryCard({
    required this.scale,
    required this.type,
    required this.destination,
    required this.valueLabel,
  });

  final double scale;
  final String type;
  final String destination;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25 * scale),
      decoration: _cardDecoration(scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Finalize sua contribuição',
            style: GoogleFonts.montserrat(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              height: 28 / 20,
              color: PagamentoPixScreen._title,
            ),
          ),
          SizedBox(height: 18 * scale),
          _PixSummaryRow(
            scale: scale,
            label: 'Tipo',
            value: type,
            showDivider: true,
          ),
          _PixSummaryRow(
            scale: scale,
            label: 'Destino',
            value: destination,
            showDivider: true,
          ),
          _PixSummaryRow(
            scale: scale,
            label: 'Valor',
            value: valueLabel,
            showDivider: true,
          ),
          _PixSummaryRow(
            scale: scale,
            label: 'Método',
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code_2_rounded,
                  size: 16 * scale,
                  color: PagamentoPixScreen._green,
                ),
                SizedBox(width: 8 * scale),
                Text(
                  'PIX',
                  style: GoogleFonts.inter(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w500,
                    height: 24 / 16,
                    color: PagamentoPixScreen._title,
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

class _PixSummaryRow extends StatelessWidget {
  const _PixSummaryRow({
    required this.scale,
    required this.label,
    this.value,
    this.valueWidget,
    this.showDivider = false,
  });

  final double scale;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: showDivider ? 9 * scale : 4 * scale),
      margin: EdgeInsets.only(bottom: showDivider ? 8 * scale : 0),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: PagamentoPixScreen._line),
              ),
            )
          : null,
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              color: PagamentoPixScreen._mutedBrown,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget ??
                  Text(
                    value ?? '',
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w500,
                      height: 24 / 16,
                      color: PagamentoPixScreen._title,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PixQrCard extends StatelessWidget {
  const _PixQrCard({
    required this.scale,
    required this.payload,
    required this.onConcluir,
  });

  final double scale;
  final String payload;
  final VoidCallback onConcluir;

  @override
  Widget build(BuildContext context) {
    final qrSize = 220 * scale;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25 * scale),
      decoration: _cardDecoration(scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'Escaneie o QR Code no app do seu banco',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
                color: PagamentoPixScreen._mutedBrown,
              ),
            ),
          ),
          SizedBox(height: 16 * scale),
          Center(
            child: Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: PagamentoPixScreen._line),
                borderRadius: BorderRadius.circular(16 * scale),
              ),
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: qrSize,
                gapless: false,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: PagamentoPixScreen._primaryDark,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: PagamentoPixScreen._primaryDark,
                ),
                errorStateBuilder: (_, _) => SizedBox(
                  width: qrSize,
                  height: qrSize,
                  child: const Center(
                    child: Text('Não foi possível gerar o QR.'),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 24 * scale),
          Row(
            children: [
              Expanded(
                child: Divider(color: PagamentoPixScreen._line),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                child: Text(
                  'ou copie o código',
                  style: GoogleFonts.inter(
                    fontSize: 12 * scale,
                    color: PagamentoPixScreen._body,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: PagamentoPixScreen._line),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),
          _PixCopyField(scale: scale, payload: payload),
          SizedBox(height: 16 * scale),
          SizedBox(
            width: double.infinity,
            height: 52 * scale,
            child: ElevatedButton.icon(
              onPressed: () =>
                  PagamentoPixScreen.copiarPayload(context, payload),
              icon: Icon(Icons.copy_rounded, size: 19 * scale),
              label: const Text('Copiar código PIX (copia e cola)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PagamentoPixScreen._primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
          SizedBox(height: 12 * scale),
          SizedBox(
            width: double.infinity,
            height: 50 * scale,
            child: OutlinedButton(
              onPressed: onConcluir,
              style: OutlinedButton.styleFrom(
                foregroundColor: PagamentoPixScreen._primaryDark,
                side: const BorderSide(color: PagamentoPixScreen._primaryDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                ),
              ),
              child: const Text('Já fiz o PIX'),
            ),
          ),
          SizedBox(height: 20 * scale),
          Container(
            padding: EdgeInsets.all(14 * scale),
            decoration: BoxDecoration(
              color: PagamentoPixScreen._fieldBackground,
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18 * scale,
                  color: PagamentoPixScreen._mutedBrown,
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Text(
                    'Este é um PIX manual. O pagamento não é confirmado '
                    'automaticamente pelo app — a tesouraria confere o '
                    'recebimento e registra sua contribuição.',
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w400,
                      height: 17 / 12,
                      color: PagamentoPixScreen._mutedBrown,
                    ),
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

class _PixCopyField extends StatelessWidget {
  const _PixCopyField({required this.scale, required this.payload});

  final double scale;
  final String payload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
      decoration: BoxDecoration(
        color: PagamentoPixScreen._fieldBackground,
        border: Border.all(color: PagamentoPixScreen._line),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              payload,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.robotoMono(
                fontSize: 12 * scale,
                height: 16 / 12,
                color: PagamentoPixScreen._mutedBrown,
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
          IconButton(
            onPressed: () => PagamentoPixScreen.copiarPayload(context, payload),
            icon: Icon(
              Icons.copy_rounded,
              size: 20 * scale,
              color: PagamentoPixScreen._primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration(double scale) {
  return BoxDecoration(
    color: Colors.white,
    border: Border.all(color: PagamentoPixScreen._line),
    borderRadius: BorderRadius.circular(16 * scale),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        offset: Offset(0, 1 * scale),
        blurRadius: 1.5 * scale,
      ),
    ],
  );
}

class _PixBottomNavigation extends StatelessWidget {
  const _PixBottomNavigation({
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
        border: Border(top: BorderSide(color: PagamentoPixScreen._line)),
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
              child: _PixNavigationItem(
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

class _PixNavigationItem extends StatelessWidget {
  const _PixNavigationItem({
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
        ? PagamentoPixScreen._primary
        : PagamentoPixScreen._body;
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
        if (selected) return;

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
      },
      child: Center(
        child: selected
            ? Container(
                width: 61 * scale,
                height: 41 * scale,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E6EC),
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
