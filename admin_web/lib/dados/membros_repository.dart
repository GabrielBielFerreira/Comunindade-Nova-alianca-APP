import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../config/ambiente.dart';

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

  CollectionReference<Map<String, dynamic>> _colecao(IgrejaId igrejaId) =>
      _db.collection('igrejas/${igrejaId.valor}/membros');

  DateTime? _lerData(dynamic valor) =>
      valor is Timestamp ? valor.toDate() : (valor is DateTime ? valor : null);

  /// Membros da unidade. Ordenação no cliente para dispensar índice composto.
  Stream<List<MembroPainel>> observar(IgrejaId igrejaId) {
    return _colecao(igrejaId).snapshots().asyncMap((snap) async {
      final membros = snap.docs.map((doc) {
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
      }).toList();

      membros.sort((a, b) =>
          a.exibicao.toLowerCase().compareTo(b.exibicao.toLowerCase()));
      return membros;
    });
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
