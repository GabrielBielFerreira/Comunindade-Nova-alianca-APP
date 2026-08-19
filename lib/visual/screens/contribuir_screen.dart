import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/igrejas/providers/igreja_providers.dart';
import '../../core/config/app_config.dart';
import '../../features/campanhas/providers/campanhas_providers.dart';
import '../../features/notificacoes/providers/notificacoes_providers.dart';
import '../mock/contribuicao_mock_data.dart';
import '../mock_data.dart';
import '../visual_router.dart';
import 'campanha_detalhes_screen.dart';
import 'revisar_contribuicao_screen.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/leader_bottom_navigation.dart';
import '../widgets/mais_menu.dart';
import '../widgets/motion.dart';
import '../widgets/visitor_bottom_navigation.dart';
import '../escala_tela.dart';

class ContribuirScreen extends ConsumerStatefulWidget {
  const ContribuirScreen({
    super.key,
    required this.isLeader,
    this.isVisitor = false,
  });

  final bool isLeader;
  final bool isVisitor;

  @override
  ConsumerState<ContribuirScreen> createState() => _ContribuirScreenState();
}

class _ContribuirScreenState extends ConsumerState<ContribuirScreen> {
  static const _designWidth = 390.0;
  static const _background = Color(0xFFFAFAFA);
  static const _primary = Color(0xFF7A0022);
  static const _primaryDark = Color(0xFF510014);
  static const _title = Color(0xFF1C1B1B);
  static const _body = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);
  static const _accent = Color(0xFFC0392B);
  static const _green = Color(0xFF16A34A);

  late final TextEditingController _valueController;
  bool _formattingValue = false;
  String _selectedType = 'Dízimo';
  ContribuicaoCampaignData? _selectedCampaign;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: 'R\$ 0,00');
    _valueController.addListener(_formatCurrencyValue);
  }

  @override
  void dispose() {
    _valueController
      ..removeListener(_formatCurrencyValue)
      ..dispose();
    super.dispose();
  }

  void _formatCurrencyValue() {
    if (_formattingValue) {
      return;
    }

    final digits = _valueController.text.replaceAll(RegExp(r'\D'), '');
    final cents = int.tryParse(digits) ?? 0;
    final formatted = _formatCents(cents);
    if (_valueController.text == formatted) {
      return;
    }

    _formattingValue = true;
    _valueController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _formattingValue = false;
  }

  String _formatCents(int cents) {
    final reais = cents ~/ 100;
    final centavos = cents % 100;
    final reaisText = reais.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'R\$ $reaisText,${centavos.toString().padLeft(2, '0')}';
  }

  int get _valueInCents {
    final digits = _valueController.text.replaceAll(RegExp(r'\D'), '');
    return int.tryParse(digits) ?? 0;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _continueContribution() {
    if (_valueInCents <= 0) {
      _showMessage('Informe um valor para continuar');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EscolherMetodoPagamentoScreen(
          isLeader: widget.isLeader,
          contributionType: _selectedType,
          valueLabel: _valueController.text,
          campaign: _selectedCampaign,
        ),
      ),
    );
  }

  Future<void> _openCampaign(ContribuicaoCampaignData campaign) async {
    final escolhida = await Navigator.of(context)
        .push<ContribuicaoCampaignData>(
          MaterialPageRoute<ContribuicaoCampaignData>(
            builder: (_) => CampanhaDetalhesScreen(campaign: campaign),
          ),
        );
    if (escolhida != null && mounted) {
      setState(() => _selectedCampaign = escolhida);
      _showMessage('Contribuindo para a campanha: ${escolhida.title}');
    }
  }

  void _showTransparencia() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Transparência'),
        content: const Text(
          'A prestação de contas da comunidade é apresentada periodicamente '
          'nos cultos e nas reuniões de membros. Para detalhes, fale com a '
          'tesouraria ou a liderança.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // `isVisitor` é apenas apresentação; a autorização vem do vínculo atual.
    // Isso fecha rotas antigas/deep links que abrem `/contribuir` sem marcar o
    // chamador como visitante.
    final membroAprovado = widget.isVisitor
        ? false
        : ref.watch(isMembroAprovadoAtualProvider);
    if (!membroAprovado) {
      return const _ContribuicaoVisitanteBloqueada();
    }

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
          // Tamanho de tela (estável com o teclado aberto) evita reconstruir a
          // árvore a cada quadro da animação do teclado.
          child: Builder(
            builder: (context) {
              final scale = (MediaQuery.sizeOf(context).width / _designWidth)
                  .clamp(escalaMinima, 1.0)
                  .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;
              final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
              final keyboardOpen = keyboardInset > 0;
              final navHeight = keyboardOpen ? 0.0 : 72 * scale + bottomPadding;

              return Stack(
                children: [
                  Column(
                    children: [
                      _ContribuirTopBar(scale: scale, topPadding: topPadding),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom: keyboardOpen
                                ? keyboardInset + 24 * scale
                                : navHeight + 24 * scale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HeroAndContributionCard(
                                scale: scale,
                                selectedType: _selectedType,
                                valueController: _valueController,
                                onTypeChanged: (type) {
                                  setState(() => _selectedType = type);
                                },
                                onContinue: _continueContribution,
                              ),
                              if (_selectedCampaign != null) ...[
                                SizedBox(height: 12 * scale),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16 * scale,
                                  ),
                                  child: _SelectedCampaignBanner(
                                    scale: scale,
                                    title: _selectedCampaign!.title,
                                    onClear: () => setState(
                                      () => _selectedCampaign = null,
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(height: 18 * scale),
                              _CampaignsSection(
                                scale: scale,
                                onSupport: _openCampaign,
                              ),
                              SizedBox(height: 16 * scale),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16 * scale,
                                ),
                                child: _TransparencyCard(
                                  scale: scale,
                                  onTap: _showTransparencia,
                                ),
                              ),
                              SizedBox(height: 16 * scale),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16 * scale,
                                ),
                                child: _ContributionHistoryCard(
                                  scale: scale,
                                  isLeader: widget.isLeader,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!keyboardOpen)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: widget.isLeader
                          ? LeaderBottomNavigation(
                              activeItem: LeaderNavItem.contribute,
                              scale: scale,
                              bottomPadding: bottomPadding,
                            )
                          : widget.isVisitor
                          ? VisitorBottomNavigation(
                              activeItem: VisitorNavItem.contribute,
                              scale: scale,
                              bottomPadding: bottomPadding,
                            )
                          : _ContribuirBottomNavigation(
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

class _ContribuicaoVisitanteBloqueada extends StatelessWidget {
  const _ContribuicaoVisitanteBloqueada();

  @override
  Widget build(BuildContext context) {
    final scale =
        (MediaQuery.sizeOf(context).width / _ContribuirScreenState._designWidth)
            .clamp(escalaMinima, 1.0)
            .toDouble();
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const Key('contribuicao_visitante_bloqueada'),
        backgroundColor: _ContribuirScreenState._background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 64 * scale,
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: _ContribuirScreenState._line),
                  ),
                ),
                child: Text(
                  'Contribuir',
                  style: GoogleFonts.montserrat(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w700,
                    color: _ContribuirScreenState._primaryDark,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 28 * scale,
                      vertical: 32 * scale,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72 * scale,
                          height: 72 * scale,
                          decoration: const BoxDecoration(
                            color: _ContribuirScreenState._soft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 34 * scale,
                            color: _ContribuirScreenState._primary,
                          ),
                        ),
                        SizedBox(height: 24 * scale),
                        Text(
                          'Contribuição protegida',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 22 * scale,
                            fontWeight: FontWeight.w700,
                            color: _ContribuirScreenState._title,
                          ),
                        ),
                        SizedBox(height: 12 * scale),
                        Text(
                          'Contribuições pelo aplicativo estão disponíveis '
                          'após entrar e ter o vínculo com a igreja aprovado.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15 * scale,
                            height: 1.5,
                            color: _ContribuirScreenState._body,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        Text(
                          'Por segurança, os dados de pagamento não ficam no '
                          'catálogo público.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14 * scale,
                            height: 1.45,
                            color: _ContribuirScreenState._body,
                          ),
                        ),
                        SizedBox(height: 24 * scale),
                        SizedBox(
                          width: double.infinity,
                          height: 50 * scale,
                          child: FilledButton(
                            key: const Key('entrar_para_contribuir'),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              VisualRoutes.entraconta,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _ContribuirScreenState._primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12 * scale),
                              ),
                            ),
                            child: Text(
                              'Entrar para contribuir',
                              style: GoogleFonts.inter(
                                fontSize: 15 * scale,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: VisitorBottomNavigation(
          activeItem: VisitorNavItem.contribute,
          scale: scale,
          bottomPadding: bottomPadding,
        ),
      ),
    );
  }
}

class EscolherMetodoPagamentoScreen extends StatefulWidget {
  const EscolherMetodoPagamentoScreen({
    super.key,
    required this.isLeader,
    this.contributionType = 'Dízimo',
    this.valueLabel = 'R\$ 0,00',
    this.campaign,
  });

  final bool isLeader;
  final String contributionType;
  final String valueLabel;
  final ContribuicaoCampaignData? campaign;

  @override
  State<EscolherMetodoPagamentoScreen> createState() =>
      _EscolherMetodoPagamentoScreenState();
}

class _EscolherMetodoPagamentoScreenState
    extends State<EscolherMetodoPagamentoScreen> {
  String _selectedMethod = 'Pix';

  void _finishContribution() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RevisarContribuicaoScreen(
          isLeader: widget.isLeader,
          contributionType: widget.contributionType,
          valueLabel: widget.valueLabel,
          paymentMethod: _selectedMethod,
          campaign: widget.campaign,
        ),
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
        backgroundColor: _ContribuirScreenState._background,
        body: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale =
                  (constraints.maxWidth / _ContribuirScreenState._designWidth)
                      .clamp(escalaMinima, 1.0)
                      .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;
              final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
              final keyboardOpen = keyboardInset > 0;
              final navHeight = keyboardOpen ? 0.0 : 72 * scale + bottomPadding;

              return Stack(
                children: [
                  Column(
                    children: [
                      _ContribuirTopBar(scale: scale, topPadding: topPadding),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom: keyboardOpen
                                ? keyboardInset + 24 * scale
                                : navHeight + 24 * scale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HeroAndPaymentMethodCard(
                                scale: scale,
                                selectedMethod: _selectedMethod,
                                onMethodChanged: (method) {
                                  setState(() => _selectedMethod = method);
                                },
                                onContribute: _finishContribution,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!keyboardOpen)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: widget.isLeader
                          ? LeaderBottomNavigation(
                              activeItem: LeaderNavItem.contribute,
                              scale: scale,
                              bottomPadding: bottomPadding,
                            )
                          : _ContribuirBottomNavigation(
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

class _HeroAndPaymentMethodCard extends StatelessWidget {
  const _HeroAndPaymentMethodCard({
    required this.scale,
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.onContribute,
  });

  final double scale;
  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;
  final VoidCallback onContribute;

  @override
  Widget build(BuildContext context) {
    final heroHeight = 248 * scale;
    final overlap = 24 * scale;
    final cardHeight = 432 * scale;

    return SizedBox(
      height: heroHeight + cardHeight - overlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _ContribuirHero(scale: scale, height: heroHeight),
          Positioned(
            left: 16 * scale,
            right: 16 * scale,
            top: heroHeight - overlap,
            child: _PaymentMethodCard(
              scale: scale,
              selectedMethod: selectedMethod,
              onMethodChanged: onMethodChanged,
              onContribute: onContribute,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.scale,
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.onContribute,
  });

  final double scale;
  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;
  final VoidCallback onContribute;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 432 * scale,
      padding: EdgeInsets.all(25 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _ContribuirScreenState._line.withValues(alpha: 0.50),
        ),
        borderRadius: BorderRadius.circular(24 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: Offset(0, 4 * scale),
            blurRadius: 10 * scale,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dízimos e Ofertas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.w900,
                        height: 30 / 24,
                        color: _ContribuirScreenState._primaryDark,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      'Sua fidelidade sustenta a casa de\nDeus.',
                      style: GoogleFonts.inter(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                        color: _ContribuirScreenState._body,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48 * scale,
                height: 48 * scale,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _ContribuirScreenState._soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  size: 22 * scale,
                  color: _ContribuirScreenState._primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 24 * scale),
          if (AppConfig.pagamentosOnlineHabilitado) ...[
            Row(
              children: [
                Expanded(
                  child: _PaymentMethodOption(
                    scale: scale,
                    label: 'Pix',
                    icon: Icons.qr_code_2_rounded,
                    selected: selectedMethod == 'Pix',
                    onTap: () => onMethodChanged('Pix'),
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: _PaymentMethodOption(
                    scale: scale,
                    label: 'Cartão',
                    icon: Icons.credit_card_rounded,
                    selected: selectedMethod == 'Cartão',
                    onTap: () => onMethodChanged('Cartão'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * scale),
            _PaymentMethodOption(
              scale: scale,
              label: 'Boleto',
              icon: Icons.receipt_long_rounded,
              selected: selectedMethod == 'Boleto',
              onTap: () => onMethodChanged('Boleto'),
            ),
          ] else ...[
            // Sem backend de pagamentos online, apenas o PIX manual está
            // disponível (cartão/boleto ficam ocultos até serem habilitados).
            _PaymentMethodOption(
              scale: scale,
              label: 'Pix',
              icon: Icons.qr_code_2_rounded,
              selected: true,
              onTap: () => onMethodChanged('Pix'),
            ),
            SizedBox(height: 12 * scale),
            Text(
              'No momento, as contribuições são feitas por PIX.',
              style: GoogleFonts.inter(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
                color: _ContribuirScreenState._body,
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52 * scale,
            child: ElevatedButton.icon(
              onPressed: onContribute,
              icon: Icon(
                Icons.volunteer_activism_outlined,
                size: 18 * scale,
                color: Colors.white,
              ),
              label: const Text('Contribuir Agora'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _ContribuirScreenState._primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  const _PaymentMethodOption({
    required this.scale,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12 * scale),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 86 * scale,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? _ContribuirScreenState._soft.withValues(alpha: 0.72)
                : _ContribuirScreenState._background,
            border: Border.all(
              color: selected
                  ? _ContribuirScreenState._primary
                  : _ContribuirScreenState._line,
            ),
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20 * scale,
                color: _ContribuirScreenState._primaryDark,
              ),
              SizedBox(height: 8 * scale),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                  color: _ContribuirScreenState._title,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContribuirTopBar extends ConsumerWidget {
  const _ContribuirTopBar({required this.scale, required this.topPadding});

  final double scale;
  final double topPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final naoLidas = ref.watch(naoLidasCountProvider);
    // Liderança na UNIDADE EM FOCO. O perfil global valia para qualquer
    // igreja e mostrava o menu de liderança ao visualizar outra unidade.
    final isLider = ref.watch(isLiderancaNaUnidadeProvider);
    return Container(
      height: 64 * scale + topPadding,
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _ContribuirScreenState._line)),
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
                ' ${ref.watch(nomeIgrejaEmFocoProvider)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 16.5 * scale,
                  fontWeight: FontWeight.w700,
                  height: 31.2 / 16.5,
                  color: _ContribuirScreenState._primaryDark,
                ),
              ),
            ),
            SizedBox(width: 5 * scale),
            _HeaderIcon(
              scale: scale,
              asset: HomeAssets.notification,
              width: 16,
              height: 20,
              showDot: naoLidas > 0,
              onTap: () =>
                  Navigator.pushNamed(context, VisualRoutes.notificacoes),
            ),
            SizedBox(width: 8 * scale),
            _HeaderIcon(
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

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
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

class _HeroAndContributionCard extends StatelessWidget {
  const _HeroAndContributionCard({
    required this.scale,
    required this.selectedType,
    required this.valueController,
    required this.onTypeChanged,
    required this.onContinue,
  });

  final double scale;
  final String selectedType;
  final TextEditingController valueController;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final heroHeight = 248 * scale;
    final overlap = 24 * scale;
    final cardHeight = 478 * scale;

    return SizedBox(
      height: heroHeight + cardHeight - overlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _ContribuirHero(scale: scale, height: heroHeight),
          Positioned(
            left: 16 * scale,
            right: 16 * scale,
            top: heroHeight - overlap,
            child: _ContributionCard(
              scale: scale,
              selectedType: selectedType,
              valueController: valueController,
              onTypeChanged: onTypeChanged,
              onContinue: onContinue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContribuirHero extends StatelessWidget {
  const _ContribuirHero({required this.scale, required this.height});

  final double scale;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16 * scale, 32 * scale, 16 * scale, 0),
      decoration: BoxDecoration(
        color: _ContribuirScreenState._primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40 * scale),
          bottomRight: Radius.circular(40 * scale),
        ),
        gradient: const RadialGradient(
          center: Alignment.topRight,
          radius: 1.2,
          colors: [Color(0xFF9B1335), Color(0xFF7A0022)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: Offset(0, 1 * scale),
            blurRadius: 2 * scale,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48 * scale,
            height: 48 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              size: 25 * scale,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            'Contribuir',
            style: GoogleFonts.montserrat(
              fontSize: 36 * scale,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -0.72 * scale,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12 * scale),
          Text(
            ContribuicaoMockData.verse,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w400,
              height: 24 / 16,
              color: Colors.white.withValues(alpha: 0.90),
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            ContribuicaoMockData.verseReference,
            style: GoogleFonts.inter(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w400,
              height: 16 / 12,
              color: Colors.white.withValues(alpha: 0.70),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({
    required this.scale,
    required this.selectedType,
    required this.valueController,
    required this.onTypeChanged,
    required this.onContinue,
  });

  final double scale;
  final String selectedType;
  final TextEditingController valueController;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 478 * scale,
      padding: EdgeInsets.all(25 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _ContribuirScreenState._line.withValues(alpha: 0.50),
        ),
        borderRadius: BorderRadius.circular(24 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: Offset(0, 4 * scale),
            blurRadius: 10 * scale,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dízimos e Ofertas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 24 * scale,
                        fontWeight: FontWeight.w900,
                        height: 30 / 24,
                        color: _ContribuirScreenState._primaryDark,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      'Sua fidelidade sustenta a casa de\nDeus.',
                      style: GoogleFonts.inter(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                        color: _ContribuirScreenState._body,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48 * scale,
                height: 48 * scale,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _ContribuirScreenState._soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  size: 22 * scale,
                  color: _ContribuirScreenState._primaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 24 * scale),
          Center(
            child: Text(
              'Tipo da contribuição',
              style: GoogleFonts.inter(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
                color: _ContribuirScreenState._title,
              ),
            ),
          ),
          SizedBox(height: 12 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TypePill(
                scale: scale,
                label: 'Dízimo',
                selected: selectedType == 'Dízimo',
                onTap: () => onTypeChanged('Dízimo'),
              ),
              SizedBox(width: 39 * scale),
              _TypePill(
                scale: scale,
                label: 'Oferta',
                selected: selectedType == 'Oferta',
                onTap: () => onTypeChanged('Oferta'),
              ),
            ],
          ),
          SizedBox(height: 32 * scale),
          Center(
            child: Text(
              'Valor',
              style: GoogleFonts.inter(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
                color: _ContribuirScreenState._title,
              ),
            ),
          ),
          SizedBox(height: 24 * scale),
          Container(
            height: 65 * scale,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _ContribuirScreenState._line),
              borderRadius: BorderRadius.circular(8 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: Offset(0, 1 * scale),
                  blurRadius: 2 * scale,
                ),
              ],
            ),
            child: TextFormField(
              controller: valueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              cursorColor: _ContribuirScreenState._primary,
              style: GoogleFonts.inter(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w400,
                height: 24 / 16,
                color: Colors.black,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          SizedBox(height: 28 * scale),
          SizedBox(
            width: double.infinity,
            height: 54 * scale,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ContribuirScreenState._primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10 * scale),
                ),
              ),
              child: Text(
                'continuar',
                style: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              ContribuicaoMockData.safeEnvironment,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
                color: _ContribuirScreenState._body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.scale,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 38 * scale,
          padding: EdgeInsets.symmetric(horizontal: 22 * scale),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _ContribuirScreenState._primary : Colors.white,
            border: Border.all(
              color: selected
                  ? _ContribuirScreenState._primary
                  : _ContribuirScreenState._line,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              color: selected ? Colors.white : _ContribuirScreenState._title,
            ),
          ),
        ),
      ),
    );
  }
}

class _CampaignsSection extends ConsumerWidget {
  const _CampaignsSection({required this.scale, required this.onSupport});

  final double scale;
  final ValueChanged<ContribuicaoCampaignData> onSupport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campanhas =
        ref.watch(campanhasAtivasProvider).valueOrNull ?? const [];
    // Sem campanhas publicadas, a seção simplesmente não aparece (honesto).
    if (campanhas.isEmpty) return const SizedBox.shrink();

    final cards = campanhas.map(ContribuicaoCampaignData.fromCampanha).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campanhas',
            style: GoogleFonts.montserrat(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              height: 28 / 20,
              color: _ContribuirScreenState._title,
            ),
          ),
          SizedBox(height: 8 * scale),
          SizedBox(
            height: 282 * scale,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: cards.length,
              separatorBuilder: (_, index) => SizedBox(width: 14 * scale),
              itemBuilder: (context, index) {
                final campaign = cards[index];
                return _CampaignCard(
                  scale: scale,
                  campaign: campaign,
                  onSupport: () => onSupport(campaign),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Faixa que mostra a campanha selecionada acima do formulário, com opção de
/// remover a vinculação.
class _SelectedCampaignBanner extends StatelessWidget {
  const _SelectedCampaignBanner({
    required this.scale,
    required this.title,
    required this.onClear,
  });

  final double scale;
  final String title;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: _ContribuirScreenState._soft,
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: const Color(0x33EACDD6)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.volunteer_activism_rounded,
            size: 20 * scale,
            color: _ContribuirScreenState._primary,
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contribuindo para a campanha',
                  style: GoogleFonts.inter(
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w500,
                    color: _ContribuirScreenState._body,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w700,
                    color: _ContribuirScreenState._primaryDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              size: 18 * scale,
              color: _ContribuirScreenState._primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.scale,
    required this.campaign,
    required this.onSupport,
  });

  final double scale;
  final ContribuicaoCampaignData campaign;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final buttonColor = campaign.urgent
        ? _ContribuirScreenState._accent
        : _ContribuirScreenState._primaryDark;

    return Container(
      width: 280 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _ContribuirScreenState._line),
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: Offset(0, 1 * scale),
            blurRadius: 3 * scale,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 128 * scale,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CampaignImage(scale: scale, campaign: campaign),
                if (campaign.urgent)
                  Positioned(
                    top: 8 * scale,
                    right: 8 * scale,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8 * scale,
                        vertical: 4 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: _ContribuirScreenState._accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'URGENTE',
                        style: GoogleFonts.inter(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w700,
                          height: 16 / 12,
                          letterSpacing: 0.6 * scale,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                    color: _ContribuirScreenState._title,
                  ),
                ),
                SizedBox(height: 8 * scale),
                AnimatedProgressBar(
                  value: campaign.progress,
                  color: buttonColor,
                  minHeight: 8 * scale,
                ),
                SizedBox(height: 8 * scale),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      campaign.progressLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                        color: _ContribuirScreenState._body,
                      ),
                    ),
                    Text(
                      campaign.trailingLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                        color: _ContribuirScreenState._body,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16 * scale),
                SizedBox(
                  width: double.infinity,
                  height: 36 * scale,
                  child: ElevatedButton.icon(
                    onPressed: onSupport,
                    icon: Icon(
                      Icons.volunteer_activism_outlined,
                      size: 16 * scale,
                      color: Colors.white,
                    ),
                    label: Text(campaign.buttonLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10 * scale),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w500,
                        height: 20 / 14,
                      ),
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

/// Imagem do card de campanha: rede (campanhas reais), asset (mock) ou um
/// placeholder on-brand quando não houver imagem.
class _CampaignImage extends StatelessWidget {
  const _CampaignImage({required this.scale, required this.campaign});

  final double scale;
  final ContribuicaoCampaignData campaign;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: _ContribuirScreenState._soft,
      alignment: Alignment.center,
      child: Icon(
        Icons.volunteer_activism_rounded,
        size: 36 * scale,
        color: _ContribuirScreenState._primary,
      ),
    );

    final url = campaign.imageUrl;
    if (url != null && url.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      );
    }
    if (campaign.imageAsset.trim().isNotEmpty) {
      return Image.asset(
        campaign.imageAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return placeholder;
  }
}

class _TransparencyCard extends StatelessWidget {
  const _TransparencyCard({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12 * scale),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(17 * scale),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _ContribuirScreenState._line),
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Row(
            children: [
              Container(
                width: 48 * scale,
                height: 48 * scale,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.insert_chart_outlined_rounded,
                  size: 20 * scale,
                  color: _ContribuirScreenState._green,
                ),
              ),
              SizedBox(width: 16 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transparência',
                      style: GoogleFonts.inter(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        color: _ContribuirScreenState._title,
                      ),
                    ),
                    Text(
                      'Acompanhe a prestação de contas\nmensal da comunidade.',
                      style: GoogleFonts.inter(
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                        color: _ContribuirScreenState._body,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 24 * scale,
                color: _ContribuirScreenState._body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContributionHistoryCard extends StatelessWidget {
  const _ContributionHistoryCard({required this.scale, required this.isLeader});

  final double scale;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            isLeader
                ? VisualRoutes.historicoContribuicoesLeader
                : VisualRoutes.historicoContribuicoes,
          );
        },
        borderRadius: BorderRadius.circular(12 * scale),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 17 * scale,
            vertical: 16 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _ContribuirScreenState._line),
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 26 * scale,
                color: _ContribuirScreenState._body,
              ),
              SizedBox(width: 16 * scale),
              Expanded(
                child: Text(
                  'Meu Histórico de Contribuições',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                    color: _ContribuirScreenState._title,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 24 * scale,
                color: _ContribuirScreenState._body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContribuirBottomNavigation extends StatelessWidget {
  const _ContribuirBottomNavigation({
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
        border: Border(top: BorderSide(color: _ContribuirScreenState._line)),
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
                    child: _ContribuirNavigationItem(
                      item: item,
                      scale: scale,
                      maxWidth: constraints.maxWidth,
                      selected: item.asset == HomeAssets.contribute,
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

class _ContribuirNavigationItem extends StatelessWidget {
  const _ContribuirNavigationItem({
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
    final color = selected
        ? _ContribuirScreenState._primary
        : _ContribuirScreenState._body;
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

        if (item.label == 'Perfil' || item.asset == HomeAssets.profile) {
          Navigator.pushNamed(context, VisualRoutes.perfil);
          return;
        }

        if (item.label == 'Contribuir' || item.asset == HomeAssets.contribute) {
          Navigator.pushNamed(context, VisualRoutes.contribuir);
          return;
        }
      },
      child: Center(
        child: selected
            ? Container(
                width: maxWidth,
                height: 41 * scale,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _ContribuirScreenState._soft,
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
