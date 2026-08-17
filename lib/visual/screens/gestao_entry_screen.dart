import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/admin/providers/aprovacoes_providers.dart';
import '../../features/oracao/providers/oracao_providers.dart';
import '../visual_router.dart';
import '../widgets/leader_bottom_navigation.dart';
import '../escala_tela.dart';

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
                  .clamp(escalaMinima, 1.0)
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
        _SecaoTitulo(scale: scale, texto: 'Publicar conteúdo'),
        SizedBox(height: 12 * scale),
        _GestaoNavCard(
          scale: scale,
          icone: Icons.campaign_outlined,
          titulo: 'Gerenciar avisos',
          subtitulo: 'Publique e edite avisos para os membros',
          rota: VisualRoutes.gerenciarAvisos,
        ),
        SizedBox(height: 12 * scale),
        _GestaoNavCard(
          scale: scale,
          icone: Icons.event_outlined,
          titulo: 'Gerenciar programação',
          subtitulo: 'Crie e organize os eventos da agenda',
          rota: VisualRoutes.gerenciarEventos,
        ),
        SizedBox(height: 12 * scale),
        _GestaoNavCard(
          scale: scale,
          icone: Icons.menu_book_outlined,
          titulo: 'Gerenciar devocionais',
          subtitulo: 'Publique os devocionais da comunidade',
          rota: VisualRoutes.gerenciarDevocionais,
        ),
        SizedBox(height: 12 * scale),
        _GestaoNavCard(
          scale: scale,
          icone: Icons.volunteer_activism_outlined,
          titulo: 'Gerenciar campanhas',
          subtitulo: 'Crie campanhas de arrecadação',
          rota: VisualRoutes.gerenciarCampanhas,
        ),
        SizedBox(height: 12 * scale),
        _GestaoNavCard(
          scale: scale,
          icone: Icons.groups_outlined,
          titulo: 'Gerenciar ministérios',
          subtitulo: 'Organize os ministérios da igreja',
          rota: VisualRoutes.gerenciarMinisterios,
        ),
        SizedBox(height: 22 * scale),
        _SecaoTitulo(scale: scale, texto: 'Aprovações'),
        SizedBox(height: 12 * scale),
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

/// Título de seção da Gestão (agrupa "Publicar conteúdo", "Aprovações"...).
class _SecaoTitulo extends StatelessWidget {
  const _SecaoTitulo({required this.scale, required this.texto});

  final double scale;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: GoogleFonts.montserrat(
        fontSize: 15 * scale,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2 * scale,
        color: GestaoEntryScreen._body,
      ),
    );
  }
}

/// Card de navegação da Gestão para uma ferramenta interna (sem badge de
/// contagem). Usado para "Gerenciar avisos" e "Gerenciar programação".
class _GestaoNavCard extends StatelessWidget {
  const _GestaoNavCard({
    required this.scale,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.rota,
  });

  final double scale;
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final String rota;

  @override
  Widget build(BuildContext context) {
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
                  color: GestaoEntryScreen._soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icone,
                    color: GestaoEntryScreen._primary, size: 26 * scale),
              ),
              SizedBox(width: 14 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: GoogleFonts.montserrat(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w700,
                            color: GestaoEntryScreen._title)),
                    SizedBox(height: 2 * scale),
                    Text(subtitulo,
                        style: GoogleFonts.inter(
                            fontSize: 13 * scale,
                            height: 1.35,
                            color: GestaoEntryScreen._muted)),
                  ],
                ),
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

