import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/igreja_info.dart';
import '../../core/utils/formatters.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/eventos/providers/eventos_providers.dart';
import '../../features/notificacoes/providers/notificacoes_providers.dart';
import '../../features/palavra_dia/palavra_do_dia.dart';
import '../mock_data.dart';
import '../visual_router.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/mais_menu.dart';
import '../widgets/motion.dart';
import '../widgets/auth_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    this.greeting = HomeMockData.greeting,
    this.greetingSubtitle = HomeMockData.greetingSubtitle,
    this.secondaryCardLabel = HomeMockData.schedulesLabel,
    this.showSecondaryCard = true,
    this.showBottomNavigation = true,
    this.muralRoute = VisualRoutes.muralOracao,
  });

  final String greeting;
  final String greetingSubtitle;
  final String secondaryCardLabel;
  final bool showSecondaryCard;
  final bool showBottomNavigation;
  final String muralRoute;

  static const _designWidth = 394.0;
  static const _background = Color(0xFFFAFAFA);
  static const _topTitle = Color(0xFF510014);
  static const _hero = Color(0xFF510014);
  static const _title = Color(0xFF1A1A1A);
  static const _body = Color(0xFF584142);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _iconBackground = Color(0xFFE8E8E8);
  static const _success = Color(0xFF16A34A);
  static const _danger = Color(0xFFB02D21);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Saudação com o nome real do usuário autenticado (usuarios/{uid}).
    final usuario = ref.watch(usuarioProvider);
    final saudacao =
        (usuario != null && usuario.primeiroNome.trim().isNotEmpty)
            ? 'OLÁ, ${usuario.primeiroNome.toUpperCase()}!'
            : greeting;

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
              final navHeight = 72 * scale + bottomPadding;

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
                            22 * scale,
                            16 * scale,
                            navHeight + 20 * scale,
                          ),
                          child: _HomeContent(
                            greeting: saudacao,
                            greetingSubtitle: greetingSubtitle,
                            secondaryCardLabel: secondaryCardLabel,
                            showSecondaryCard: showSecondaryCard,
                            muralRoute: muralRoute,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showBottomNavigation)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: AppBottomNavigation(
                        items: _memberNavItems(),
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

  List<AppNavItem> _memberNavItems() {
    return [
      for (final item in HomeMockData.bottomNavigation)
        AppNavItem(
          label: item.label,
          asset: item.asset,
          iconWidth: item.iconWidth,
          iconHeight: item.iconHeight,
          selected: item.selected,
          fontSize: item.fontSize,
          onTap: _memberOnTapFor(item),
        ),
    ];
  }

  void Function(BuildContext context)? _memberOnTapFor(
    HomeBottomNavigationData item,
  ) {
    if (item.label == 'Avisos') {
      return (context) => Navigator.pushNamed(context, VisualRoutes.avisos);
    }
    if (item.asset == HomeAssets.schedule) {
      return (context) =>
          Navigator.pushNamed(context, VisualRoutes.programacao);
    }
    if (item.asset == HomeAssets.prayer) {
      return (context) => Navigator.pushNamed(context, VisualRoutes.oracao);
    }
    if (item.asset == HomeAssets.contribute) {
      return (context) => Navigator.pushNamed(context, VisualRoutes.contribuir);
    }
    if (item.asset == HomeAssets.profile) {
      return (context) => Navigator.pushNamed(context, VisualRoutes.perfil);
    }
    return null;
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.scale, required this.topPadding});

  final double scale;
  final double topPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final naoLidas = ref.watch(naoLidasCountProvider);
    final isLider = ref.watch(usuarioProvider)?.isLider ?? false;
    return Container(
      height: 64 * scale + topPadding,
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: HomeScreen._line)),
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
                ' ${HomeMockData.communityName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 16.5 * scale,
                  fontWeight: FontWeight.w700,
                  height: 31.2 / 16.5,
                  color: HomeScreen._topTitle,
                ),
              ),
            ),
            SizedBox(width: 5 * scale),
            _TopIconButton(
              scale: scale,
              asset: HomeAssets.notification,
              width: 16,
              height: 20,
              badgeCount: naoLidas,
              onTap: () =>
                  Navigator.pushNamed(context, VisualRoutes.notificacoes),
            ),
            SizedBox(width: 8 * scale),
            _TopIconButton(
              scale: scale,
              asset: HomeAssets.menu,
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

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.scale,
    required this.asset,
    required this.width,
    required this.height,
    this.badgeCount = 0,
    this.onTap,
  });

  final double scale;
  final String asset;
  final double width;
  final double height;
  final int badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: 32 * scale,
      height: 36 * scale,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AuthAssetImage(asset, width: width * scale, height: height * scale),
          if (badgeCount > 0)
            Positioned(
              top: 2 * scale,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4 * scale),
                constraints: BoxConstraints(minWidth: 15 * scale),
                height: 15 * scale,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.2 * scale),
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 9 * scale,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) {
      return button;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: button,
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({
    required this.greeting,
    required this.greetingSubtitle,
    required this.secondaryCardLabel,
    required this.showSecondaryCard,
    required this.muralRoute,
  });

  final String greeting;
  final String greetingSubtitle;
  final String secondaryCardLabel;
  final bool showSecondaryCard;
  final String muralRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = (MediaQuery.sizeOf(context).width / HomeScreen._designWidth)
        .clamp(0.86, 1.0)
        .toDouble();

    // Próximo culto: primeiro evento futuro do Firestore (sem horário fixo).
    final eventos = ref.watch(eventosStreamProvider).valueOrNull ?? [];
    final proximo = eventos.isNotEmpty ? eventos.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeSlideIn(
          child: _Greeting(
            scale: scale,
            greeting: greeting,
            subtitle: greetingSubtitle,
          ),
        ),
        SizedBox(height: 20 * scale),
        FadeSlideIn(
          delay: const Duration(milliseconds: 70),
          child: _WordCard(scale: scale),
        ),
        SizedBox(height: 20 * scale),
        FadeSlideIn(
          delay: const Duration(milliseconds: 140),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pushNamed(context, VisualRoutes.programacao),
            child: _InfoCard(
              scale: scale,
              iconAsset: HomeAssets.calendar,
              iconWidth: 18,
              iconHeight: 20,
              label: HomeMockData.nextServiceLabel,
              title: proximo?.titulo ?? 'Nenhum culto agendado',
              status: proximo != null
                  ? '${Formatters.data(proximo.data)} • ${proximo.horario}'
                  : 'Confira a programação',
              statusAsset: HomeAssets.check,
              statusColor: HomeScreen._success,
            ),
          ),
        ),
        if (showSecondaryCard) ...[
          SizedBox(height: 16 * scale),
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: _InfoCard(
              scale: scale,
              iconAsset: HomeAssets.scaleBell,
              iconWidth: 16,
              iconHeight: 20,
              label: secondaryCardLabel,
              title: HomeMockData.schedulesTitle,
              status: HomeMockData.schedulesStatus,
              statusAsset: HomeAssets.alert,
              statusColor: HomeScreen._danger,
            ),
          ),
        ],
        SizedBox(height: 24 * scale),
        FadeSlideIn(
          delay: const Duration(milliseconds: 260),
          child: _VidaNaComunidadeSection(scale: scale, muralRoute: muralRoute),
        ),
        SizedBox(height: 24 * scale),
        FadeSlideIn(
          delay: const Duration(milliseconds: 320),
          child: _PalavraELouvorSection(scale: scale),
        ),
      ],
    );
  }
}

/// Seção "PALAVRA E LOUVOR" com atalhos grandes para Bíblia e Cantor Cristão,
/// acessíveis a visitantes, membros e liderança.
/// Atalho de seção da Home.
class _Atalho {
  const _Atalho(this.icone, this.titulo, this.subtitulo, this.onTap);
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
}

/// Grade de atalhos (2 colunas) com título de seção.
class _SecaoAtalhos extends StatelessWidget {
  const _SecaoAtalhos({
    required this.titulo,
    required this.scale,
    required this.itens,
  });

  final String titulo;
  final double scale;
  final List<_Atalho> itens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: GoogleFonts.montserrat(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 12 * scale),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 12 * scale) / 2;
            return Wrap(
              spacing: 12 * scale,
              runSpacing: 12 * scale,
              children: [
                for (final it in itens)
                  SizedBox(
                    width: itemWidth,
                    child: _PalavraLouvorCard(
                      scale: scale,
                      icone: it.icone,
                      titulo: it.titulo,
                      subtitulo: it.subtitulo,
                      onTap: it.onTap,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Seção "Palavra e Louvor": Bíblia, Cantor Cristão, Devocionais e Escola de
/// Louvor (esta só aparece quando habilitada por feature flag).
class _PalavraELouvorSection extends StatelessWidget {
  const _PalavraELouvorSection({required this.scale});

  final double scale;

  static const _primary = Color(0xFF7A0022);
  static const _soft = Color(0xFFF5E6EC);
  static const _title = Color(0xFF1A1A1A);
  static const _border = Color(0xFFE5E7EB);
  static const _cardColors = (_primary, _soft, _title, _border);

  @override
  Widget build(BuildContext context) {
    return _SecaoAtalhos(
      titulo: 'PALAVRA E LOUVOR',
      scale: scale,
      itens: [
        _Atalho(Icons.menu_book_rounded, 'Bíblia', 'Leia e favorite',
            () => Navigator.pushNamed(context, VisualRoutes.biblia)),
        _Atalho(Icons.library_music_rounded, 'Cantor Cristão',
            'Hinos por número',
            () => Navigator.pushNamed(context, VisualRoutes.cantorCristao)),
        _Atalho(Icons.auto_stories_rounded, 'Devocionais', 'Palavra diária',
            () => Navigator.pushNamed(context, VisualRoutes.devocionais)),
        if (AppConfig.escolaDeLouvorHabilitada)
          _Atalho(Icons.school_rounded, 'Escola de Louvor', 'Formação musical',
              () => Navigator.pushNamed(context, VisualRoutes.escolaLouvor)),
      ],
    );
  }
}

/// Seção "Vida na Comunidade": Meu Ministério, Mural de Oração, Ao Vivo,
/// Instagram.
class _VidaNaComunidadeSection extends StatelessWidget {
  const _VidaNaComunidadeSection({required this.scale, required this.muralRoute});

  final double scale;
  final String muralRoute;

  Future<void> _abrir(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return _SecaoAtalhos(
      titulo: 'VIDA NA COMUNIDADE',
      scale: scale,
      itens: [
        _Atalho(Icons.groups_rounded, 'Meu Ministério', 'Sirva na igreja',
            () => Navigator.pushNamed(context, VisualRoutes.meuMinisterio)),
        _Atalho(Icons.favorite_rounded, 'Mural de Oração', 'Ore em comunidade',
            () => Navigator.pushNamed(context, muralRoute)),
        _Atalho(Icons.live_tv_rounded, 'Ao Vivo', 'Acompanhe o culto',
            () => _abrir(IgrejaInfo.instagramUrl)),
        _Atalho(Icons.camera_alt_rounded, 'Instagram', IgrejaInfo.instagram,
            () => _abrir(IgrejaInfo.instagramUrl)),
      ],
    );
  }
}

class _PalavraLouvorCard extends StatelessWidget {
  const _PalavraLouvorCard({
    required this.scale,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final double scale;
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (primary, soft, title, border) =
        _PalavraELouvorSection._cardColors;
    return Semantics(
      button: true,
      label: titulo,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        child: InkWell(
          borderRadius: BorderRadius.circular(16 * scale),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(16 * scale),
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(16 * scale),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48 * scale,
                  height: 48 * scale,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  child: Icon(icone, color: primary, size: 26 * scale),
                ),
                SizedBox(height: 12 * scale),
                Text(
                  titulo,
                  style: GoogleFonts.montserrat(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w700,
                    color: title,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  subtitulo,
                  style: GoogleFonts.inter(
                    fontSize: 12 * scale,
                    color: const Color(0xFF6B7280),
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

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.scale,
    required this.greeting,
    required this.subtitle,
  });

  final double scale;
  final String greeting;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: GoogleFonts.montserrat(
            fontSize: 28 * scale,
            fontWeight: FontWeight.w700,
            height: 35 / 28,
            letterSpacing: -0.7 * scale,
            color: HomeScreen._title,
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w400,
            height: 24 / 16,
            color: HomeScreen._body,
          ),
        ),
      ],
    );
  }
}

class _WordCard extends ConsumerWidget {
  const _WordCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palavra = ref.watch(palavraDoDiaProvider).valueOrNull;
    final verso = palavra != null ? '"${palavra.texto}"' : HomeMockData.verse;
    final referencia = palavra?.referencia ?? HomeMockData.verseReference;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24 * scale),
      decoration: BoxDecoration(
        color: HomeScreen._hero,
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
              horizontal: 12 * scale,
              vertical: 4 * scale,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthAssetImage(
                  HomeAssets.word,
                  width: 14.7 * scale,
                  height: 10.7 * scale,
                ),
                SizedBox(width: 8 * scale),
                Text(
                  HomeMockData.wordLabel,
                  style: GoogleFonts.montserrat(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w700,
                    height: 16.8 / 12,
                    letterSpacing: 0.6 * scale,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            verso,
            style: GoogleFonts.montserrat(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w500,
              height: 25 / 20,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            referencia,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w400,
              height: 21 / 14,
              color: Colors.white.withValues(alpha: 0.80),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.scale,
    required this.iconAsset,
    required this.iconWidth,
    required this.iconHeight,
    required this.label,
    required this.title,
    required this.status,
    required this.statusAsset,
    required this.statusColor,
  });

  final double scale;
  final String iconAsset;
  final double iconWidth;
  final double iconHeight;
  final String label;
  final String title;
  final String status;
  final String statusAsset;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105.8 * scale,
      width: double.infinity,
      padding: EdgeInsets.all(17 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: HomeScreen._line.withValues(alpha: 0.50)),
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: Offset(0, 1 * scale),
            blurRadius: 1 * scale,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48 * scale,
            height: 48 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HomeScreen._iconBackground,
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: AuthAssetImage(
              iconAsset,
              width: iconWidth * scale,
              height: iconHeight * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w400,
                    height: 16.8 / 12,
                    letterSpacing: 0.6 * scale,
                    color: HomeScreen._muted,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w600,
                    height: 28 / 20,
                    color: HomeScreen._title,
                  ),
                ),
                SizedBox(height: 1 * scale),
                Row(
                  children: [
                    AuthAssetImage(
                      statusAsset,
                      width: 13 * scale,
                      height: 12 * scale,
                    ),
                    SizedBox(width: 4 * scale),
                    Flexible(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14 * scale,
                          fontWeight: FontWeight.w400,
                          height: 21 / 14,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12 * scale),
          AuthAssetImage(
            HomeAssets.arrow,
            width: 16 * scale,
            height: 16 * scale,
          ),
        ],
      ),
    );
  }
}
