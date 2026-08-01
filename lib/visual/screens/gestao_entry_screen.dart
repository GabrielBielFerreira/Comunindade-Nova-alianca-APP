import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../features/admin/providers/aprovacoes_providers.dart';
import '../../features/oracao/providers/oracao_providers.dart';
import '../visual_router.dart';
import '../widgets/leader_bottom_navigation.dart';

class GestaoEntryScreen extends StatelessWidget {
  const GestaoEntryScreen({super.key});

  static const _designWidth = 394.0;
  static const _background = Color(0xFFFAFAFA);
  static const _primary = Color(0xFF7A0022);
  static const _primaryDark = Color(0xFF510014);
  static const _title = Color(0xFF1A1A1A);
  static const _body = Color(0xFF584142);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);

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
              final navHeight = 76 * scale + bottomPadding;

              return Stack(
                children: [
                  Column(
                    children: [
                      _GestaoTopBar(scale: scale, topPadding: topPadding),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            20 * scale,
                            24 * scale,
                            20 * scale,
                            navHeight + 20 * scale,
                          ),
                          child: _GestaoContent(scale: scale),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: LeaderBottomNavigation(
                      activeItem: LeaderNavItem.management,
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

class _GestaoTopBar extends StatelessWidget {
  const _GestaoTopBar({required this.scale, required this.topPadding});

  final double scale;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: topPadding + 64 * scale,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: GestaoEntryScreen._line)),
      ),
      child: Row(
        children: [
          SizedBox(width: 8 * scale),
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(
              Icons.arrow_back,
              color: GestaoEntryScreen._title,
              size: 24 * scale,
            ),
          ),
          Expanded(
            child: Text(
              'Gestão',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 20 * scale,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: GestaoEntryScreen._title,
              ),
            ),
          ),
          SizedBox(width: 56 * scale),
        ],
      ),
    );
  }
}

class _GestaoContent extends StatelessWidget {
  const _GestaoContent({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GESTÃO',
          style: GoogleFonts.montserrat(
            fontSize: 28 * scale,
            fontWeight: FontWeight.w800,
            height: 35 / 28,
            letterSpacing: -0.7 * scale,
            color: GestaoEntryScreen._title,
          ),
        ),
        SizedBox(height: 6 * scale),
        Text(
          'Acesse as ferramentas de organização da comunidade.',
          style: GoogleFonts.inter(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: GestaoEntryScreen._body,
          ),
        ),
        SizedBox(height: 22 * scale),
        _ManagementPanelCard(scale: scale),
        SizedBox(height: 22 * scale),
        _CadastrosPendentesCard(scale: scale),
        SizedBox(height: 22 * scale),
        _AcaoGestaoCard(
          scale: scale,
          icone: Icons.reviews_outlined,
          titulo: 'Pedidos de oração a aprovar',
          countProvider: pedidosModeracaoCountProvider,
          rota: VisualRoutes.moderacaoOracao,
        ),
        SizedBox(height: 22 * scale),
        _ExclusiveNotice(scale: scale),
      ],
    );
  }
}

class _ManagementPanelCard extends StatelessWidget {
  const _ManagementPanelCard({required this.scale});

  final double scale;

  void _mostrarErro(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _abrirPainel(BuildContext context) async {
    final url = AppConfig.gestaoPanelUrl.trim();
    final uri = Uri.tryParse(url);

    if (url.isEmpty ||
        uri == null ||
        !uri.hasScheme ||
        !(uri.isScheme('http') || uri.isScheme('https'))) {
      _mostrarErro(
        context,
        'Painel de gestão ainda não configurado. Fale com a administração.',
      );
      return;
    }

    try {
      final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abriu && context.mounted) {
        _mostrarErro(context, 'Não foi possível abrir o painel de gestão.');
      }
    } catch (_) {
      if (context.mounted) {
        _mostrarErro(context, 'Painel indisponível no momento. Tente novamente.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: GestaoEntryScreen._line),
        borderRadius: BorderRadius.circular(18 * scale),
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
            width: 52 * scale,
            height: 52 * scale,
            decoration: const BoxDecoration(
              color: GestaoEntryScreen._soft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: GestaoEntryScreen._primary,
              size: 28 * scale,
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            'Painel de Gestão',
            style: GoogleFonts.montserrat(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: GestaoEntryScreen._title,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            'Acesse o painel administrativo externo para organizar escalas, ministérios, membros e pedidos de oração.',
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: GestaoEntryScreen._muted,
            ),
          ),
          SizedBox(height: 20 * scale),
          GestureDetector(
            onTap: () => _abrirPainel(context),
            child: Container(
              height: 56 * scale,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GestaoEntryScreen._primary,
                borderRadius: BorderRadius.circular(12 * scale),
                boxShadow: [
                  BoxShadow(
                    color: GestaoEntryScreen._primary.withValues(alpha: 0.18),
                    offset: Offset(0, 8 * scale),
                    blurRadius: 14 * scale,
                    spreadRadius: -5 * scale,
                  ),
                ],
              ),
              child: Text(
                'Abrir painel de gestão',
                style: GoogleFonts.inter(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w700,
                  height: 20 / 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CadastrosPendentesCard extends ConsumerWidget {
  const _CadastrosPendentesCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cadastrosPendentesCountProvider);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(18 * scale),
        onTap: () =>
            Navigator.pushNamed(context, VisualRoutes.cadastrosPendentes),
        child: Container(
          padding: EdgeInsets.all(18 * scale),
          decoration: BoxDecoration(
            border: Border.all(color: GestaoEntryScreen._line),
            borderRadius: BorderRadius.circular(18 * scale),
          ),
          child: Row(
            children: [
              Container(
                width: 48 * scale,
                height: 48 * scale,
                decoration: const BoxDecoration(
                  color: GestaoEntryScreen._soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.how_to_reg_outlined,
                    color: GestaoEntryScreen._primary, size: 26 * scale),
              ),
              SizedBox(width: 14 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cadastros pendentes',
                        style: GoogleFonts.montserrat(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w700,
                            color: GestaoEntryScreen._title)),
                    SizedBox(height: 2 * scale),
                    Text(
                      count == 0
                          ? 'Nenhum aguardando'
                          : '$count aguardando aprovação',
                      style: GoogleFonts.inter(
                          fontSize: 13 * scale,
                          color: GestaoEntryScreen._muted),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10 * scale, vertical: 4 * scale),
                  decoration: BoxDecoration(
                    color: GestaoEntryScreen._primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('$count',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13 * scale)),
                ),
              SizedBox(width: 8 * scale),
              Icon(Icons.chevron_right,
                  color: GestaoEntryScreen._muted, size: 22 * scale),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcaoGestaoCard extends ConsumerWidget {
  const _AcaoGestaoCard({
    required this.scale,
    required this.icone,
    required this.titulo,
    required this.countProvider,
    required this.rota,
  });

  final double scale;
  final IconData icone;
  final String titulo;
  final ProviderListenable<int> countProvider;
  final String rota;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(countProvider);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(18 * scale),
        onTap: () => Navigator.pushNamed(context, rota),
        child: Container(
          padding: EdgeInsets.all(18 * scale),
          decoration: BoxDecoration(
            border: Border.all(color: GestaoEntryScreen._line),
            borderRadius: BorderRadius.circular(18 * scale),
          ),
          child: Row(
            children: [
              Container(
                width: 48 * scale,
                height: 48 * scale,
                decoration: const BoxDecoration(
                    color: GestaoEntryScreen._soft, shape: BoxShape.circle),
                child: Icon(icone,
                    color: GestaoEntryScreen._primary, size: 26 * scale),
              ),
              SizedBox(width: 14 * scale),
              Expanded(
                child: Text(titulo,
                    style: GoogleFonts.montserrat(
                        fontSize: 15 * scale,
                        fontWeight: FontWeight.w700,
                        color: GestaoEntryScreen._title)),
              ),
              if (count > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10 * scale, vertical: 4 * scale),
                  decoration: BoxDecoration(
                      color: GestaoEntryScreen._primary,
                      borderRadius: BorderRadius.circular(999)),
                  child: Text('$count',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13 * scale)),
                ),
              SizedBox(width: 8 * scale),
              Icon(Icons.chevron_right,
                  color: GestaoEntryScreen._muted, size: 22 * scale),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExclusiveNotice extends StatelessWidget {
  const _ExclusiveNotice({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: GestaoEntryScreen._soft,
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            color: GestaoEntryScreen._primary,
            size: 22 * scale,
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Text(
              'Área exclusiva para líderes, pastores e diáconos.',
              style: GoogleFonts.inter(
                fontSize: 13.5 * scale,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: GestaoEntryScreen._primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

