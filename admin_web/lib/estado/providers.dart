import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../dados/acessos.dart';
import '../dados/conteudo_repository.dart';
import '../dados/financas_repository.dart';
import '../dados/igrejas_repository.dart';
import '../dados/membros_repository.dart';

// ── Autenticação ──────────────────────────────────────────────────────

final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authProvider).authStateChanges();
});

// ── Acessos (fonte da autorização no painel) ──────────────────────────

final acessosRepositoryProvider =
    Provider<AcessosRepository>((ref) => AcessosRepository());

/// Recarrega sempre que a sessão muda. Uma sessão expirada derruba os acessos
/// junto, evitando painel exibindo dados de quem já saiu.
final meusAcessosProvider = FutureProvider<MeusAcessos?>((ref) async {
  final usuario = ref.watch(authStateProvider).valueOrNull;
  if (usuario == null) return null;
  return ref.watch(acessosRepositoryProvider).carregar();
});

/// Unidade selecionada. Trocar aqui NÃO concede permissão: o valor só é
/// aceito se estiver entre os acessos devolvidos pelo servidor.
final igrejaSelecionadaProvider = StateProvider<IgrejaId?>((ref) => null);

/// Acesso efetivo à unidade em foco, já validado contra `meusAcessos`.
final acessoAtualProvider = Provider<AcessoIgreja?>((ref) {
  final acessos = ref.watch(meusAcessosProvider).valueOrNull;
  if (acessos == null || acessos.acessos.isEmpty) return null;

  final selecionada = ref.watch(igrejaSelecionadaProvider);
  return acessos.porId(selecionada) ?? acessos.acessos.first;
});

// ── Repositórios ──────────────────────────────────────────────────────

final membrosRepositoryProvider =
    Provider<MembrosRepository>((ref) => MembrosRepository());

final financasRepositoryProvider =
    Provider<FinancasRepository>((ref) => FinancasRepository());

/// Membros da unidade em foco.
final membrosProvider = StreamProvider<List<MembroPainel>>((ref) {
  final acesso = ref.watch(acessoAtualProvider);
  if (acesso == null) return Stream.value(const []);
  return ref.watch(membrosRepositoryProvider).observar(acesso.igrejaId);
});

/// Transações da unidade em foco. Só emite para quem tem acesso financeiro —
/// senão as Rules negariam a consulta e o stream cairia em erro.
final transacoesProvider = StreamProvider<List<Transacao>>((ref) {
  final acesso = ref.watch(acessoAtualProvider);
  if (acesso == null || !acesso.lerFinancas) return Stream.value(const []);
  return ref.watch(financasRepositoryProvider).observar(acesso.igrejaId);
});

final filtroFinancasProvider =
    StateProvider<FiltroFinancas>((ref) => const FiltroFinancas());

final transacoesFiltradasProvider = Provider<List<Transacao>>((ref) {
  final todas = ref.watch(transacoesProvider).valueOrNull ?? const <Transacao>[];
  final filtro = ref.watch(filtroFinancasProvider);
  return todas.where(filtro.aceita).toList();
});

// ── Conteúdo da unidade em foco ───────────────────────────────────────

/// Recriado quando a unidade muda, o que invalida os streams derivados e
/// descarta o cache da igreja anterior.
final conteudoRepositoryProvider = Provider<ConteudoRepository?>((ref) {
  final acesso = ref.watch(acessoAtualProvider);
  if (acesso == null) return null;
  return ConteudoRepository(igrejaId: acesso.igrejaId);
});

/// Emite lista vazia quando não há repositório ou o usuário não tem a
/// capacidade — evita disparar consulta que as Rules negariam.
Stream<List<T>> _seAutorizado<T>(
  Ref ref,
  bool Function(AcessoIgreja) permite,
  Stream<List<T>> Function(ConteudoRepository) consulta,
) {
  final repo = ref.watch(conteudoRepositoryProvider);
  final acesso = ref.watch(acessoAtualProvider);
  if (repo == null || acesso == null || !permite(acesso)) {
    return Stream.value(const []);
  }
  return consulta(repo);
}

final avisosProvider = StreamProvider<List<Aviso>>((ref) =>
    _seAutorizado(ref, (a) => a.gerenciarConteudo, (r) => r.avisos()));

final eventosProvider = StreamProvider<List<Evento>>((ref) =>
    _seAutorizado(ref, (a) => a.gerenciarConteudo, (r) => r.eventos()));

final campanhasProvider = StreamProvider<List<Campanha>>((ref) =>
    _seAutorizado(ref, (a) => a.gerenciarConteudo, (r) => r.campanhas()));

final ministeriosProvider = StreamProvider<List<Ministerio>>((ref) =>
    _seAutorizado(ref, (a) => a.gerenciarConteudo, (r) => r.ministerios()));

final devocionaisProvider = StreamProvider<List<Devocional>>((ref) =>
    _seAutorizado(ref, (a) => a.gerenciarConteudo, (r) => r.devocionais()));

final oracoesPendentesProvider = StreamProvider<List<PedidoOracao>>((ref) =>
    _seAutorizado(ref, (a) => a.moderarOracao, (r) => r.oracoesPendentes()));

final oracoesAprovadasProvider = StreamProvider<List<PedidoOracao>>((ref) =>
    _seAutorizado(ref, (a) => a.moderarOracao, (r) => r.oracoesAprovadas()));

// ── Igrejas (super_admin) ─────────────────────────────────────────────

final igrejasRepositoryProvider =
    Provider<IgrejasRepository>((ref) => IgrejasRepository());

final igrejasProvider = StreamProvider<List<IgrejaModel>>((ref) {
  final acessos = ref.watch(meusAcessosProvider).valueOrNull;
  if (acessos == null || !acessos.isSuperAdmin) return Stream.value(const []);
  return ref.watch(igrejasRepositoryProvider).observar();
});

// ── Métricas do dashboard (contagens reais) ───────────────────────────

class ResumoDashboard {
  const ResumoDashboard({
    required this.pendentes,
    required this.aprovados,
    required this.inativos,
    required this.lideranca,
  });

  final int pendentes;
  final int aprovados;
  final int inativos;
  final int lideranca;
}

final resumoDashboardProvider = Provider<AsyncValue<ResumoDashboard>>((ref) {
  return ref.watch(membrosProvider).whenData((membros) {
    var pendentes = 0;
    var aprovados = 0;
    var inativos = 0;
    var lideranca = 0;

    for (final m in membros) {
      switch (m.vinculo.status) {
        case StatusVinculo.pendente:
          pendentes++;
        case StatusVinculo.aprovado:
          aprovados++;
          if (m.vinculo.perfil.isLiderancaMinisterial) lideranca++;
        case StatusVinculo.inativo:
          inativos++;
      }
    }

    return ResumoDashboard(
      pendentes: pendentes,
      aprovados: aprovados,
      inativos: inativos,
      lideranca: lideranca,
    );
  });
});
