import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../../../core/data/igreja_scope.dart';

/// Vínculo enriquecido com o nome da pessoa, para listas de gestão.
class MembroUnidade {
  const MembroUnidade({required this.vinculo, this.nome, this.email});

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

/// Leitura dos vínculos de UMA unidade: `igrejas/{igrejaId}/membros`.
///
/// Somente leitura: aprovar, recusar, promover e desvincular são operações de
/// servidor (Cloud Functions). O cliente não escreve perfil, status nem
/// funções administrativas — as Rules negam.
class MembrosRepository {
  MembrosRepository(this._scope);

  final IgrejaScope _scope;

  CollectionReference<Map<String, dynamic>> get _col => _scope.membros;

  Stream<List<MembroUnidade>> stream() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs.map((doc) {
        return MembroUnidade(
          vinculo: VinculoIgreja.doMapa(
            uid: doc.id,
            igrejaId: _scope.igrejaId,
            dados: doc.data(),
            lerData: lerDataFirestore,
          ),
          nome: doc.data()['nome'] as String?,
          email: doc.data()['email'] as String?,
        );
      }).toList();

      lista.sort((a, b) =>
          a.exibicao.toLowerCase().compareTo(b.exibicao.toLowerCase()));
      return lista;
    });
  }

  Stream<List<MembroUnidade>> streamPorStatus(StatusVinculo status) {
    return stream().map(
      (lista) => lista.where((m) => m.vinculo.status == status).toList(),
    );
  }

  /// Membros aprovados — base para escolher responsável de ministério/evento.
  Stream<List<MembroUnidade>> streamAprovados() =>
      streamPorStatus(StatusVinculo.aprovado);
}
