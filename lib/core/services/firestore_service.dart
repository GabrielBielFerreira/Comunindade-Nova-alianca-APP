import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço base com helpers genéricos para o Firestore.
/// Cada feature implementa seus próprios métodos específicos.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseFirestore get db => _db;

  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(String path) {
    return _db.doc(path).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDoc(String path) {
    return _db.doc(path).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamColecao(
    String colecao, {
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(colecao);
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getColecao(
    String colecao, {
    String? orderBy,
    bool descending = false,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(colecao);
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    return query.get();
  }

  Future<DocumentReference<Map<String, dynamic>>> adicionar(
    String colecao,
    Map<String, dynamic> dados,
  ) {
    return _db.collection(colecao).add(dados);
  }

  Future<void> salvar(
    String path,
    Map<String, dynamic> dados, {
    bool merge = true,
  }) {
    return _db.doc(path).set(dados, SetOptions(merge: merge));
  }

  Future<void> atualizar(String path, Map<String, dynamic> campos) {
    return _db.doc(path).update(campos);
  }

  Future<void> deletar(String path) {
    return _db.doc(path).delete();
  }

  Future<void> incrementarCampo(String path, String campo, int delta) {
    return _db.doc(path).update({
      campo: FieldValue.increment(delta),
    });
  }

  Future<void> adicionarAoArray(String path, String campo, dynamic valor) {
    return _db.doc(path).update({
      campo: FieldValue.arrayUnion([valor]),
    });
  }

  Future<void> removerDoArray(String path, String campo, dynamic valor) {
    return _db.doc(path).update({
      campo: FieldValue.arrayRemove([valor]),
    });
  }

  Timestamp get agora => Timestamp.now();
  Timestamp timestampDe(DateTime dt) => Timestamp.fromDate(dt);
}
