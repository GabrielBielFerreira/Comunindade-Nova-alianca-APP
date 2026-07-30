import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/palavra_dia/palavra_do_dia.dart';
import '../mock/oracao_mock_data.dart';
import '../mock_data.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/leader_bottom_navigation.dart';
import '../widgets/oracao_bottom_navigation.dart';
import 'oracao_novo_pedido_screen.dart';
import 'oracao_pedido_urgente_screen.dart';

class OracaoScreen extends StatefulWidget {
  const OracaoScreen({super.key, required this.isLeader});

  final bool isLeader;

  @override
  State<OracaoScreen> createState() => _OracaoScreenState();
}

class _OracaoScreenState extends State<OracaoScreen> {
  static const _designWidth = 390.0;
  static const _background = Color(0xFFFAFAFA);
  static const _primary = Color(0xFF7A0022);
  static const _darkPrimary = Color(0xFF510014);
  static const _title = Color(0xFF1C1B1B);
  static const _body = Color(0xFF584142);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _avatar = Color(0xFFEACDD6);

  int _selectedTab = 1;
  final Set<String> _praying = <String>{};

  List<OracaoRequestData> get _requests => _selectedTab == 0
      ? OracaoMockData.myRequests
      : OracaoMockData.communityRequests;

  String _requestKey(OracaoRequestData request) =>
      '${request.author}-${request.time}-${request.text}';

  int _visiblePrayerCount(OracaoRequestData request) {
    final key = _requestKey(request);
    return request.prayerCount + (_praying.contains(key) ? 1 : 0);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _togglePrayer(OracaoRequestData request) {
    final key = _requestKey(request);
    final isPraying = _praying.contains(key);

    setState(() {
      if (isPraying) {
        _praying.remove(key);
      } else {
        _praying.add(key);
      }
    });

    _showMessage(
      isPraying
          ? 'Oração removida visualmente'
          : 'Você marcou que está orando por ${request.author}',
    );
  }

  void _openDevotional() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final scale = (MediaQuery.sizeOf(context).width / _designWidth)
            .clamp(0.86, 1.0)
            .toDouble();

        return Padding(
          padding: EdgeInsets.fromLTRB(
            24 * scale,
            6 * scale,
            24 * scale,
            28 * scale + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                OracaoMockData.devotionalTitle,
                style: GoogleFonts.montserrat(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w700,
                  color: _title,
                ),
              ),
              SizedBox(height: 12 * scale),
              Text(
                OracaoMockData.verse.replaceAll('\n', ' '),
                style: GoogleFonts.montserrat(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: _primary,
                ),
              ),
              SizedBox(height: 4 * scale),
              Text(
                OracaoMockData.verseReference,
                style: GoogleFonts.inter(fontSize: 13 * scale, color: _muted),
              ),
              SizedBox(height: 16 * scale),
              Text(
                OracaoMockData.devotionalBody,
                style: GoogleFonts.inter(
                  fontSize: 15 * scale,
                  height: 1.5,
                  color: _body,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ignore: unused_element
  void _openRequestSheet({required bool urgent}) {
    final controller = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final scale = (MediaQuery.sizeOf(context).width / _designWidth)
            .clamp(0.86, 1.0)
            .toDouble();

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20 * scale,
            4 * scale,
            20 * scale,
            MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.paddingOf(context).bottom +
                20 * scale,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                urgent ? 'Pedido urgente' : 'Novo pedido',
                style: GoogleFonts.montserrat(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w700,
                  color: _title,
                ),
              ),
              SizedBox(height: 12 * scale),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Digite seu pedido de oração',
                  hintStyle: GoogleFonts.inter(color: _muted),
                  filled: true,
                  fillColor: _background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * scale),
                    borderSide: const BorderSide(color: _line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * scale),
                    borderSide: const BorderSide(color: _line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * scale),
                    borderSide: const BorderSide(color: _primary),
                  ),
                ),
              ),
              SizedBox(height: 14 * scale),
              SizedBox(
                width: double.infinity,
                height: 52 * scale,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showMessage(
                      urgent
                          ? 'Pedido urgente registrado no protótipo'
                          : 'Pedido registrado no protótipo',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                  ),
                  child: Text(
                    'Enviar pedido',
                    style: GoogleFonts.inter(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(controller.dispose);
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
        resizeToAvoidBottomInset: true,
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
                      _TopBar(scale: scale, topPadding: topPadding),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            8 * scale,
                            16 * scale,
                            navigationHeight + 22 * scale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PageHeader(scale: scale),
                              SizedBox(height: 24 * scale),
                              _WordCard(scale: scale, onTap: _openDevotional),
                              SizedBox(height: 24 * scale),
                              _SubmitRequestCard(
                                scale: scale,
                                onNewRequest: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => OracaoNovoPedidoScreen(
                                        isLeader: widget.isLeader,
                                      ),
                                    ),
                                  );
                                },
                                onUrgentRequest: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => OracaoPedidoUrgenteScreen(
                                        isLeader: widget.isLeader,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 24 * scale),
                              _Tabs(
                                scale: scale,
                                selectedTab: _selectedTab,
                                onSelected: (index) {
                                  setState(() => _selectedTab = index);
                                },
                              ),
                              SizedBox(height: 24 * scale),
                              _RecentHeader(
                                scale: scale,
                                onSeeAll: () => Navigator.pushNamed(
                                  context,
                                  widget.isLeader
                                      ? VisualRoutes.muralOracaoLeader
                                      : VisualRoutes.muralOracao,
                                ),
                              ),
                              SizedBox(height: 16 * scale),
                              for (var i = 0; i < _requests.length; i++) ...[
                                _PrayerRequestCard(
                                  scale: scale,
                                  request: _requests[i],
                                  prayerCount: _visiblePrayerCount(
                                    _requests[i],
                                  ),
                                  onPray: () => _togglePrayer(_requests[i]),
                                ),
                                if (i < _requests.length - 1)
                                  SizedBox(height: 8 * scale),
                              ],
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
                            activeItem: LeaderNavItem.prayer,
                            scale: scale,
                            bottomPadding: bottomPadding,
                          )
                        : OracaoBottomNavigation(
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.scale, required this.topPadding});

  final double scale;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * scale + topPadding,
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _OracaoScreenState._line)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(7 * scale, 0, 16 * scale, 1 * scale),
        child: Row(
          children: [
            ClipOval(
              child: Image.asset(
                HomeAssets.logo,
                width: 32 * scale,
                height: 32 * scale,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            SizedBox(width: 11 * scale),
            Expanded(
              child: Text(
                HomeMockData.communityName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 16.5 * scale,
                  fontWeight: FontWeight.w700,
                  height: 31.2 / 16.5,
                  color: _OracaoScreenState._darkPrimary,
                ),
              ),
            ),
            _HeaderIcon(
              asset: HomeAssets.notification,
              scale: scale,
              width: 16,
              height: 20,
              showDot: true,
              onTap: () =>
                  Navigator.pushNamed(context, VisualRoutes.notificacoes),
            ),
            SizedBox(width: 8 * scale),
            _HeaderIcon(
              asset: HomeAssets.menu,
              scale: scale,
              width: 18,
              height: 12,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.asset,
    required this.scale,
    required this.width,
    required this.height,
    this.showDot = false,
    this.onTap,
  });

  final String asset;
  final double scale;
  final double width;
  final double height;
  final bool showDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: 32 * scale,
      height: 36 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AuthAssetImage(asset, width: width * scale, height: height * scale),
          if (showDot)
            Positioned(
              top: 7 * scale,
              right: 6 * scale,
              child: Container(
                width: 8 * scale,
                height: 8 * scale,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          OracaoMockData.title,
          style: GoogleFonts.montserrat(
            fontSize: 24 * scale,
            fontWeight: FontWeight.w700,
            height: 32 / 24,
            color: _OracaoScreenState._darkPrimary,
          ),
        ),
        SizedBox(height: 8 * scale),
        Text(
          OracaoMockData.subtitle,
          style: GoogleFonts.inter(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w400,
            height: 24 / 16,
            color: _OracaoScreenState._muted,
          ),
        ),
      ],
    );
  }
}

class _WordCard extends ConsumerWidget {
  const _WordCard({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palavra = ref.watch(palavraDoDiaProvider).valueOrNull;
    final verso = palavra != null ? '"${palavra.texto}"' : OracaoMockData.verse;
    final referencia = palavra?.referencia ?? OracaoMockData.verseReference;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16 * scale),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.all(20 * scale),
          decoration: BoxDecoration(
            color: _OracaoScreenState._primary,
            borderRadius: BorderRadius.circular(16 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: Offset(0, 1 * scale),
                blurRadius: 2 * scale,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * scale,
                  vertical: 4 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuthAssetImage(
                      HomeAssets.word,
                      width: 14 * scale,
                      height: 14 * scale,
                    ),
                    SizedBox(width: 6 * scale),
                    Text(
                      OracaoMockData.wordLabel,
                      style: GoogleFonts.montserrat(
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w700,
                        height: 15 / 10,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14 * scale),
              Text(
                verso,
                style: GoogleFonts.montserrat(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w500,
                  height: 24.75 / 18,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10 * scale),
              Text(
                referencia,
                style: GoogleFonts.inter(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w400,
                  height: 18 / 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitRequestCard extends StatelessWidget {
  const _SubmitRequestCard({
    required this.scale,
    required this.onNewRequest,
    required this.onUrgentRequest,
  });

  final double scale;
  final VoidCallback onNewRequest;
  final VoidCallback onUrgentRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        25 * scale,
        25 * scale,
        25 * scale,
        24 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _OracaoScreenState._line),
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
          AuthAssetImage(
            OracaoAssets.requestBadge,
            width: 44 * scale,
            height: 44.5 * scale,
          ),
          SizedBox(height: 16 * scale),
          Text(
            OracaoMockData.requestTitle,
            style: GoogleFonts.montserrat(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              height: 28 / 20,
              color: _OracaoScreenState._title,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            OracaoMockData.requestDescription,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
              color: _OracaoScreenState._body,
            ),
          ),
          SizedBox(height: 28 * scale),
          Row(
            children: [
              Expanded(
                child: _RequestButton(
                  scale: scale,
                  label: OracaoMockData.newRequest,
                  asset: OracaoAssets.plus,
                  filled: true,
                  onTap: onNewRequest,
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: _RequestButton(
                  scale: scale,
                  label: OracaoMockData.urgentRequest,
                  asset: OracaoAssets.urgent,
                  filled: false,
                  onTap: onUrgentRequest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestButton extends StatelessWidget {
  const _RequestButton({
    required this.scale,
    required this.label,
    required this.asset,
    required this.filled,
    required this.onTap,
  });

  final double scale;
  final String label;
  final String asset;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = filled ? Colors.white : _OracaoScreenState._body;

    return SizedBox(
      height: 51 * scale,
      child: Material(
        color: filled ? _OracaoScreenState._primary : Colors.white,
        borderRadius: BorderRadius.circular(10 * scale),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10 * scale),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: filled ? null : Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(10 * scale),
              boxShadow: filled
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        offset: const Offset(0, 1),
                        blurRadius: 1,
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AuthAssetImage(
                  asset,
                  width: (filled ? 14 : 20) * scale,
                  height: (filled ? 14 : 20) * scale,
                ),
                SizedBox(width: 8 * scale),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.scale,
    required this.selectedTab,
    required this.onSelected,
  });

  final double scale;
  final int selectedTab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _OracaoScreenState._line)),
      ),
      child: Row(
        children: [
          _TabButton(
            label: OracaoMockData.myRequestsTab,
            scale: scale,
            selected: selectedTab == 0,
            onTap: () => onSelected(0),
          ),
          _TabButton(
            label: OracaoMockData.communityTab,
            scale: scale,
            selected: selectedTab == 1,
            onTap: () => onSelected(1),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.scale,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double scale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 35 * scale,
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? _OracaoScreenState._primary
                    : _OracaoScreenState._line,
                width: selected ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              color: selected
                  ? _OracaoScreenState._primary
                  : _OracaoScreenState._muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentHeader extends StatelessWidget {
  const _RecentHeader({required this.scale, required this.onSeeAll});

  final double scale;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          OracaoMockData.recentTitle,
          style: GoogleFonts.montserrat(
            fontSize: 20 * scale,
            fontWeight: FontWeight.w600,
            height: 28 / 20,
            color: _OracaoScreenState._title,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: _OracaoScreenState._primary,
            padding: EdgeInsets.zero,
            minimumSize: Size(68 * scale, 28 * scale),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            OracaoMockData.seeAll,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrayerRequestCard extends StatelessWidget {
  const _PrayerRequestCard({
    required this.scale,
    required this.request,
    required this.prayerCount,
    required this.onPray,
  });

  final double scale;
  final OracaoRequestData request;
  final int prayerCount;
  final VoidCallback onPray;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _OracaoScreenState._line),
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
          Row(
            children: [
              Container(
                width: 32 * scale,
                height: 32 * scale,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _OracaoScreenState._avatar,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  request.author.characters.first.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                    color: _OracaoScreenState._primary,
                  ),
                ),
              ),
              SizedBox(width: 8 * scale),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.author,
                    style: GoogleFonts.inter(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                      color: _OracaoScreenState._title,
                    ),
                  ),
                  Text(
                    request.time,
                    style: GoogleFonts.inter(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                      color: _OracaoScreenState._muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          Text(
            '${request.text}...',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w400,
              height: 24 / 16,
              color: _OracaoScreenState._title,
            ),
          ),
          SizedBox(height: 12 * scale),
          Container(
            height: 1,
            color: _OracaoScreenState._line.withValues(alpha: 0.5),
          ),
          SizedBox(height: 9 * scale),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onPray,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 32 * scale,
                padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F3F2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuthAssetImage(
                      OracaoAssets.prayerHands,
                      width: 20 * scale,
                      height: 20 * scale,
                    ),
                    SizedBox(width: 6 * scale),
                    Text(
                      '$prayerCount',
                      style: GoogleFonts.inter(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w600,
                        height: 20 / 16,
                        color: _OracaoScreenState._darkPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
