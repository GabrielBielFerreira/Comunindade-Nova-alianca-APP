import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../features/avisos/data/aviso_model.dart';
import '../../features/avisos/providers/avisos_providers.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/notificacoes/providers/notificacoes_providers.dart';
import '../mock/avisos_mock_data.dart';
import '../mock_data.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/aviso_card.dart';
import '../widgets/avisos_bottom_navigation.dart';
import '../widgets/leader_bottom_navigation.dart';
import '../widgets/mais_menu.dart';
import 'aviso_detalhes_screen.dart';

/// Converte o aviso do Firestore no formato usado pelo card visual.
AvisoData _avisoParaCard(AvisoModel m) {
  final filtro = m.segmento == SegmentoAviso.ministerio
      ? AvisoFilter.ministerios
      : AvisoFilter.comunidade;
  final categoria = switch (m.segmento) {
    SegmentoAviso.ministerio => 'Ministério',
    SegmentoAviso.lideres => 'Liderança',
    SegmentoAviso.jovens => 'Jovens',
    SegmentoAviso.todos => 'Igreja',
  };
  return AvisoData(
    filter: filtro,
    category: categoria,
    title: m.titulo,
    description: m.conteudo,
    publishedAt: 'Publicado ${Formatters.dataRelativa(m.publicadoEm)}',
    publishedMetadata: 'Publicado em ${Formatters.dataHora(m.publicadoEm)}',
    detailDescription: m.conteudo,
    detailDate: Formatters.data(m.publicadoEm),
    detailTime: Formatters.hora(m.publicadoEm),
    detailLocation: '',
    detailAddress: '',
  );
}

class AvisosScreen extends ConsumerStatefulWidget {
  const AvisosScreen({super.key, required this.isLeader});

  final bool isLeader;

  @override
  ConsumerState<AvisosScreen> createState() => _AvisosScreenState();
}

class _AvisosScreenState extends ConsumerState<AvisosScreen> {
  static const _designWidth = 390.0;
  static const _background = Color(0xFFFAFAFA);
  static const _title = Color(0xFF510014);
  static const _body = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);

  AvisoFilter _selectedFilter = AvisoFilter.todos;

  List<AvisoData> _filtrar(List<AvisoModel> avisos) {
    final cards = avisos.map(_avisoParaCard).toList();
    if (_selectedFilter == AvisoFilter.todos) return cards;
    return cards.where((c) => c.filter == _selectedFilter).toList();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Widget _buildNotices(double scale) {
    final async = ref.watch(avisosStreamProvider);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
      child: async.when(
        loading: () => Padding(
          padding: EdgeInsets.symmetric(vertical: 48 * scale),
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => _MensagemAvisos(
          scale: scale,
          texto:
              'Não foi possível carregar os avisos. Verifique sua conexão.',
        ),
        data: (avisos) {
          final cards = _filtrar(avisos);
          if (cards.isEmpty) {
            return _MensagemAvisos(
              scale: scale,
              texto: 'Nenhum aviso publicado ainda.',
            );
          }
          return Column(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                AvisoCard(
                  notice: cards[index],
                  scale: scale,
                  onDetails: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(
                        name: VisualRoutes.avisoDetalhes,
                      ),
                      builder: (_) => AvisoDetalhesScreen(
                        notice: cards[index],
                        isLeader: widget.isLeader,
                      ),
                    ),
                  ),
                  onScale: () => _showMessage(
                    'Escalas serão abertas pela área de Gestão',
                  ),
                ),
                if (index < cards.length - 1) SizedBox(height: 16 * scale),
              ],
            ],
          );
        },
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
                      _AvisosTopBar(
                        scale: scale,
                        topPadding: topPadding,
                        isLeader: widget.isLeader,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom: navigationHeight + 20 * scale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  16 * scale,
                                  18 * scale,
                                  16 * scale,
                                  0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AVISOS',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 24 * scale,
                                        fontWeight: FontWeight.w700,
                                        height: 31.2 / 24,
                                        color: _title,
                                      ),
                                    ),
                                    SizedBox(height: 4 * scale),
                                    Text(
                                      'Fique por dentro das novidades e\ndirecionamentos da comunidade.',
                                      style: GoogleFonts.inter(
                                        fontSize: 16 * scale,
                                        fontWeight: FontWeight.w400,
                                        height: 25.6 / 16,
                                        color: _body,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 18 * scale),
                              _FilterBar(
                                scale: scale,
                                selected: _selectedFilter,
                                onSelected: (filter) {
                                  setState(() => _selectedFilter = filter);
                                },
                              ),
                              SizedBox(height: 8 * scale),
                              _buildNotices(scale),
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
                            activeItem: LeaderNavItem.notices,
                            scale: scale,
                            bottomPadding: bottomPadding,
                          )
                        : MemberAvisosBottomNavigation(
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

class _AvisosTopBar extends ConsumerWidget {
  const _AvisosTopBar({
    required this.scale,
    required this.topPadding,
    required this.isLeader,
  });

  final double scale;
  final double topPadding;
  final bool isLeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final naoLidas = ref.watch(naoLidasCountProvider);
    final isLider = ref.watch(usuarioProvider)?.isLider ?? isLeader;
    return Container(
      height: 64 * scale + topPadding,
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _AvisosScreenState._line)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8 * scale, 0, 16 * scale, 1 * scale),
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
                  color: _AvisosScreenState._title,
                ),
              ),
            ),
            _HeaderIcon(
              asset: HomeAssets.notification,
              scale: scale,
              width: 16,
              height: 20,
              showDot: naoLidas > 0,
              onTap: () =>
                  Navigator.pushNamed(context, VisualRoutes.notificacoes),
            ),
            SizedBox(width: 8 * scale),
            _HeaderIcon(
              asset: HomeAssets.menu,
              scale: scale,
              width: 18,
              height: 12,
              onTap: () => showMaisMenu(context, isLider: isLider),
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.scale,
    required this.selected,
    required this.onSelected,
  });

  final double scale;
  final AvisoFilter selected;
  final ValueChanged<AvisoFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38 * scale,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: AvisosMockData.filters.length,
        separatorBuilder: (_, index) => SizedBox(width: 8 * scale),
        itemBuilder: (context, index) {
          final item = AvisosMockData.filters[index];
          final isSelected = item.filter == selected;

          return InkWell(
            onTap: () => onSelected(item.filter),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(horizontal: 17 * scale),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF510014) : Colors.white,
                border: isSelected
                    ? null
                    : Border.all(color: _AvisosScreenState._line),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w500,
                  height: 21 / 14,
                  color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MensagemAvisos extends StatelessWidget {
  const _MensagemAvisos({required this.scale, required this.texto});

  final double scale;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 24 * scale),
      padding: EdgeInsets.all(24 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _AvisosScreenState._line),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(
        children: [
          Icon(Icons.campaign_outlined,
              size: 40 * scale, color: _AvisosScreenState._body),
          SizedBox(height: 12 * scale),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15 * scale,
              color: _AvisosScreenState._body,
            ),
          ),
        ],
      ),
    );
  }
}
