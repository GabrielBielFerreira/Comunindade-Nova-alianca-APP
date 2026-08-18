import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/auth_error.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/auth/providers/auth_controller.dart';
import '../../features/igrejas/providers/escolha_igreja_provider.dart';
import '../mock_data.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';
import '../escala_tela.dart';

class EntracontaScreen extends ConsumerStatefulWidget {
  const EntracontaScreen({super.key});

  static const _primary = Color(0xFF7A0022);
  static const _text = Color(0xFF040303);
  static const _muted = Color(0xFF6B7280);
  static const _placeholder = Color(0xFF9CA3AF);
  static const _inputFill = Color(0xFFF9FAFB);
  static const _border = Color(0xFFE5E7EB);
  static const _cardBorder = Color(0xFFF3F4F6);
  static const _headerSubtitle = Color(0xFFFFB2B7);

  @override
  ConsumerState<EntracontaScreen> createState() => _EntracontaScreenState();
}

class _EntracontaScreenState extends ConsumerState<EntracontaScreen> {
  static const _kUltimoEmail = 'ultimo_email_login';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _carregarUltimoEmail();
  }

  Future<void> _carregarUltimoEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kUltimoEmail);
    if (email != null && email.isNotEmpty && mounted) {
      // Só preenche se o usuário ainda não digitou nada.
      if (_emailController.text.isEmpty) {
        _emailController.text = email;
      }
    }
  }

  Future<void> _salvarUltimoEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUltimoEmail, email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _submitLogin() async {
    FocusScope.of(context).unfocus();
    if (_loading) return;

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showMessage('Informe seu e-mail');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Informe sua senha');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authActionsProvider).login(email: email, senha: password);
      // Guarda o e-mail (nunca a senha) para pré-preencher no próximo acesso.
      await _salvarUltimoEmail(email);
      // Sucesso: o RootGate reage à mudança de sessão e mostra a Home correta.
      // Como o login pode ter sido alcançado via push (Welcome → login),
      // voltamos à raiz para revelar a tela decidida pelo gate.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) _showMessage(mensagemErroAuth(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitGoogle() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      // No PRIMEIRO acesso o cadastro precisa de uma unidade; nos seguintes o
      // valor e ignorado pelo servico.
      final ok = await ref.read(authActionsProvider).entrarComGoogle(
            igrejaId: ref.read(igrejaEscolhidaCadastroProvider),
          );
      // Sucesso: o RootGate reage à sessão; voltamos à raiz. Cancelamento
      // (ok == false) não faz nada.
      if (ok && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on IgrejaObrigatoriaNoCadastro {
      // Primeiro acesso sem igreja: leva a pessoa para escolher em vez de
      // deixar a conta autenticada sem vinculo nenhum.
      if (mounted) {
        _showMessage('Escolha sua igreja para concluir o cadastro.');
        Navigator.of(context).pushNamed(VisualRoutes.selectChurch);
      }
    } catch (e) {
      if (mounted) _showMessage(mensagemErroAuth(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        // Usa o tamanho de tela (estável quando o teclado abre) em vez de
        // LayoutBuilder — assim a árvore NÃO é reconstruída a cada quadro da
        // animação do teclado (evita a lentidão). O SingleChildScrollView
        // continua permitindo rolar até o campo focado.
        child: Builder(
          builder: (context) {
            final screen = MediaQuery.sizeOf(context);
            final scale = (screen.width / 391).clamp(escalaMinima, 1.0);
            final headerHeight = 287.0 * scale;
            final figmaCardHeight = 534.0 * scale;
            final remainingHeight = screen.height - headerHeight;
            final cardHeight = remainingHeight > figmaCardHeight
                ? remainingHeight
                : figmaCardHeight;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screen.height),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: headerHeight + cardHeight,
                      child: Column(
                        children: [
                          _Header(
                            height: headerHeight,
                            scale: scale,
                          ),
                          _LoginCard(
                            scale: scale,
                            minHeight: cardHeight,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            obscurePassword: _obscurePassword,
                            loading: _loading,
                            onTogglePassword: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            onSubmit: _submitLogin,
                            onGoogle: _submitGoogle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.height,
    required this.scale,
  });

  final double height;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: EntracontaScreen._primary),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 48 * scale),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 96 * scale,
                    height: 96 * scale,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          offset: Offset(0, 2 * scale),
                          blurRadius: 2 * scale,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          offset: Offset(0, 4 * scale),
                          blurRadius: 3 * scale,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      EntracontaMockData.logoAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
                SizedBox(height: 23.9 * scale),
                Text(
                  EntracontaMockData.welcome,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 24 * scale,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.6 * scale,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  EntracontaMockData.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: EntracontaScreen._headerSubtitle,
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

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.scale,
    required this.minHeight,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.loading,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onGoogle,
  });

  final double scale;
  final double minHeight;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool loading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsets.fromLTRB(
        33 * scale,
        19 * scale,
        31 * scale,
        35 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: EntracontaScreen._cardBorder),
        borderRadius: BorderRadius.circular(24 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 28 * scale,
            child: Center(
              child: Text(
                EntracontaMockData.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.6 * scale,
                  color: EntracontaScreen._text,
                ),
              ),
            ),
          ),
          SizedBox(height: 14 * scale),
          _FormFieldBlock(
            label: EntracontaMockData.emailLabel,
            hint: EntracontaMockData.emailHint,
            iconAsset: EntracontaMockData.emailIconAsset,
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: 24 * scale),
          _FormFieldBlock(
            label: EntracontaMockData.passwordLabel,
            hint: EntracontaMockData.passwordHint,
            iconAsset: EntracontaMockData.lockIconAsset,
            trailingIconAsset: EntracontaMockData.eyeOffIconAsset,
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onTrailingTap: onTogglePassword,
            onFieldSubmitted: (_) => onSubmit(),
          ),
          SizedBox(height: 20 * scale),
          _SubmitButton(scale: scale, onTap: onSubmit, loading: loading),
          SizedBox(height: 14 * scale),
          Row(
            children: [
              const Expanded(child: Divider(color: EntracontaScreen._border)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                child: Text(
                  'ou',
                  style: GoogleFonts.inter(
                    fontSize: 13 * scale,
                    color: EntracontaScreen._muted,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: EntracontaScreen._border)),
            ],
          ),
          SizedBox(height: 14 * scale),
          _GoogleButton(scale: scale, onTap: loading ? null : onGoogle),
          SizedBox(height: 16 * scale),
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, VisualRoutes.recuperarSenha),
            child: Text(
              EntracontaMockData.forgotPassword,
              style: GoogleFonts.inter(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
                color: EntracontaScreen._primary,
              ),
            ),
          ),
          SizedBox(height: 15 * scale),
          Container(height: 1, color: EntracontaScreen._border),
          SizedBox(height: 7 * scale),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, VisualRoutes.cadastro),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    EntracontaMockData.noAccount,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w400,
                      height: 20 / 14,
                      color: EntracontaScreen._muted,
                    ),
                  ),
                ),
                SizedBox(width: 4 * scale),
                Text(
                  EntracontaMockData.createAccount,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                    color: EntracontaScreen._primary,
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

class _FormFieldBlock extends StatelessWidget {
  const _FormFieldBlock({
    required this.label,
    required this.hint,
    required this.iconAsset,
    required this.controller,
    this.trailingIconAsset,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onTrailingTap,
    this.onFieldSubmitted,
  });

  final String label;
  final String hint;
  final String iconAsset;
  final TextEditingController controller;
  final String? trailingIconAsset;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final VoidCallback? onTrailingTap;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = (width / 391).clamp(escalaMinima, 1.16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: label == EntracontaMockData.emailLabel
              ? 28 * scale
              : 20 * scale,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
                color: label == EntracontaMockData.emailLabel
                    ? EntracontaScreen._text
                    : Colors.black,
              ),
            ),
          ),
        ),
        SizedBox(height: 8 * scale),
        Container(
          height: 53 * scale,
          decoration: BoxDecoration(
            color: EntracontaScreen._inputFill,
            border: Border.all(color: EntracontaScreen._border),
            borderRadius: BorderRadius.circular(16 * scale),
          ),
          child: Row(
            children: [
              SizedBox(width: 16 * scale),
              SizedBox(
                width: label == EntracontaMockData.emailLabel
                    ? 16.64 * scale
                    : 13.36 * scale,
                height: label == EntracontaMockData.emailLabel
                    ? 13.36 * scale
                    : 17.5 * scale,
                child: AuthAssetImage(
                  iconAsset,
                  width: label == EntracontaMockData.emailLabel
                      ? 16.64 * scale
                      : 13.36 * scale,
                  height: label == EntracontaMockData.emailLabel
                      ? 13.36 * scale
                      : 17.5 * scale,
                ),
              ),
              SizedBox(width: (45 - 16 - 16.64) * scale),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  obscureText: obscureText,
                  enableSuggestions: !obscureText,
                  autocorrect: !obscureText,
                  onFieldSubmitted: onFieldSubmitted,
                  cursorColor: EntracontaScreen._primary,
                  style: GoogleFonts.inter(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w400,
                    color: EntracontaScreen._text,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w400,
                      color: EntracontaScreen._placeholder,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (trailingIconAsset != null) ...[
                SizedBox(width: 12 * scale),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTrailingTap,
                  child: SizedBox(
                    width: 18.32 * scale,
                    height: 15.82 * scale,
                    child: AuthAssetImage(
                      trailingIconAsset!,
                      width: 18.32 * scale,
                      height: 15.82 * scale,
                    ),
                  ),
                ),
                SizedBox(width: 16 * scale),
              ] else
                SizedBox(width: 17 * scale),
            ],
          ),
        ),
      ],
    );
  }
}

/// Botão "Continuar com Google". Serve tanto para entrar quanto para cadastrar
/// (novos usuários entram na esteira de aprovação como membro pendente).
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52 * scale,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          Icons.g_mobiledata_rounded,
          size: 32 * scale,
          color: const Color(0xFF4285F4),
        ),
        label: Text(
          'Continuar com Google',
          style: GoogleFonts.inter(
            fontSize: 15 * scale,
            fontWeight: FontWeight.w600,
            color: EntracontaScreen._text,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: EntracontaScreen._border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * scale),
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.scale,
    required this.onTap,
    required this.loading,
  });

  final double scale;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 52 * scale,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: EntracontaScreen._primary,
          borderRadius: BorderRadius.circular(16 * scale),
          boxShadow: [
            BoxShadow(
              color: EntracontaScreen._primary.withValues(alpha: 0.39),
              offset: Offset(0, 4 * scale),
              blurRadius: 7 * scale,
            ),
          ],
        ),
        child: loading
            ? SizedBox(
                width: 22 * scale,
                height: 22 * scale,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                EntracontaMockData.submit,
                style: GoogleFonts.inter(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                  letterSpacing: 1.4 * scale,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
