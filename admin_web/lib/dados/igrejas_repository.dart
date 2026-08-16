import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../config/ambiente.dart';
import 'conteudo_repository.dart' show lerData;

/// Unidades da rede. Criar e atualizar passam por Cloud Function — as Rules
/// negam escrita direta em `igrejas/{id}` a qualquer cliente.
class IgrejasRepository {
  IgrejasRepository({FirebaseFirestore? db, FirebaseFunctions? functions})
      : _db = db ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(
              region: ConfiguracaoFirebase.regiaoFunctions,
            );

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Stream<List<IgrejaModel>> observar() {
    return _db.collection('igrejas').snapshots().map((snap) {
      final lista = snap.docs
          .map((d) =>
              IgrejaModel.doMapa(id: d.id, dados: d.data(), lerData: lerData))
          .toList();
      lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
      return lista;
    });
  }

  Future<void> criar({required String igrejaId, required String nome}) async {
    await _functions.httpsCallable('criarIgreja').call({
      'igrejaId': igrejaId,
      'nome': nome,
    });
  }

  Future<void> atualizar({
    required IgrejaId igrejaId,
    String? nome,
    bool? ativa,
    Map<String, String?>? dadosInstitucionais,
  }) async {
    // Só envia o que foi realmente informado: o servidor mescla os campos e
    // um `null` acidental apagaria dado institucional já cadastrado.
    final payload = <String, dynamic>{'igrejaId': igrejaId.valor};
    if (nome != null) payload['nome'] = nome;
    if (ativa != null) payload['ativa'] = ativa;
    if (dadosInstitucionais != null) {
      payload['dados_institucionais'] = dadosInstitucionais;
    }

    await _functions.httpsCallable('atualizarIgreja').call(payload);
  }
}
