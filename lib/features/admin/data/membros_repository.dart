import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/data/usuario_model.dart';

/// Leitura de membros para a liderança (ex.: escolher o líder de um ministério).
///
/// As regras do Firestore só permitem que a liderança (`isLider`) leia a
/// coleção `usuarios` inteira; membros comuns não conseguem listar todos.
class MembrosRepository {
  MembrosRepository({FirebaseFirestore? db})
      : _col = (db ?? FirebaseFirestore.instance).collection('usuarios');

  final CollectionReference<Map<String, dynamic>> _col;

  /// Membros aprovados, ordenados por nome. Base do seletor de membros.
  Stream<List<UsuarioModel>> streamAprovados() {
    return _col.where('status', isEqualTo: 'aprovado').snapshots().map((snap) {
      final lista = snap.docs.map(UsuarioModel.fromFirestore).toList();
      lista.sort(
          (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      return lista;
    });
  }
}
