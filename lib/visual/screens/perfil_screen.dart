import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/providers/auth_controller.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/notificacoes/providers/notificacoes_providers.dart';
import '../widgets/mais_menu.dart';
import '../mock_data.dart';
import '../profile_photo_notifier.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/leader_bottom_navigation.dart';
import '../escala_tela.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key, required this.isLeader});

  final bool isLeader;

  static const _designWidth = 394.0;
  static const _background = Color(0xFFFAFAFA);
  static const _primary = Color(0xFF7A0022);
  static const _topTitle = Color(0xFF510014);
  static const _title = Color(0xFF1C1B1B);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);
  static const _logoutBackground = Color(0xFFFEE2E2);
  static const _logoutText = Color(0xFFC0392B);

  static const _avatar = 'assets/images/figma/profile/profile_avatar.png';

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
                  .clamp(escalaMinima, 1.0)
                  .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;
              final navHeight = 72 * scale + bottomPadding;

              return Stack(
                children: [
                  Column(
                    children: [
                      _ProfileTopBar(scale: scale, topPadding: topPadding),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            18 * scale,
                            24 * scale,
                            18 * scale,
                            navHeight + 20 * scale,
                          ),
                          child: _ProfileContent(
                            scale: scale,
                            isLeader: isLeader,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: isLeader
                        ? LeaderBottomNavigation(
                            activeItem: LeaderNavItem.profile,
                            scale: scale,
                            bottomPadding: bottomPadding,
                          )
                        : _PerfilBottomNavigation(
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

class _ProfileTopBar extends ConsumerWidget {
  const _ProfileTopBar({required this.scale, required this.topPadding});

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
        border: Border(bottom: BorderSide(color: PerfilScreen._line)),
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
                  color: PerfilScreen._topTitle,
                ),
              ),
            ),
            SizedBox(width: 5 * scale),
            _ProfileTopIcon(
              scale: scale,
              asset: HomeAssets.notification,
              width: 16,
              height: 20,
              showDot: naoLidas > 0,
              onTap: () =>
                  Navigator.pushNamed(context, VisualRoutes.notificacoes),
            ),
            SizedBox(width: 8 * scale),
            _ProfileTopIcon(
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

class _ProfileTopIcon extends StatelessWidget {
  const _ProfileTopIcon({
    required this.scale,
    required this.asset,
    required this.width,
    required this.height,
    this.showDot = false,
    this.onTap,
  });

  final double scale;
  final String asset;
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

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.scale, required this.isLeader});

  final double scale;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHero(scale: scale),
        SizedBox(height: 24 * scale),
        _ProfileOptionsCard(scale: scale, isLeader: isLeader),
        SizedBox(height: 24 * scale),
        _LogoutButton(scale: scale),
      ],
    );
  }
}

class _ProfileHero extends ConsumerWidget {
  const _ProfileHero({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioProvider);
    final nome = (usuario != null && usuario.nome.trim().isNotEmpty)
        ? usuario.nome
        : 'Membro';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24 * scale),
      child: Column(
        children: [
          ValueListenableBuilder<File?>(
            valueListenable: profilePhotoNotifier,
            builder: (context, photo, _) {
              return Container(
                width: 96 * scale,
                height: 96 * scale,
                padding: EdgeInsets.all(2 * scale),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F3F2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: PerfilScreen._soft,
                    width: 2 * scale,
                  ),
                ),
                child: ClipOval(
                  child: photo != null
                      ? Image.file(photo, fit: BoxFit.cover)
                      : Image.asset(
                          PerfilScreen._avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                ),
              );
            },
          ),
          SizedBox(height: 24 * scale),
          Text(
            nome,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 24 * scale,
              fontWeight: FontWeight.w700,
              height: 32 / 24,
              color: PerfilScreen._title,
            ),
          ),
          SizedBox(height: 32 * scale),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 320 * scale),
            child: SizedBox(
              width: double.infinity,
              height: 48 * scale,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: PerfilScreen._topTitle,
                  side: const BorderSide(color: PerfilScreen._topTitle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                ),
                onPressed: () =>
                    Navigator.pushNamed(context, VisualRoutes.dadosPessoais),
                child: Text(
                  'EDITAR PERFIL',
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                    letterSpacing: 0.7,
                    color: PerfilScreen._topTitle,
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

class _ProfileOptionsCard extends StatelessWidget {
  const _ProfileOptionsCard({required this.scale, required this.isLeader});

  final double scale;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    final rows = <_ProfileOptionData>[
      const _ProfileOptionData(
        label: 'Dados cadastrais',
        icon: Icons.badge_outlined,
        route: VisualRoutes.dadosPessoais,
      ),
      _ProfileOptionData(
        label: 'Hist\u00F3rico de contribui\u00E7\u00F5es',
        icon: Icons.volunteer_activism_outlined,
        route: isLeader
            ? VisualRoutes.historicoContribuicoesLeader
            : VisualRoutes.historicoContribuicoes,
      ),
      const _ProfileOptionData(
        label: 'Notifica\u00E7\u00F5es',
        icon: Icons.notifications_none_rounded,
        route: VisualRoutes.notificacoes,
      ),
      const _ProfileOptionData(
        label: 'Configura\u00E7\u00F5es',
        icon: Icons.settings_outlined,
        route: VisualRoutes.configuracoes,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: PerfilScreen._line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12 * scale),
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++)
              _ProfileOptionRow(
                data: rows[index],
                scale: scale,
                showDivider: index < rows.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOptionRow extends StatelessWidget {
  const _ProfileOptionRow({
    required this.data,
    required this.scale,
    required this.showDivider,
  });

  final _ProfileOptionData data;
  final double scale;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, data.route),
      child: Container(
        height: 57.5 * scale,
        padding: EdgeInsets.symmetric(horizontal: 16 * scale),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: PerfilScreen._line))
              : null,
        ),
        child: Row(
          children: [
            Icon(data.icon, size: 22 * scale, color: PerfilScreen._topTitle),
            SizedBox(width: 16 * scale),
            Expanded(
              child: Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w400,
                  height: 24 / 16,
                  color: PerfilScreen._title,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 24 * scale,
              color: PerfilScreen._muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton({required this.scale});

  final double scale;

  Future<void> _confirmarESair(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente encerrar sua sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await ref.read(authActionsProvider).sair();
    // Reconstrói o RootGate como raiz (limpando a pilha). Como as abas usam
    // pushNamedAndRemoveUntil, sem isto o "voltar" revelaria a Home de membro
    // em vez da tela de boas-vindas. O RootGate reage à sessão encerrada.
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        VisualRoutes.entraconta,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: PerfilScreen._logoutBackground,
      borderRadius: BorderRadius.circular(12 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(12 * scale),
        onTap: () => _confirmarESair(context, ref),
        child: Container(
          height: 52 * scale,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                size: 20 * scale,
                color: PerfilScreen._logoutText,
              ),
              SizedBox(width: 12 * scale),
              Text(
                'SAIR DA CONTA',
                style: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                  letterSpacing: 1.4,
                  color: PerfilScreen._logoutText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerfilBottomNavigation extends StatelessWidget {
  const _PerfilBottomNavigation({
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
        border: Border(top: BorderSide(color: PerfilScreen._line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, -1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          for (final item in HomeMockData.bottomNavigation)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    height: 56 * scale,
                    child: _PerfilNavigationItem(
                      item: item,
                      scale: scale,
                      maxWidth: constraints.maxWidth,
                      selected: item.asset == HomeAssets.profile,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PerfilNavigationItem extends StatelessWidget {
  const _PerfilNavigationItem({
    required this.item,
    required this.scale,
    required this.maxWidth,
    required this.selected,
  });

  final HomeBottomNavigationData item;
  final double scale;
  final double maxWidth;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? PerfilScreen._primary : PerfilScreen._muted;
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
        SizedBox(
          width: maxWidth - 4 * scale,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
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
          ),
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (selected) {
          return;
        }

        if (item.asset == HomeAssets.home) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            VisualRoutes.entraconta,
            (route) => false,
          );
          return;
        }

        if (item.asset == HomeAssets.notification) {
          Navigator.pushNamed(context, VisualRoutes.avisos);
          return;
        }

        if (item.asset == HomeAssets.schedule) {
          Navigator.pushNamed(context, VisualRoutes.programacao);
          return;
        }

        if (item.asset == HomeAssets.prayer) {
          Navigator.pushNamed(context, VisualRoutes.oracao);
          return;
        }

        if (item.asset == HomeAssets.contribute) {
          Navigator.pushNamed(context, VisualRoutes.contribuir);
        }
      },
      child: Center(
        child: selected
            ? Container(
                width: maxWidth,
                height: 39 * scale,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PerfilScreen._soft,
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

class _ProfileOptionData {
  const _ProfileOptionData({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}
