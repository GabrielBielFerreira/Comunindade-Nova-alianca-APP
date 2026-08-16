import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../../../core/data/igreja_scope.dart';

/// Catálogo de unidades da rede e vínculos do usuário.
///
/// `igrejas/{id}` é legível sem sessão de propósito: o aplicativo precisa
/// listar as unidades antes do login, na seleção de igreja. Já o vínculo
/// (`membros/{uid}`) é dado de autorização e exige sessão.
class IgrejasRepository {
  IgrejasRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('igrejas');

  /// Todas as unidades ativas, para a tela de seleção.
  Stream<List<IgrejaModel>> streamAtivas() {
    return _col.where('ativa', isEqualTo: true).snapshots().map((snap) {
      final lista = snap.docs
          .map((d) => IgrejaModel.doMapa(
                id: d.id,
                dados: d.data(),
                lerData: lerDataFirestore,
              ))
          .toList();
      lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      return lista;
    });
  }

  Stream<IgrejaModel?> streamIgreja(IgrejaId id) {
    return _col.doc(id.valor).snapshots().map((d) {
      if (!d.exists) return null;
      return IgrejaModel.doMapa(
        id: d.id,
        dados: d.data()!,
        lerData: lerDataFirestore,
      );
    });
  }

  Future<IgrejaModel?> buscar(IgrejaId id) async {
    final snap = await _col.doc(id.valor).get();
    if (!snap.exists) return null;
    return IgrejaModel.doMapa(
      id: snap.id,
      dados: snap.data()!,
      lerData: lerDataFirestore,
    );
  }

  /// Vínculo do usuário numa unidade. `null` quando não há vínculo.
  Stream<VinculoIgreja?> streamVinculo(IgrejaId igrejaId, String uid) {
    return _col
        .doc(igrejaId.valor)
        .collection('membros')
        .doc(uid)
        .snapshots()
        .map((d) {
      if (!d.exists) return null;
      return VinculoIgreja.doMapa(
        uid: uid,
        igrejaId: igrejaId,
        dados: d.data()!,
        lerData: lerDataFirestore,
      );
    });
  }

  /// Cria o vínculo PENDENTE do próprio usuário. As Rules só aceitam
  /// `status: pendente`, `perfil: membro` e `funcoes_admin` vazio — promoção
  /// é exclusiva do servidor.
  Future<void> criarVinculoPendente({
    required IgrejaId igrejaId,
    required String uid,
  }) async {
    await _col.doc(igrejaId.valor).collection('membros').doc(uid).set({
      'perfil': PerfilComunitario.membro.valor,
      'status': StatusVinculo.pendente.valor,
      'funcoes_admin': <String>[],
      'ministerio_ids': <String>[],
      'criado_em': FieldValue.serverTimestamp(),
    });
  }
}
