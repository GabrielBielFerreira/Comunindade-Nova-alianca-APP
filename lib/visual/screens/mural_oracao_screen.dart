import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/oracao/data/pedido_oracao_model.dart';
import '../../features/oracao/providers/oracao_providers.dart';
import '../mock/oracao_mock_data.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/leader_bottom_navigation.dart';
import '../widgets/oracao_bottom_navigation.dart';
import 'oracao_novo_pedido_screen.dart';

/// Converte um pedido do Firestore no formato usado pelos cards visuais.
OracaoRequestData _paraCard(PedidoOracaoModel p) => OracaoRequestData(
      author: p.nomeExibicao,
      time: Formatters.dataRelativa(p.criadoEm),
      text: p.texto,
      prayerCount: p.oramCount,
      label: p.urgente ? OracaoMockData.muralHighlightLabel : null,
    );

class MuralOracaoScreen extends StatefulWidget {
  const MuralOracaoScreen({super.key, required this.isLeader});

  final bool isLeader;

  @override
  State<MuralOracaoScreen> createState() => _MuralOracaoScreenState();
}

class _MuralOracaoScreenState extends State<MuralOracaoScreen> {
  static const _designWidth = 390.0;
  static const _background = Color(0xFFFAFAFA);
  static const _primary = Color(0xFF7A0022);
  static const _darkPrimary = Color(0xFF510014);
  static const _title = Color(0xFF1C1B1B);
  static const _body = Color(0xFF584142);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF6F3F2);
  static const _avatar = Color(0xFFEACDD6);

  int _selectedTab = 0;

  void _openNewRequest() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OracaoNovoPedidoScreen(isLeader: widget.isLeader),
      ),
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
                      _MuralTopBar(scale: scale, topPadding: topPadding),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            16 * scale,
                            16 * scale,
                            navigationHeight + 48 * scale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  OracaoMockData.muralSubtitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 16 * scale,
                                    fontWeight: FontWeight.w400,
                                    height: 24 / 16,
                                    color: _body,
                                  ),
                                ),
                              ),
                              SizedBox(height: 36 * scale),
                              _MuralTabs(
                                scale: scale,
                                selectedTab: _selectedTab,
                                onSelected: (index) {
                                  setState(() => _selectedTab = index);
                                },
                              ),
                              SizedBox(height: 32 * scale),
                              if (_selectedTab == 0)
                                _CommunityMural(scale: scale)
                              else
                                _MyMural(
                                  scale: scale,
                                  onNewRequest: _openNewRequest,
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
                            activeItem: LeaderNavItem.prayer,
                            scale: scale,
                            bottomPadding: bottomPadding,
                          )
                        : OracaoBottomNavigation(
                            scale: scale,
                            bottomPadding: bottomPadding,
                          ),
                  ),
                  Positioned(
                    right: 16 * scale,
                    bottom: navigationHeight + 24 * scale,
                    child: _MuralFab(scale: scale, onTap: _openNewRequest),
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

class _MuralTopBar extends StatelessWidget {
  const _MuralTopBar({required this.scale, required this.topPadding});

  final double scale;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * scale + topPadding,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: Color(0xFFFCF9F8),
        border: Border(
          bottom: BorderSide(color: _MuralOracaoScreenState._line),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56 * scale,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.arrow_back,
                size: 25 * scale,
                color: _MuralOracaoScreenState._darkPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              OracaoMockData.muralTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 24 * scale,
                fontWeight: FontWeight.w700,
                height: 32 / 24,
                color: _MuralOracaoScreenState._darkPrimary,
              ),
            ),
          ),
          SizedBox(width: 56 * scale),
        ],
      ),
    );
  }
}

class _MuralTabs extends StatelessWidget {
  const _MuralTabs({
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
        border: Border(
          bottom: BorderSide(color: _MuralOracaoScreenState._line),
        ),
      ),
      child: Row(
        children: [
          _MuralTabButton(
            label: OracaoMockData.communityTab,
            scale: scale,
            selected: selectedTab == 0,
            onTap: () => onSelected(0),
          ),
          _MuralTabButton(
            label: OracaoMockData.myMuralTab,
            scale: scale,
            selected: selectedTab == 1,
            onTap: () => onSelected(1),
          ),
        ],
      ),
    );
  }
}

class _MuralTabButton extends StatelessWidget {
  const _MuralTabButton({
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
          height: 36 * scale,
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? _MuralOracaoScreenState._darkPrimary
                    : _MuralOracaoScreenState._line,
                width: selected ? 2 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w600,
              height: 20 / 14,
              color: selected
                  ? _MuralOracaoScreenState._darkPrimary
                  : _MuralOracaoScreenState._body,
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityMural extends ConsumerWidget {
  const _CommunityMural({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(muralPedidosProvider);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;

    return async.when(
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: 48 * scale),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _MuralMensagem(
        scale: scale,
        texto: 'Não foi possível carregar o mural. Verifique sua conexão.',
      ),
      data: (pedidos) {
        if (pedidos.isEmpty) {
          return _MuralMensagem(
            scale: scale,
            texto: 'Ainda não há pedidos no mural da comunidade.',
          );
        }
        final destaque =
            pedidos.firstWhere((p) => p.urgente, orElse: () => pedidos.first);
        final recentes = pedidos.where((p) => p.id != destaque.id).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MuralRequestCard(
              scale: scale,
              request: _paraCard(destaque),
              prayerCount: destaque.oramCount,
              onPray: () => _orar(ref, destaque, uid),
            ),
            SizedBox(height: 32 * scale),
            if (recentes.isNotEmpty) ...[
              Text(
                OracaoMockData.muralRecentTitle,
                style: GoogleFonts.inter(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w400,
                  height: 24 / 16,
                  color: _MuralOracaoScreenState._title,
                ),
              ),
              SizedBox(height: 24 * scale),
              for (var i = 0; i < recentes.length; i++) ...[
                _MuralRequestCard(
                  scale: scale,
                  request: _paraCard(recentes[i]),
                  prayerCount: recentes[i].oramCount,
                  onPray: () => _orar(ref, recentes[i], uid),
                ),
                if (i < recentes.length - 1) SizedBox(height: 20 * scale),
              ],
            ],
          ],
        );
      },
    );
  }
}

void _orar(WidgetRef ref, PedidoOracaoModel pedido, String? uid) {
  if (uid == null) return;
  // As Rules exigem incremento de exatamente 1 sobre o valor atual, por isso
  // o contador do documento vai junto.
  ref.read(oracaoRepositoryProvider).estouOrando(
        pedidoId: pedido.id,
        uid: uid,
        oramCountAtual: pedido.oramCount,
        jaOrou: pedido.orouUsuario(uid),
      );
}

class _MyMural extends ConsumerWidget {
  const _MyMural({required this.scale, required this.onNewRequest});

  final double scale;
  final VoidCallback onNewRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(meusPedidosProvider);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;

    return async.when(
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: 48 * scale),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _MuralMensagem(
        scale: scale,
        texto: 'Não foi possível carregar seus pedidos.',
      ),
      data: (pedidos) {
        if (pedidos.isEmpty) {
          return _EmptyMyRequestsCard(scale: scale, onNewRequest: onNewRequest);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < pedidos.length; i++) ...[
              _MuralRequestCard(
                scale: scale,
                request: _paraCard(pedidos[i]),
                prayerCount: pedidos[i].oramCount,
                onPray: () => _orar(ref, pedidos[i], uid),
              ),
              if (i < pedidos.length - 1) SizedBox(height: 20 * scale),
            ],
          ],
        );
      },
    );
  }
}

class _MuralMensagem extends StatelessWidget {
  const _MuralMensagem({required this.scale, required this.texto});
  final double scale;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _MuralOracaoScreenState._line),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 15 * scale,
          color: _MuralOracaoScreenState._muted,
        ),
      ),
    );
  }
}

class _EmptyMyRequestsCard extends StatelessWidget {
  const _EmptyMyRequestsCard({required this.scale, required this.onNewRequest});

  final double scale;
  final VoidCallback onNewRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _MuralOracaoScreenState._line),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(
        children: [
          Text(
            'Você ainda não compartilhou pedidos.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w600,
              color: _MuralOracaoScreenState._title,
            ),
          ),
          SizedBox(height: 14 * scale),
          SizedBox(
            height: 48 * scale,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNewRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: _MuralOracaoScreenState._primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
              ),
              child: Text(
                'Novo pedido',
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
  }
}

class _MuralRequestCard extends StatelessWidget {
  const _MuralRequestCard({
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
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        22 * scale,
        16 * scale,
        12 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _MuralOracaoScreenState._line),
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
              _MuralAvatar(author: request.author, scale: scale),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Text(
                  request.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w600,
                    height: 22 / 15,
                    color: _MuralOracaoScreenState._title,
                  ),
                ),
              ),
              Text(
                request.time,
                style: GoogleFonts.inter(
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w400,
                  height: 18 / 13,
                  color: _MuralOracaoScreenState._muted,
                ),
              ),
            ],
          ),
          if (request.label != null) ...[
            SizedBox(height: 12 * scale),
            Text(
              request.label!,
              style: GoogleFonts.montserrat(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w700,
                height: 16 / 12,
                letterSpacing: 2.16 * scale,
                color: const Color(0xFFB02D21),
              ),
            ),
          ],
          SizedBox(height: 12 * scale),
          Text(
            request.text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w400,
              height: request.label == null ? 24 / 16 : 20 / 16,
              color: request.label == null
                  ? _MuralOracaoScreenState._title
                  : _MuralOracaoScreenState._body,
            ),
          ),
          SizedBox(height: 14 * scale),
          Container(
            height: 1,
            color: _MuralOracaoScreenState._line.withValues(alpha: 0.65),
          ),
          SizedBox(height: 10 * scale),
          Align(
            alignment: Alignment.centerRight,
            child: _PrayerCountPill(
              scale: scale,
              count: prayerCount,
              onTap: onPray,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuralAvatar extends StatelessWidget {
  const _MuralAvatar({required this.author, required this.scale});

  final String author;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32 * scale,
      height: 32 * scale,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: _MuralOracaoScreenState._avatar,
        shape: BoxShape.circle,
      ),
      child: Text(
        author.characters.first.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 14 * scale,
          fontWeight: FontWeight.w700,
          height: 20 / 14,
          color: _MuralOracaoScreenState._primary,
        ),
      ),
    );
  }
}

class _PrayerCountPill extends StatelessWidget {
  const _PrayerCountPill({
    required this.scale,
    required this.count,
    required this.onTap,
  });

  final double scale;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 32 * scale,
        padding: EdgeInsets.symmetric(horizontal: 12 * scale),
        decoration: BoxDecoration(
          color: _MuralOracaoScreenState._soft,
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
              '$count',
              style: GoogleFonts.inter(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w600,
                height: 20 / 16,
                color: _MuralOracaoScreenState._darkPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MuralFab extends StatelessWidget {
  const _MuralFab({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _MuralOracaoScreenState._primary,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 56 * scale,
          height: 56 * scale,
          child: Icon(Icons.add, color: Colors.white, size: 32 * scale),
        ),
      ),
    );
  }
}
