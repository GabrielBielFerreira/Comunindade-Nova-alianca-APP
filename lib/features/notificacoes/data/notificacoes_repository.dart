import 'package:cloud_firestore/cloud_firestore.dart';

import 'notificacao_model.dart';

/// Central de Notificações (coleção `notificacoes`). Cada usuário lê apenas as
/// próprias (regras de segurança). Ordenação no cliente.
class NotificacoesRepository {
  NotificacoesRepository({FirebaseFirestore? db})
      : _col = (db ?? FirebaseFirestore.instance).collection('notificacoes');

  final CollectionReference<Map<String, dynamic>> _col;

  Stream<List<NotificacaoModel>> stream(String uid) {
    return _col
        .where('destinatario_id', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final lista = snap.docs.map(NotificacaoModel.fromFirestore).toList();
      lista.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return lista;
    });
  }

  Future<void> marcarLida(String id) => _col.doc(id).update({'lida': true});
}
