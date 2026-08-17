import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../config/ambiente.dart';
import 'conteudo_repository.dart' show Pagina;

/// Um vínculo enriquecido com o nome da pessoa, para exibição em lista.
class MembroPainel {
  const MembroPainel({required this.vinculo, this.nome, this.email});

  final VinculoIgreja vinculo;
  final String? nome;
  final String? email;

  String get exibicao {
    final n = nome?.trim();
    if (n != null && n.isNotEmpty) return n;
    final e = email?.trim();
    if (e != null && e.isNotEmpty) return e;
    return vinculo.uid;
  }
}

/// Contagens da unidade, obtidas por consulta agregada.
///
/// O dashboard NÃO baixa a coleção de membros para contar: `count()` roda no
/// servidor e cobra uma fração da leitura, o que importa numa unidade com
/// milhares de vínculos.
class ContagemMembros {
  const ContagemMembros({
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

/// Leitura de membros e mutações via Cloud Functions.
///
/// Leituras vão direto ao Firestore (as Rules já restringem ao escopo da
/// unidade). Toda MUTAÇÃO passa por Function — o cliente não tem permissão
/// de escrever perfil, status ou funções.
class MembrosRepository {
  MembrosRepository({FirebaseFirestore? db, FirebaseFunctions? functions})
      : _db = db ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(
              region: ConfiguracaoFirebase.regiaoFunctions,
            );

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  /// Teto da lista de gestão. A busca da tela filtra dentro desta página.
  static const int limitePadrao = 300;

  CollectionReference<Map<String, dynamic>> _colecao(IgrejaId igrejaId) =>
      _db.collection('igrejas/${igrejaId.valor}/membros');

  DateTime? _lerData(dynamic valor) =>
      valor is Timestamp ? valor.toDate() : (valor is DateTime ? valor : null);

  /// Membros da unidade. Ordenação no cliente para dispensar índice composto.
  ///
  /// Limitada: uma unidade grande não pode fazer o painel baixar todos os
  /// vínculos de uma vez. A tela informa quando a lista foi truncada.
  Stream<Pagina<MembroPainel>> observar(
    IgrejaId igrejaId, {
    int limite = limitePadrao,
  }) {
    return _colecao(igrejaId).limit(limite + 1).snapshots().map((snap) {
      final truncada = snap.docs.length > limite;
      final docs = truncada ? snap.docs.take(limite) : snap.docs;

      final membros = docs.map((doc) {
        return MembroPainel(
          vinculo: VinculoIgreja.doMapa(
            uid: doc.id,
            igrejaId: igrejaId,
            dados: doc.data(),
            lerData: _lerData,
          ),
          nome: doc.data()['nome'] as String?,
          email: doc.data()['email'] as String?,
        );
      }).toList()
        ..sort((a, b) =>
            a.exibicao.toLowerCase().compareTo(b.exibicao.toLowerCase()));

      return Pagina(itens: membros, truncada: truncada);
    });
  }

  /// Contagens por consulta agregada — nenhum documento trafega.
  Future<ContagemMembros> contar(IgrejaId igrejaId) async {
    final col = _colecao(igrejaId);

    Future<int> quantos(Query<Map<String, dynamic>> q) async =>
        (await q.count().get()).count ?? 0;

    // Disparadas em paralelo: são quatro idas independentes ao servidor.
    final resultados = await Future.wait([
      quantos(col.where('status', isEqualTo: StatusVinculo.pendente.valor)),
      quantos(col.where('status', isEqualTo: StatusVinculo.aprovado.valor)),
      quantos(col.where('status', isEqualTo: StatusVinculo.inativo.valor)),
      quantos(
        col
            .where('status', isEqualTo: StatusVinculo.aprovado.valor)
            .where(
              'perfil',
              whereIn: PerfilComunitario.values
                  .where((p) => p.isLiderancaMinisterial)
                  .map((p) => p.valor)
                  .toList(),
            ),
      ),
    ]);

    return ContagemMembros(
      pendentes: resultados[0],
      aprovados: resultados[1],
      inativos: resultados[2],
      lideranca: resultados[3],
    );
  }

  Future<void> _chamar(String nome, Map<String, dynamic> dados) async {
    await _functions.httpsCallable(nome).call(dados);
  }

  Future<void> aprovar({required IgrejaId igrejaId, required String uid}) =>
      _chamar('aprovarMembro', {'igrejaId': igrejaId.valor, 'uid': uid});

  Future<void> recusar({
    required IgrejaId igrejaId,
    required String uid,
    required String motivo,
  }) =>
      _chamar('recusarMembro',
          {'igrejaId': igrejaId.valor, 'uid': uid, 'motivo': motivo});

  Future<void> promover({
    required IgrejaId igrejaId,
    required String uid,
    required PerfilComunitario perfil,
  }) =>
      _chamar('promoverParaLideranca',
          {'igrejaId': igrejaId.valor, 'uid': uid, 'perfil': perfil.valor});

  Future<void> removerDaLideranca({
    required IgrejaId igrejaId,
    required String uid,
    required String motivo,
  }) =>
      _chamar('removerDaLideranca',
          {'igrejaId': igrejaId.valor, 'uid': uid, 'motivo': motivo});

  Future<void> desvincular({
    required IgrejaId igrejaId,
    required String uid,
    required String motivo,
  }) =>
      _chamar('desvincularDaIgreja',
          {'igrejaId': igrejaId.valor, 'uid': uid, 'motivo': motivo});

  /// Atribui tesoureiro, editor ou moderador de oração.
  ///
  /// A função `pastor` NÃO é atribuída avulsa: ela acompanha a promoção de
  /// perfil, e o servidor rejeita a tentativa.
  Future<void> atribuirFuncao({
    required IgrejaId igrejaId,
    required String uid,
    required FuncaoAdmin funcao,
  }) =>
      _chamar('atribuirFuncaoAdmin',
          {'igrejaId': igrejaId.valor, 'uid': uid, 'funcao': funcao.valor});

  Future<void> removerFuncao({
    required IgrejaId igrejaId,
    required String uid,
    required FuncaoAdmin funcao,
    required String motivo,
  }) =>
      _chamar('removerFuncaoAdmin', {
        'igrejaId': igrejaId.valor,
        'uid': uid,
        'funcao': funcao.valor,
        'motivo': motivo,
      });
}
