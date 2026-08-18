import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/data/auth_error.dart';
import '../../features/auth/providers/auth_controller.dart';
import '../../features/igrejas/providers/escolha_igreja_provider.dart';
import '../../features/igrejas/providers/igreja_providers.dart';
import '../mock_data.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';

class CadastroScreen extends ConsumerStatefulWidget {
  const CadastroScreen({super.key});

  @override
  ConsumerState<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends ConsumerState<CadastroScreen> {
  bool _loading = false;

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _submitCadastro() async {
    FocusScope.of(context).unfocus();
    if (_loading) return;

    if (_nomeController.text.trim().isEmpty) {
      _showMessage('Informe seu nome completo');
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      _showMessage('Informe um e-mail válido');
      return;
    }

    if (_telefoneController.text.trim().isEmpty) {
      _showMessage('Informe seu telefone');
      return;
    }

    if (_senhaController.text.length < 6) {
      _showMessage('A senha deve ter pelo menos 6 caracteres');
      return;
    }

    // Sem unidade escolhida nao existe vinculo a criar, e o cadastro nao
    // apareceria em "Cadastros pendentes" de nenhuma igreja.
    final igrejaId = ref.read(igrejaEscolhidaCadastroProvider);
    if (igrejaId == null) {
      _showMessage('Escolha sua igreja para concluir o cadastro.');
      Navigator.of(context).pushNamed(VisualRoutes.selectChurch);
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authActionsProvider).cadastrar(
            nome: _nomeController.text.trim(),
            email: _emailController.text.trim().toLowerCase(),
            telefone: _telefoneController.text.trim(),
            senha: _senhaController.text,
            igrejaId: igrejaId,
          );
      // A escolha ja virou vinculo; nao deve vazar para um proximo cadastro.
      await ref.read(igrejaEscolhidaCadastroProvider.notifier).limpar();
      // Conta criada com status pendente. O RootGate mostrará a tela de
      // "Aguardando aprovação"; voltamos à raiz para revelá-la.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) _showMessage(mensagemErroAuth(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = authScaleFor(context, 390);
    final frameHeight = math.max(
      MediaQuery.sizeOf(context).height,
      988 * scale,
    );
    final cardTop = (312 - 28) * scale;

    return AuthCanvas(
      referenceWidth: 390,
      minHeight: frameHeight,
      backgroundColor: AuthColors.white,
      child: SizedBox(
        height: frameHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AuthHeroHeader(
                height: 312,
                title: CadastroMockData.headerTitle,
                subtitle: CadastroMockData.subtitle,
                scale: scale,
              ),
            ),
            Positioned(
              top: cardTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: _CadastroCard(
                scale: scale,
                nomeController: _nomeController,
                emailController: _emailController,
                telefoneController: _telefoneController,
                senhaController: _senhaController,
                obscurePassword: _obscurePassword,
                onTogglePassword: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSubmit: _submitCadastro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CadastroCard extends ConsumerWidget {
  const _CadastroCard({
    required this.scale,
    required this.nomeController,
    required this.emailController,
    required this.telefoneController,
    required this.senhaController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final double scale;
  final TextEditingController nomeController;
  final TextEditingController emailController;
  final TextEditingController telefoneController;
  final TextEditingController senhaController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24 * scale,
        30 * scale,
        24 * scale,
        32 * scale,
      ),
      decoration: BoxDecoration(
        color: AuthColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32 * scale),
          topRight: Radius.circular(32 * scale),
          bottomLeft: Radius.circular(12 * scale),
          bottomRight: Radius.circular(12 * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: Offset(0, 4 * scale),
            blurRadius: 2 * scale,
          ),
        ],
      ),
      child: Column(
        children: [
          _IgrejaEscolhida(scale: scale),
          AuthInputField(
            label: CadastroMockData.nomeLabel,
            hint: CadastroMockData.nomeHint,
            iconAsset: AuthAssets.cadastroUser,
            scale: scale,
            controller: nomeController,
            textInputAction: TextInputAction.next,
            iconWidth: 13.33,
            iconHeight: 13.33,
            labelColor: Colors.black,
          ),
          SizedBox(height: 24 * scale),
          AuthInputField(
            label: CadastroMockData.emailLabel,
            hint: CadastroMockData.emailHint,
            iconAsset: AuthAssets.cadastroEmail,
            scale: scale,
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            iconWidth: 16.67,
            iconHeight: 13.33,
            labelColor: Colors.black,
          ),
          SizedBox(height: 24 * scale),
          AuthInputField(
            label: CadastroMockData.telefoneLabel,
            hint: CadastroMockData.telefoneHint,
            iconAsset: AuthAssets.cadastroPhone,
            scale: scale,
            controller: telefoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            iconWidth: 12.5,
            iconHeight: 18.33,
            labelColor: Colors.black,
          ),
          SizedBox(height: 24 * scale),
          AuthInputField(
            label: CadastroMockData.senhaLabel,
            hint: CadastroMockData.senhaHint,
            iconAsset: AuthAssets.cadastroLock,
            trailingIconAsset: AuthAssets.cadastroEye,
            scale: scale,
            controller: senhaController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onTrailingTap: onTogglePassword,
            onFieldSubmitted: (_) => onSubmit(),
            iconWidth: 13.33,
            iconHeight: 17.5,
            trailingWidth: 18.33,
            trailingHeight: 12.5,
            rightPadding: 16,
            labelColor: Colors.black,
          ),
          SizedBox(height: 7 * scale),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 4 * scale),
              child: Text(
                CadastroMockData.senhaHelp,
                style: GoogleFonts.inter(
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: AuthColors.muted,
                ),
              ),
            ),
          ),
          SizedBox(height: 40 * scale),
          AuthPrimaryButton(
            text: CadastroMockData.submit,
            scale: scale,
            radius: 10,
            fontFamily: AuthButtonFont.montserrat,
            iconAsset: AuthAssets.cadastroArrow,
            shadow: true,
            onTap: onSubmit,
          ),
          SizedBox(height: 32 * scale),
          GestureDetector(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              VisualRoutes.login,
              (route) => false,
            ),
            child: Text.rich(
              TextSpan(
                text: '${CadastroMockData.loginPrefix} ',
                style: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: AuthColors.formLabel,
                ),
                children: [
                  TextSpan(
                    text: CadastroMockData.loginLink,
                    style: GoogleFonts.inter(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: AuthColors.primary,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 31 * scale),
          Text(
            CadastroMockData.termsLine1,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: AuthColors.muted,
            ),
          ),
          Text(
            CadastroMockData.termsLine2,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w400,
              height: 1.4,
              color: AuthColors.formLabel,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mostra em qual unidade o cadastro vai nascer.
///
/// A escolha da igreja define quem aprova a pessoa e a que dados ela terá
/// acesso — não pode ser uma decisão invisível tomada duas telas atrás.
class _IgrejaEscolhida extends ConsumerWidget {
  const _IgrejaEscolhida({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(igrejaEscolhidaCadastroProvider);
    final igrejas = ref.watch(igrejasAtivasProvider).valueOrNull;

    final nome = id == null
        ? null
        : igrejas
            ?.where((i) => i.id == id)
            .map((i) => i.nome)
            .cast<String?>()
            .firstWhere((_) => true, orElse: () => null);

    final semIgreja = id == null;

    return Padding(
      padding: EdgeInsets.only(bottom: 24 * scale),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          color: semIgreja ? const Color(0xFFFEF3C7) : AuthColors.soft,
          borderRadius: BorderRadius.circular(8 * scale),
        ),
        child: Row(
          children: [
            Icon(
              semIgreja ? Icons.warning_amber_rounded : Icons.church_outlined,
              size: 18 * scale,
              color: AuthColors.primary,
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    semIgreja ? 'Nenhuma igreja escolhida' : 'Sua igreja',
                    style: GoogleFonts.inter(
                      fontSize: 11 * scale,
                      color: AuthColors.muted,
                    ),
                  ),
                  Text(
                    // Sem o nome carregado ainda, mostra o id em vez de um
                    // nome inventado.
                    semIgreja
                        ? 'Toque para escolher antes de continuar'
                        : (nome ?? id.valor),
                    style: GoogleFonts.inter(
                      fontSize: 13.5 * scale,
                      fontWeight: FontWeight.w600,
                      color: AuthColors.title,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pushNamed(VisualRoutes.selectChurch),
              child: Text(semIgreja ? 'Escolher' : 'Trocar'),
            ),
          ],
        ),
      ),
    );
  }
}
