import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/ambiente.dart';
import '../estado/providers.dart';

String mensagemDeErroAuth(Object erro) {
  if (erro is FirebaseAuthException) {
    return switch (erro.code) {
      'invalid-email' => 'E-mail inválido.',
      'user-disabled' => 'Esta conta está desativada.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'E-mail ou senha incorretos.',
      'too-many-requests' =>
        'Muitas tentativas. Aguarde alguns minutos e tente de novo.',
      'network-request-failed' =>
        'Sem conexão com o servidor. Verifique se os emuladores estão rodando.',
      _ => 'Não foi possível entrar (${erro.code}).',
    };
  }
  return 'Não foi possível entrar. Tente novamente.';
}

class LoginTela extends ConsumerStatefulWidget {
  const LoginTela({super.key});

  @override
  ConsumerState<LoginTela> createState() => _LoginTelaState();
}

class _LoginTelaState extends ConsumerState<LoginTela> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _carregando = false;
  bool _mostrarSenha = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await ref.read(authProvider).signInWithEmailAndPassword(
            email: _email.text.trim(),
            password: _senha.text,
          );
      // A navegação é reativa: o redirect do router observa authStateProvider.
    } catch (erro) {
      if (mounted) setState(() => _erro = mensagemDeErroAuth(erro));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _FaixaAmbiente(),
                      const SizedBox(height: 24),
                      Text('Painel Nova Aliança',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Acesso administrativo',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        autofocus: true,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? 'Informe um e-mail válido.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _senha,
                        obscureText: !_mostrarSenha,
                        onFieldSubmitted: (_) => _entrar(),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_mostrarSenha
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _mostrarSenha = !_mostrarSenha),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Informe a senha.' : null,
                      ),
                      if (_erro != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_erro!)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _carregando ? null : _entrar,
                        child: _carregando
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Entrar'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _carregando
                            ? null
                            : () => context.push('/recuperar-senha'),
                        child: const Text('Esqueci minha senha'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Deixa explícito que o painel está apontando para o Emulator Suite.
class _FaixaAmbiente extends StatelessWidget {
  const _FaixaAmbiente();

  @override
  Widget build(BuildContext context) {
    if (!ambienteAtual.isEmulador) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.science_outlined, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ambienteAtual.rotulo,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Recuperação de senha via Firebase Auth.
class RecuperarSenhaTela extends ConsumerStatefulWidget {
  const RecuperarSenhaTela({super.key});

  @override
  ConsumerState<RecuperarSenhaTela> createState() => _RecuperarSenhaTelaState();
}

class _RecuperarSenhaTelaState extends ConsumerState<RecuperarSenhaTela> {
  final _email = TextEditingController();
  bool _carregando = false;
  String? _erro;
  bool _enviado = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await ref.read(authProvider).sendPasswordResetEmail(email: _email.text.trim());
      if (mounted) setState(() => _enviado = true);
    } catch (erro) {
      if (mounted) setState(() => _erro = mensagemDeErroAuth(erro));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _enviado
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mark_email_read_outlined, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Se existir uma conta com este e-mail, o link de '
                        'redefinição foi enviado.',
                        textAlign: TextAlign.center,
                      ),
                      if (ambienteAtual.isEmulador) ...[
                        const SizedBox(height: 12),
                        Text(
                          'No emulador, o link aparece no console do Emulator '
                          'Suite (aba Authentication), não em um e-mail real.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.tonal(
                        onPressed: () => context.go('/login'),
                        child: const Text('Voltar ao login'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _email,
                        autofocus: true,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_erro != null) ...[
                        const SizedBox(height: 12),
                        Text(_erro!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _carregando ? null : _enviar,
                        child: const Text('Enviar link de redefinição'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
