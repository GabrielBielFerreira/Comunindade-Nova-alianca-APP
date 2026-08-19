import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/ambiente.dart';
import '../estado/providers.dart';
import '../ui/tema.dart';

/// Mensagem legível para o usuário do painel.
///
/// Em produção nenhuma mensagem cita emulador: falar de "emuladores" para o
/// pastor de uma igreja não ajuda e expõe detalhe de desenvolvimento.
String mensagemDeErroAuth(Object erro) {
  if (erro is FirebaseAuthException) {
    return switch (erro.code) {
      'invalid-email' => 'E-mail inválido.',
      'user-disabled' =>
        'Esta conta está desativada. Fale com o pastor da '
            'sua igreja.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'E-mail ou senha incorretos.',
      'missing-password' => 'Informe a senha.',
      'too-many-requests' =>
        'Muitas tentativas. Aguarde alguns minutos e tente de novo.',
      'operation-not-allowed' =>
        'Este método de acesso não está habilitado para o painel.',
      'network-request-failed' =>
        ambienteAtual.isEmulador
            ? 'Sem conexão com o servidor. Verifique se os emuladores estão '
                  'rodando.'
            : 'Sem conexão. Verifique sua internet e tente novamente.',
      _ =>
        'Não foi possível entrar. Se o problema continuar, informe este '
            'código ao suporte: ${erro.code}.',
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
      await ref
          .read(authProvider)
          .signInWithEmailAndPassword(
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layoutAmplo = constraints.maxWidth >= 840;
            final paddingExterno = layoutAmplo ? 32.0 : 12.0;
            final paddingCard = constraints.maxWidth < 360 ? 20.0 : 28.0;

            final formulario = Card(
              child: Padding(
                padding: EdgeInsets.all(layoutAmplo ? 32 : paddingCard),
                child: _conteudoFormulario(mostrarMarca: !layoutAmplo),
              ),
            );

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(paddingExterno),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: layoutAmplo ? 1000 : 480,
                  ),
                  child: layoutAmplo
                      ? Row(
                          children: [
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 32),
                                child: _Marca(),
                              ),
                            ),
                            const SizedBox(width: 32),
                            SizedBox(width: 420, child: formulario),
                          ],
                        )
                      : formulario,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _conteudoFormulario({required bool mostrarMarca}) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FaixaAmbiente(),
          if (mostrarMarca) ...[
            const _Marca(),
            const SizedBox(height: 24),
          ] else ...[
            Text(
              'Acesse sua conta',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Entre com as credenciais autorizadas pela liderança.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
          ],
          TextFormField(
            controller: _email,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Informe um e-mail válido.'
                : null,
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
                icon: Icon(
                  _mostrarSenha ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
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
    );
  }
}

/// Logo oficial e identificação do painel.
class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Image.asset(
          'assets/images/logo_nova_alianca.png',
          height: 84,
          fit: BoxFit.contain,
          semanticLabel: 'Logo da Igreja Nova Aliança',
          // Se o ativo faltar, o login continua utilizável.
          errorBuilder: (_, _, _) =>
              const Icon(Icons.church_outlined, size: 64, color: Cores.primary),
        ),
        const SizedBox(height: 16),
        Text(
          'Painel de Gestão',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          'Nova Aliança',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Cores.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Acesso exclusivo da liderança e da administração.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// Deixa explícito que o painel está apontando para o Emulator Suite.
///
/// Em produção não aparece: `ambienteAtual.isEmulador` é falso e o widget
/// devolve um espaço vazio.
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
      await ref
          .read(authProvider)
          .sendPasswordResetEmail(email: _email.text.trim());
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
                        Text(
                          _erro!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
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
