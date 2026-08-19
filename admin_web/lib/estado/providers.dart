import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../dados/acessos.dart';
import '../dados/auditoria_repository.dart';
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

/// Página vazia, para os providers que não devem consultar nada — o painel
/// não dispara consulta que as Rules negariam.
Stream<Pagina<T>> _semDados<T>() =>
    Stream.value(const Pagina(itens: [], truncada: false));

/// Membros da unidade em foco. Limitada — ver [MembrosRepository.observar].
final membrosProvider = StreamProvider<Pagina<MembroPainel>>((ref) {
  final acesso = ref.watch(acessoAtualProvider);
  if (acesso == null) return _semDados();
  return ref.watch(membrosRepositoryProvider).observar(acesso.igrejaId);
});

/// Contagens do dashboard por consulta agregada — não baixa os vínculos.
final contagemMembrosProvider = FutureProvider<ContagemMembros>((ref) async {
  final acesso = ref.watch(acessoAtualProvider);
  if (acesso == null) {
    return const ContagemMembros(
        pendentes: 0, aprovados: 0, inativos: 0, lideranca: 0);
  }
  return ref.watch(membrosRepositoryProvider).contar(acesso.igrejaId);
});

/// Transações da unidade em foco. Só emite para quem tem acesso financeiro —
/// senão as Rules negariam a consulta e o stream cairia em erro.
final transacoesProvider = StreamProvider<Pagina<Transacao>>((ref) {
  final acesso = ref.watch(acessoAtualProvider);
  if (acesso == null || !acesso.lerFinancas) return _semDados();
  return ref.watch(financasRepositoryProvider).observar(acesso.igrejaId);
});

/// Totais somados no servidor. Independem do teto de [transacoesProvider], por
/// isso o dashboard mostra o valor real mesmo com histórico longo.
final resumoFinanceiroProvider =
    FutureProvider<ResumoFinanceiroUnidade?>((ref) async {
  final acesso = ref.watch(acessoAtualProvider);
  if (acesso == null || !acesso.lerFinancas) return null;
  return ref.watch(financasRepositoryProvider).resumo(acesso.igrejaId);
});

final filtroFinancasProvider =
    StateProvider<FiltroFinancas>((ref) => const FiltroFinancas());

final transacoesFiltradasProvider = Provider<List<Transacao>>((ref) {
  final pagina = ref.watch(transacoesProvider).valueOrNull;
  final filtro = ref.watch(filtroFinancasProvider);
  return (pagina?.itens ?? const <Transacao>[]).where(filtro.aceita).toList();
});

// ── Conteúdo da unidade em foco ───────────────────────────────────────

/// Recriado quando a unidade muda, o que invalida os streams derivados e
/// descarta o cache da igreja anterior.
final conteudoRepositoryProvider = Provider<ConteudoRepository?>((ref) {
  final acesso = ref.watch(acessoAtualProvider);
  if (acesso == null) return null;
  return ConteudoRepository(igrejaId: acesso.igrejaId);
});

/// Emite vazio quando não há repositório ou o usuário não tem a capacidade —
/// evita disparar consulta que as Rules negariam.
Stream<T> _seAutorizado<T>(
  Ref ref,
  bool Function(AcessoIgreja) permite,
  Stream<T> Function(ConteudoRepository) consulta,
  T vazio,
) {
  final repo = ref.watch(conteudoRepositoryProvider);
  final acesso = ref.watch(acessoAtualProvider);
  if (repo == null || acesso == null || !permite(acesso)) {
    return Stream.value(vazio);
  }
  return consulta(repo);
}

Stream<Pagina<T>> _paginaSeAutorizado<T>(
  Ref ref,
  bool Function(AcessoIgreja) permite,
  Stream<Pagina<T>> Function(ConteudoRepository) consulta,
) =>
    _seAutorizado(ref, permite, consulta,
        const Pagina(itens: [], truncada: false));

final avisosProvider = StreamProvider<Pagina<Aviso>>((ref) =>
    _paginaSeAutorizado(ref, (a) => a.gerenciarConteudo, (r) => r.avisos()));

final eventosProvider = StreamProvider<Pagina<Evento>>((ref) =>
    _paginaSeAutorizado(ref, (a) => a.gerenciarConteudo, (r) => r.eventos()));

final campanhasProvider = StreamProvider<Pagina<Campanha>>((ref) =>
    _paginaSeAutorizado(ref, (a) => a.gerenciarConteudo, (r) => r.campanhas()));

final ministeriosProvider = StreamProvider<Pagina<Ministerio>>((ref) =>
    _paginaSeAutorizado(
        ref, (a) => a.gerenciarConteudo, (r) => r.ministerios()));

final devocionaisProvider = StreamProvider<Pagina<Devocional>>((ref) =>
    _paginaSeAutorizado(
        ref, (a) => a.gerenciarConteudo, (r) => r.devocionais()));

final oracoesPendentesProvider = StreamProvider<Pagina<PedidoOracao>>((ref) =>
    _paginaSeAutorizado(
        ref, (a) => a.moderarOracao, (r) => r.oracoesPendentes()));

final oracoesAprovadasProvider = StreamProvider<Pagina<PedidoOracao>>((ref) =>
    _paginaSeAutorizado(
        ref, (a) => a.moderarOracao, (r) => r.oracoesAprovadas()));

// ── Cartões do dashboard (consultas pequenas e ordenadas no servidor) ──

final avisosRecentesProvider = StreamProvider<List<Aviso>>((ref) =>
    _seAutorizado(ref, (a) => a.gerenciarConteudo, (r) => r.avisosRecentes(),
        const <Aviso>[]));

final proximosEventosProvider = StreamProvider<List<Evento>>((ref) =>
    _seAutorizado(ref, (a) => a.gerenciarConteudo, (r) => r.proximosEventos(),
        const <Evento>[]));

// ── Unidade em foco: configuração e status Mercado Pago ───────────────

/// Documento operacional privado `/igrejas/{id}` da unidade autorizada.
final igrejaAtualProvider = StreamProvider<IgrejaModel?>((ref) {
  final acesso = ref.watch(acessoAtualProvider);
  if (acesso == null) return Stream.value(null);
  return ref.watch(igrejasRepositoryProvider).observarUma(acesso.igrejaId);
});

// ── Auditoria da unidade em foco ──────────────────────────────────────

final auditoriaRepositoryProvider = Provider<AuditoriaRepository?>((ref) {
  final acesso = ref.watch(acessoAtualProvider);
  if (acesso == null) return null;
  return AuditoriaRepository(igrejaId: acesso.igrejaId);
});

/// Só liderança ministerial e `super_admin` leem auditoria (`canReadAudit`).
/// Para os demais o painel nem consulta — não gera erro de permissão na tela.
final auditoriaRecenteProvider =
    StreamProvider<List<RegistroAuditoria>?>((ref) {
  final repo = ref.watch(auditoriaRepositoryProvider);
  final acesso = ref.watch(acessoAtualProvider);
  final acessos = ref.watch(meusAcessosProvider).valueOrNull;
  if (repo == null || acesso == null) return Stream.value(null);

  final podeLer = (acessos?.isSuperAdmin ?? false) ||
      acesso.perfil.isLiderancaMinisterial;
  if (!podeLer) return Stream.value(null);

  return repo.recentes();
});

// ── Busca do dashboard ────────────────────────────────────────────────

/// Termo digitado na busca do dashboard. Filtra o que já está carregado —
/// não dispara consulta nova a cada tecla.
final buscaDashboardProvider = StateProvider<String>((ref) => '');

// ── Igrejas (super_admin) ─────────────────────────────────────────────

final igrejasRepositoryProvider =
    Provider<IgrejasRepository>((ref) => IgrejasRepository());

final igrejasProvider = StreamProvider<List<IgrejaModel>>((ref) {
  final acessos = ref.watch(meusAcessosProvider).valueOrNull;
  if (acessos == null || !acessos.isSuperAdmin) return Stream.value(const []);
  return ref.watch(igrejasRepositoryProvider).observar();
});

// ── Métricas do dashboard ─────────────────────────────────────────────
//
// As contagens vêm de `contagemMembrosProvider` (consulta agregada). Elas
// deixaram de ser derivadas da lista de membros de propósito: a lista é
// limitada, e contar sobre uma página truncada mostraria número menor que o
// real — um erro pior que uma consulta a mais.

/// Recarrega o que o dashboard mostra. Usado no botão "atualizar" e depois de
/// uma ação administrativa que muda contagem.
void recarregarDashboard(WidgetRef ref) {
  ref.invalidate(contagemMembrosProvider);
  ref.invalidate(resumoFinanceiroProvider);
}
