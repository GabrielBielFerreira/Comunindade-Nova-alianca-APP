import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../core/services/fcm_service.dart';
import '../core/services/notification_preferences.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/data/auth_service.dart';
import '../features/igrejas/providers/igreja_providers.dart';
import '../visual/screens/home_leader_screen.dart';
import '../visual/screens/select_church_screen.dart';
import '../visual/screens/home_member_screen.dart';
import '../visual/screens/welcome_access_screen.dart';
import 'screens/aguardando_aprovacao_screen.dart';
import 'screens/conta_inativa_screen.dart';
import 'screens/splash_screen.dart';

/// Porta de entrada única do app de produção.
///
/// Decide qual experiência renderizar:
///
/// - Não autenticado/anônimo  → [WelcomeAccessScreen]
/// - Sem documento de usuário → recuperação segura do cadastro incompleto
/// - Sem igreja principal     → [SemIgrejaVinculadaScreen]
/// - Vínculo pendente         → [AguardandoAprovacaoScreen]
/// - Vínculo inativo          → [ContaInativaScreen]
/// - Vínculo aprovado         → Home por perfil (liderança ou membro)
///
/// ## Fonte da decisão
///
/// A decisão vem do VÍNCULO com a igreja principal
/// (`igrejas/{igrejaId}/membros/{uid}`), não mais de `perfil`/`status` no
/// documento global `usuarios/{uid}`.
///
/// Isso é obrigatório na arquitetura multi-igreja: autorização é sempre
/// relativa a uma unidade. Ler o perfil global permitia que alguém aprovado
/// numa igreja fosse tratado como aprovado em qualquer outra — e as Rules
/// atuais nem gravam mais esses campos ali.
///
/// Usa deliberadamente o vínculo PRINCIPAL, não o da unidade em foco: quem
/// visita outra igreja continua entrando no aplicativo pela própria.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inicializa o FCM quando começa uma sessão REAL. A autenticação anônima
    // existe apenas para permitir ações públicas (como pedido de oração) e
    // não representa um membro nem deve registrar o aparelho como se fosse.
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final anterior = previous?.valueOrNull;
      final atual = next.valueOrNull;
      if (_iniciouContaReal(anterior, atual)) {
        // Falhas de FCM não devem quebrar o app (ex.: sem google-services.json).
        FcmService.init().catchError((_) {});
      }
    });

    // Notificações seguem a igreja PRINCIPAL, nunca a visualizada.
    //
    // Antes as inscrições eram globais (`transmissoes`, `eventos`,
    // `comunicacoes`) e um aviso de Olinda chegava no aparelho de quem é de
    // Petrolina. Agora o tópico carrega o IgrejaId, e é este listener que
    // reconcilia a inscrição quando o vínculo oficial muda — inclusive depois
    // de uma transferência oficial entre unidades.
    ref.listen<IgrejaId?>(igrejaPrincipalProvider, (anterior, atual) {
      if (anterior == atual) return;
      NotificationPreferences.sincronizar(atual).catchError((_) {});
    });

    // Ao entrar numa CONTA REAL, descarta a unidade pública escolhida antes
    // do login. Isso também cobre a transição anônimo -> e-mail/Google, na
    // qual os dois estados possuem User não nulo, mas são sessões diferentes.
    //
    // Sem isto, quem navegou como visitante em Petrolina e depois entrou com
    // conta de Olinda continuaria vendo Petrolina — herdando silenciosamente
    // um contexto que não é o seu. A sessão começa sempre na igreja do
    // vínculo; visitar outra passa a exigir uma troca manual explícita.
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      if (_iniciouContaReal(previous?.valueOrNull, next.valueOrNull)) {
        ref.read(igrejaVisualizadaProvider.notifier).limpar();
      }
    });

    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const SplashScreen(),
      error: (_, _) => const WelcomeAccessScreen(),
      data: (firebaseUser) {
        // A sessão anônima é uma credencial técnica para gravar ações de
        // visitante sob Rules seguras. Sem perfil/vínculo, ela continua na
        // experiência pública e nunca cai em "Preparando sua conta...".
        if (firebaseUser == null || firebaseUser.isAnonymous) {
          // ── Onboarding do visitante ──────────────────────────────────
          //
          // O produto começa escolhendo a igreja: sem unidade em foco não há
          // conteúdo a mostrar, porque tudo vive sob "igrejas/{igrejaId}".
          final preferencia = ref.watch(igrejaVisualizadaProvider);

          // Espera a leitura do disco. Decidir com nulo antes disso faria a
          // tela de seleção piscar para quem já escolheu.
          if (!preferencia.carregado) return const SplashScreen();

          if (preferencia.id == null) {
            return const SelectChurchScreen(modo: ModoSelecaoIgreja.onboarding);
          }

          // Uma preferência local não é prova de que a unidade continua
          // pública. O catálogo contém somente unidades ativas; validar pela
          // lista evita consultar diretamente um documento que acabou de ser
          // desativado (essa leitura é negada pelas Rules).
          final catalogoAtivo = ref.watch(catalogoIgrejasAtivasProvider);
          return catalogoAtivo.when(
            loading: () => const SplashScreen(),
            error: (_, _) => SplashScreen(
              mensagem:
                  'Não foi possível verificar as igrejas disponíveis. '
                  'Verifique sua conexão e tente novamente.',
              onTentarNovamente: () =>
                  ref.invalidate(catalogoIgrejasAtivasProvider),
            ),
            data: (catalogo) {
              final idSalvo = preferencia.id!;
              final continuaAtiva = catalogo.igrejas.any(
                (igreja) => igreja.id == idSalvo && igreja.ativa,
              );
              if (!continuaAtiva && !catalogo.confirmadoNoServidor) {
                // Cache local ausente/vazio não confirma desativação. Mantém a
                // preferência e oferece nova tentativa quando a rede voltar.
                return SplashScreen(
                  mensagem:
                      'Não foi possível confirmar a igreja selecionada. '
                      'Verifique sua conexão e tente novamente.',
                  onTentarNovamente: () =>
                      ref.invalidate(catalogoIgrejasAtivasProvider),
                );
              }
              if (!continuaAtiva) {
                // A mutação ocorre depois deste build e só apaga o mesmo ID
                // que foi validado. Um callback atrasado não remove uma nova
                // escolha feita pela pessoa.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  final atual = ref.read(igrejaVisualizadaProvider);
                  if (atual.id == idSalvo) {
                    ref.read(igrejaVisualizadaProvider.notifier).limpar();
                  }
                });
                return const SplashScreen();
              }

              return const WelcomeAccessScreen();
            },
          );
        }

        final usuarioAsync = ref.watch(usuarioAtualProvider);
        return usuarioAsync.when(
          loading: () => const SplashScreen(),
          // Nunca deixa o usuário preso: oferece tentar de novo ou sair.
          error: (_, _) => SplashScreen(
            mensagem:
                'Não foi possível carregar seu perfil. '
                'Verifique sua conexão e tente novamente.',
            onTentarNovamente: () => ref.invalidate(usuarioAtualProvider),
            onSair: () => ref.read(authServiceProvider).logout(),
          ),
          data: (usuario) {
            if (usuario == null) {
              // Uma conta real sem `usuarios/{uid}` pode ser um cadastro cujo
              // batch falhou e cuja exclusão compensatória também falhou. Não
              // mostramos carregamento infinito nem criamos vínculo de forma
              // implícita: a própria pessoa pode revalidar ou remover somente
              // a credencial órfã e então refazer o cadastro.
              return const ContaSemCadastroScreen();
            }

            // Conta sem unidade: cadastro antigo ou provisionamento parcial.
            // Não adivinhamos uma igreja — sem vínculo não há o que liberar.
            final principal = ref.watch(igrejaPrincipalProvider);
            if (principal == null) {
              return const SemIgrejaVinculadaScreen();
            }

            final vinculoAsync = ref.watch(vinculoPrincipalProvider);
            return vinculoAsync.when(
              loading: () => const SplashScreen(),
              error: (_, _) => SplashScreen(
                mensagem:
                    'Não foi possível verificar seu vínculo com a '
                    'igreja. Verifique sua conexão e tente novamente.',
                onTentarNovamente: () =>
                    ref.invalidate(vinculoPrincipalProvider),
                onSair: () => ref.read(authServiceProvider).logout(),
              ),
              data: (vinculo) {
                // Autenticado, com igreja principal, mas sem documento de
                // vínculo: o cadastro não completou. Tratar como pendente é o
                // mais seguro — nunca liberar conteúdo por ausência de dado.
                if (vinculo == null) {
                  return const AguardandoAprovacaoScreen();
                }

                switch (vinculo.status) {
                  case StatusVinculo.pendente:
                    return const AguardandoAprovacaoScreen();
                  case StatusVinculo.inativo:
                    return const ContaInativaScreen();
                  case StatusVinculo.aprovado:
                    // O vínculo PRINCIPAL decide se a conta pode entrar. A
                    // navegação administrativa, porém, segue a unidade EM
                    // FOCO. Um líder de Olinda que apenas visita Petrolina
                    // continua vendo o conteúdo público de Petrolina, mas
                    // não recebe botões de gestão dali sem um vínculo de
                    // liderança aprovado também em Petrolina.
                    final visualizandoOutra = ref.watch(
                      visualizandoOutraIgrejaProvider,
                    );
                    final liderNaUnidadeEmFoco = visualizandoOutra
                        ? ref.watch(isLiderancaNaUnidadeProvider)
                        : vinculo.perfil.isLiderancaMinisterial;

                    return liderNaUnidadeEmFoco
                        ? const HomeLeaderScreen()
                        : const HomeMemberScreen();
                }
              },
            );
          },
        );
      },
    );
  }
}

/// Estado fail-closed para uma credencial real sem documento de usuário.
///
/// Nenhuma Home ou permissão é liberada. A recuperação confirma no servidor
/// que o documento continua ausente antes de excluir a credencial do Auth.
class ContaSemCadastroScreen extends ConsumerStatefulWidget {
  const ContaSemCadastroScreen({super.key});

  @override
  ConsumerState<ContaSemCadastroScreen> createState() =>
      _ContaSemCadastroScreenState();
}

class _ContaSemCadastroScreenState
    extends ConsumerState<ContaSemCadastroScreen> {
  bool _recuperando = false;
  String? _erro;

  Future<void> _recomecarCadastro() async {
    if (_recuperando) return;
    setState(() {
      _recuperando = true;
      _erro = null;
    });

    try {
      final resultado = await ref
          .read(authServiceProvider)
          .recuperarCadastroIncompleto();
      if (!mounted) return;

      if (resultado == RecuperacaoCadastroIncompleto.cadastroEncontrado) {
        // O documento pode ter chegado depois do primeiro snapshot. Nada foi
        // excluído; apenas forçamos uma nova assinatura do perfil.
        ref.invalidate(usuarioAtualProvider);
      }
      // Quando a credencial é removida, o authState leva o RootGate de volta
      // ao fluxo público. Não há navegação manual nem estado inventado aqui.
      setState(() => _recuperando = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recuperando = false;
        _erro =
            'Não foi possível liberar este acesso agora. Verifique sua '
            'conexão e tente novamente. Se continuar, saia, entre novamente '
            'e procure o responsável pelo aplicativo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 56,
                    color: Color(0xFF7A0022),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Não foi possível concluir seu cadastro',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seu acesso foi criado, mas os dados do cadastro e o '
                    'vínculo com uma igreja não foram encontrados. Nenhum '
                    'acesso de membro foi liberado.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _erro!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _recuperando ? null : _recomecarCadastro,
                      child: _recuperando
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Recomeçar cadastro'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _recuperando
                          ? null
                          : () => ref.invalidate(usuarioAtualProvider),
                      child: const Text('Tentar carregar novamente'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _recuperando
                        ? null
                        : () => ref.read(authServiceProvider).logout(),
                    child: const Text('Sair'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uma conta real começou quando saímos de nenhuma sessão, de uma sessão
/// anônima ou trocamos de uid. Comparar apenas null/não-null falhava no caso
/// anônimo -> e-mail/Google.
bool _iniciouContaReal(User? anterior, User? atual) {
  if (atual == null || atual.isAnonymous) return false;
  return anterior == null || anterior.isAnonymous || anterior.uid != atual.uid;
}

/// Conta autenticada que não está vinculada a nenhuma unidade.
///
/// Acontece com cadastros anteriores à arquitetura multi-igreja e com
/// provisionamentos interrompidos. A saída é escolher a igreja, não navegar
/// pelo aplicativo sem escopo.
class SemIgrejaVinculadaScreen extends ConsumerWidget {
  const SemIgrejaVinculadaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.church_outlined,
                  size: 56,
                  color: Color(0xFF7A0022),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sua conta ainda não está vinculada a uma igreja',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Fale com a liderança da sua igreja para concluir o '
                  'vínculo. Enquanto isso, você pode sair e entrar novamente '
                  'escolhendo a sua unidade.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => ref.read(authServiceProvider).logout(),
                  child: const Text('Sair'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
