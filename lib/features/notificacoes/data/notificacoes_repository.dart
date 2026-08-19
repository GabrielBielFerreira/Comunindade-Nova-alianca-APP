import 'package:cloud_firestore/cloud_firestore.dart';

import 'notificacao_model.dart';

/// Notificações pessoais: `usuarios/{uid}/notificacoes`.
///
/// Saíram da coleção global para uma subcoleção do próprio usuário. Assim a
/// regra é trivial ("é o dono?") em vez de depender de um campo
/// `destinatario_id` que precisava ser conferido em toda leitura.
class NotificacoesRepository {
  NotificacoesRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('usuarios').doc(uid).collection('notificacoes');

  Stream<List<NotificacaoModel>> stream(String uid) {
    return _col(uid).snapshots().map((snap) {
      final lista = snap.docs.map(NotificacaoModel.fromFirestore).toList();
      lista.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return lista;
    });
  }

  /// Marcar como lida é a única escrita permitida ao cliente.
  Future<void> marcarLida(String uid, String id) =>
      _col(uid).doc(id).update({'lida': true});

  Future<void> excluir(String uid, String id) => _col(uid).doc(id).delete();
}
