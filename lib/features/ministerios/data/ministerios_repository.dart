import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/data/igreja_scope.dart';
import '../../avisos/data/ministerio_model.dart';

/// Ministérios de UMA unidade: `igrejas/{igrejaId}/ministerios`.
class MinisteriosRepository {
  MinisteriosRepository(this._scope);

  final IgrejaScope _scope;

  CollectionReference<Map<String, dynamic>> get _col => _scope.ministerios;

  Future<MinisterioModel?> obter(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? MinisterioModel.fromFirestore(doc) : null;
  }

  Stream<List<MinisterioModel>> stream() {
    return _col.where('ativo', isEqualTo: true).snapshots().map(_ordenar);
  }

  /// Visão de gestão: inclui inativos.
  Stream<List<MinisterioModel>> streamGerenciar() {
    return _col.snapshots().map(_ordenar);
  }

  List<MinisterioModel> _ordenar(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs.map(MinisterioModel.fromFirestore).toList();
    lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }

  Future<String> criar(MinisterioModel ministerio) async {
    final ref = await _col.add(ministerio.toMap());
    return ref.id;
  }

  Future<void> atualizar(MinisterioModel ministerio) {
    return _col.doc(ministerio.id).update(ministerio.toMap());
  }

  /// Ativa/desativa sem apagar. Não existe exclusão física de ministério:
  /// escalas, autoria de conteúdo e histórico dependem do documento.
  Future<void> definirAtivo(String id, bool ativo) {
    return _col.doc(id).update({'ativo': ativo});
  }

  /// Interesse do membro em participar — fica no escopo da própria unidade.
  Future<void> registrarInteresse({
    required String uid,
    required String nome,
    String? ministerioId,
    String? ministerioNome,
  }) async {
    await _scope.interessesMinisterio.add({
      'usuario_id': uid,
      'usuario_nome': nome,
      'ministerio_id': ministerioId,
      'ministerio_nome': ministerioNome,
      'status': 'novo',
      'criado_em': FieldValue.serverTimestamp(),
    });
  }
}
