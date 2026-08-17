import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../config/ambiente.dart';
import 'conteudo_repository.dart' show lerData;

/// Unidades da rede. Criar e atualizar passam por Cloud Function — as Rules
/// negam escrita direta em `igrejas/{id}` a qualquer cliente.
class IgrejasRepository {
  IgrejasRepository({FirebaseFirestore? db, FirebaseFunctions? functions})
      : _dbInjetado = db,
        _functionsInjetado = functions;

  final FirebaseFirestore? _dbInjetado;
  final FirebaseFunctions? _functionsInjetado;

  /// Resolvidos sob demanda — ver [MembrosRepository].
  late final FirebaseFirestore _db = _dbInjetado ?? FirebaseFirestore.instance;
  late final FirebaseFunctions _functions = _functionsInjetado ??
      FirebaseFunctions.instanceFor(
        region: ConfiguracaoFirebase.regiaoFunctions,
      );

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

  /// Uma unidade. `/igrejas/{id}` tem leitura pública nas Rules (o aplicativo
  /// precisa listar unidades antes do login), então qualquer usuário do painel
  /// consegue ler a configuração da unidade que administra.
  Stream<IgrejaModel?> observarUma(IgrejaId igrejaId) {
    return _db.doc('igrejas/${igrejaId.valor}').snapshots().map((d) {
      final dados = d.data();
      if (!d.exists || dados == null) return null;
      return IgrejaModel.doMapa(id: d.id, dados: dados, lerData: lerData);
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
