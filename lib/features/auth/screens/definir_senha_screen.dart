import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../data/auth_error.dart';
import '../providers/auth_controller.dart';
import '../providers/auth_provider.dart';

/// Permite ao usuário logado (tipicamente via Google) DEFINIR uma senha de
/// e-mail para a mesma conta — passando a poder entrar também por e-mail/senha,
/// sem perder o acesso pelo Google.
class DefinirSenhaScreen extends ConsumerStatefulWidget {
  const DefinirSenhaScreen({super.key});

  @override
  ConsumerState<DefinirSenhaScreen> createState() => _DefinirSenhaScreenState();
}

class _DefinirSenhaScreenState extends ConsumerState<DefinirSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _obscure = true;
  bool _salvando = false;

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  void _mostrar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _salvando = true);
    String mensagem;
    bool ok = false;
    try {
      await ref
          .read(authActionsProvider)
          .definirSenha(_senhaController.text.trim());
      mensagem = 'Senha definida! Agora você também pode entrar por e-mail e '
          'senha.';
      ok = true;
    } catch (e) {
      mensagem = mensagemErroAuth(e);
    }

    if (!mounted) return;
    setState(() => _salvando = false);
    _mostrar(mensagem);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(usuarioProvider);
    final actions = ref.read(authActionsProvider);
    final jaTemSenha = actions.possuiSenha;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Senha de acesso',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      jaTemSenha
                          ? 'Esta conta já entra por e-mail e senha. Você pode '
                              'redefinir a senha abaixo.'
                          : 'Crie uma senha para entrar também por e-mail e '
                              'senha. O acesso pelo Google continua funcionando.',
                      style: const TextStyle(
                          color: AppColors.primaryHover, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (usuario != null) ...[
              Text(
                'E-mail',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 18, color: AppColors.mutedForeground),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        usuario.email,
                        style: const TextStyle(color: AppColors.foreground),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              'Nova senha',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _senhaController,
              obscureText: _obscure,
              decoration: _dec(
                'Pelo menos 6 caracteres',
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                ),
              ),
              validator: Validators.senha,
            ),
            const SizedBox(height: 18),
            Text(
              'Confirmar senha',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmarController,
              obscureText: _obscure,
              decoration: _dec('Repita a senha'),
              validator: (v) =>
                  Validators.confirmarSenha(v, _senhaController.text.trim()),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.lock_outline),
              label: Text(jaTemSenha ? 'Redefinir senha' : 'Definir senha'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderFocus),
        ),
      );
}
