import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/igreja_scope.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/igrejas_repository.dart';

final igrejasRepositoryProvider =
    Provider<IgrejasRepository>((ref) => IgrejasRepository());

/// Unidades ativas da rede (tela de seleção).
final igrejasAtivasProvider = StreamProvider<List<IgrejaModel>>((ref) {
  return ref.watch(igrejasRepositoryProvider).streamAtivas();
});

/// Igreja PRINCIPAL do usuário: onde ele tem vínculo. Vem de
/// `usuarios/{uid}.igreja_principal_id` e só muda por operação de servidor.
///
/// Enquanto não houver usuário ou o campo estiver ausente, fica `null` — o
/// aplicativo não escolhe uma unidade por conta própria.
final igrejaPrincipalProvider = Provider<IgrejaId?>((ref) {
  final usuario = ref.watch(usuarioAtualProvider).valueOrNull;
  return IgrejaId.tentar(usuario?.igrejaPrincipalId);
});

/// Estado da preferência local de unidade.
///
/// [carregado] existe para separar "ainda não li o SharedPreferences" de
/// "não há unidade escolhida". Sem essa distinção, a primeira tela do
/// aplicativo pisca: o gate decide com `null` antes da leitura terminar e
/// manda para a tela errada por uma fração de segundo.
class EstadoIgrejaVisualizada {
  const EstadoIgrejaVisualizada({required this.carregado, this.id});

  const EstadoIgrejaVisualizada.carregando()
      : carregado = false,
        id = null;

  final bool carregado;
  final IgrejaId? id;

  bool get temEscolha => carregado && id != null;
}

/// Preferência LOCAL de qual unidade está sendo visualizada.
///
/// É apenas contexto de leitura: trocar aqui não altera vínculo, aprovação,
/// ministérios nem concede qualquer permissão.
///
/// Serve a dois papéis: a unidade que o VISITANTE escolheu no onboarding e a
/// unidade que um usuário autenticado está visitando. Em ambos os casos o
/// valor é preferência de leitura, nunca autorização.
class IgrejaVisualizadaNotifier extends StateNotifier<EstadoIgrejaVisualizada> {
  IgrejaVisualizadaNotifier() : super(const EstadoIgrejaVisualizada.carregando()) {
    _carregar();
  }

  static const _chave = 'igreja_visualizada_id';

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    state = EstadoIgrejaVisualizada(
      carregado: true,
      id: IgrejaId.tentar(prefs.getString(_chave)),
    );
  }

  Future<void> definir(IgrejaId? id) async {
    state = EstadoIgrejaVisualizada(carregado: true, id: id);
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_chave);
    } else {
      await prefs.setString(_chave, id.valor);
    }
  }

  /// Volta a visualizar a própria igreja.
  Future<void> limpar() => definir(null);
}

final igrejaVisualizadaProvider = StateNotifierProvider<
    IgrejaVisualizadaNotifier, EstadoIgrejaVisualizada>(
  (ref) => IgrejaVisualizadaNotifier(),
);

/// Unidade em foco: a visualizada, ou a principal quando não houver troca.
///
/// TODO provider operacional do aplicativo depende deste valor. Quando ele
/// muda, os providers dependentes são recriados automaticamente pelo Riverpod,
/// o que descarta o cache da unidade anterior.
final igrejaAtualProvider = Provider<IgrejaId?>((ref) {
  final visualizada = ref.watch(igrejaVisualizadaProvider).id;
  if (visualizada != null) return visualizada;
  return ref.watch(igrejaPrincipalProvider);
});

///  enquanto a preferência local ainda está sendo lida do disco.
///
/// O gate de entrada espera este valor antes de decidir a primeira tela.
final preferenciaIgrejaCarregandoProvider = Provider<bool>((ref) {
  return !ref.watch(igrejaVisualizadaProvider).carregado;
});

/// `true` quando o usuário está olhando uma unidade diferente da sua.
final visualizandoOutraIgrejaProvider = Provider<bool>((ref) {
  final atual = ref.watch(igrejaAtualProvider);
  final principal = ref.watch(igrejaPrincipalProvider);
  return atual != null && principal != null && atual != principal;
});

/// Escopo de dados da unidade em foco. `null` até haver unidade definida.
final igrejaScopeProvider = Provider<IgrejaScope?>((ref) {
  final id = ref.watch(igrejaAtualProvider);
  if (id == null) return null;
  return IgrejaScope(igrejaId: id);
});

/// Dados institucionais da unidade em foco.
final igrejaAtualDadosProvider = StreamProvider<IgrejaModel?>((ref) {
  final id = ref.watch(igrejaAtualProvider);
  if (id == null) return Stream.value(null);
  return ref.watch(igrejasRepositoryProvider).streamIgreja(id);
});

/// Vínculo do usuário NA UNIDADE EM FOCO.
///
/// É `null` quando ele apenas visita outra unidade — e é exatamente isso que
/// faz o conteúdo restrito continuar inacessível ali.
final vinculoAtualProvider = StreamProvider<VinculoIgreja?>((ref) {
  final id = ref.watch(igrejaAtualProvider);
  final usuario = ref.watch(usuarioAtualProvider).valueOrNull;
  if (id == null || usuario == null) return Stream.value(null);
  return ref.watch(igrejasRepositoryProvider).streamVinculo(id, usuario.uid);
});

/// Vínculo do usuário na PRÓPRIA igreja — não muda ao visualizar outra.
final vinculoPrincipalProvider = StreamProvider<VinculoIgreja?>((ref) {
  final id = ref.watch(igrejaPrincipalProvider);
  final usuario = ref.watch(usuarioAtualProvider).valueOrNull;
  if (id == null || usuario == null) return Stream.value(null);
  return ref.watch(igrejasRepositoryProvider).streamVinculo(id, usuario.uid);
});

/// Autorização do usuário sobre a unidade em foco.
///
/// Espelha o servidor; a interface usa isto apenas para esconder o que não faz
/// sentido mostrar. A segurança real continua nas Rules e nas Functions.
final autorizacaoAtualProvider = Provider<Autorizacao?>((ref) {
  final id = ref.watch(igrejaAtualProvider);
  final usuario = ref.watch(usuarioAtualProvider).valueOrNull;
  if (id == null || usuario == null) return null;

  final vinculo = ref.watch(vinculoAtualProvider).valueOrNull;
  return Autorizacao(uid: usuario.uid, igrejaId: id, vinculo: vinculo);
});

/// Membro aprovado na unidade em foco?
final isMembroAprovadoAtualProvider = Provider<bool>((ref) {
  return ref.watch(autorizacaoAtualProvider)?.temVinculoAtivo ?? false;
});

/// Liderança ministerial NA UNIDADE EM FOCO, para decisões de interface.
///
/// Substitui `usuarioProvider?.isLider`, que lia `perfil` do documento global
/// `usuarios/{uid}` — campo que as Rules não gravam mais e que valia para
/// qualquer igreja. Alguém aprovado como líder em Olinda aparecia como líder
/// ao visualizar Petrolina.
///
/// Isto é só apresentação: a segurança real continua nas Rules e nas
/// Functions, que repetem a autorização no servidor.
final isLiderancaNaUnidadeProvider = Provider<bool>((ref) {
  final autorizacao = ref.watch(autorizacaoAtualProvider);
  if (autorizacao == null) return false;
  return autorizacao.perfilEfetivo.isLiderancaMinisterial;
});

/// Pode criar/editar conteúdo da unidade em foco (avisos, eventos, campanhas,
/// ministérios, devocionais).
final podeGerenciarConteudoProvider = Provider<bool>((ref) {
  return ref.watch(autorizacaoAtualProvider)?.podeGerenciarConteudo ?? false;
});

/// Nome da unidade EM FOCO, para cabeçalhos.
///
/// Enquanto carrega, usa o nome da rede em vez de string vazia ou do nome de
/// outra unidade: é o único texto verdadeiro nesse instante.
///
/// Mostrar a unidade no cabeçalho é o que torna a troca de igreja visível —
/// com o nome da rede fixo, mudar de Olinda para Petrolina não aparecia.
final nomeIgrejaEmFocoProvider = Provider<String>((ref) {
  return ref.watch(igrejaAtualDadosProvider).valueOrNull?.nome ??
      'Comunidade Nova Aliança';
});
