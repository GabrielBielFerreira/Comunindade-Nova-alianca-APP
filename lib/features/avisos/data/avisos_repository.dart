import 'package:cloud_firestore/cloud_firestore.dart';

import 'aviso_model.dart';

/// Acesso ao Firestore para avisos (coleção `avisos`). Ordenação no cliente
/// para evitar índices compostos. Escrita é restrita à liderança pelas regras.
class AvisosRepository {
  AvisosRepository({FirebaseFirestore? db})
      : _col = (db ?? FirebaseFirestore.instance).collection('avisos');

  final CollectionReference<Map<String, dynamic>> _col;

  Stream<List<AvisoModel>> stream() {
    return _col.where('ativo', isEqualTo: true).snapshots().map((snap) {
      final lista = snap.docs.map(AvisoModel.fromFirestore).toList();
      lista.sort((a, b) => b.publicadoEm.compareTo(a.publicadoEm));
      return lista;
    });
  }
}
