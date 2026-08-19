import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../../../core/data/igreja_scope.dart';

/// Resultado do catálogo acompanhado da origem do snapshot.
///
/// Uma lista vazia vinda somente do cache não prova que uma igreja foi
/// desativada no servidor e, portanto, nunca deve apagar a preferência local.
class CatalogoIgrejasAtivas {
  const CatalogoIgrejasAtivas({
    required this.igrejas,
    required this.confirmadoNoServidor,
  });

  final List<IgrejaModel> igrejas;
  final bool confirmadoNoServidor;
}

/// Catálogo de unidades da rede e vínculos do usuário.
///
/// `catalogo_igrejas/{id}` contém somente os dados públicos necessários para
/// listar e exibir unidades antes do login. Já o vínculo em
/// `igrejas/{id}/membros/{uid}` é dado de autorização e exige sessão.
class IgrejasRepository {
  IgrejasRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _catalogo =>
      _db.collection('catalogo_igrejas');

  CollectionReference<Map<String, dynamic>> get _igrejas =>
      _db.collection('igrejas');

  /// Todas as unidades ativas, para a tela de seleção.
  Stream<List<IgrejaModel>> streamAtivas() {
    return _catalogo
        .where('ativa', isEqualTo: true)
        .snapshots()
        .map(_mapearIgrejasAtivas);
  }

  /// Mesma consulta, preservando se o resultado já foi confirmado pelo
  /// servidor. `includeMetadataChanges` permite receber a confirmação mesmo
  /// quando os documentos são idênticos aos que estavam no cache.
  Stream<CatalogoIgrejasAtivas> streamAtivasComMetadados() {
    return _catalogo
        .where('ativa', isEqualTo: true)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snap) => CatalogoIgrejasAtivas(
            igrejas: _mapearIgrejasAtivas(snap),
            confirmadoNoServidor: !snap.metadata.isFromCache,
          ),
        );
  }

  List<IgrejaModel> _mapearIgrejasAtivas(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final lista = snap.docs
        .map(
          (d) => IgrejaModel.doMapa(
            id: d.id,
            dados: d.data(),
            lerData: lerDataFirestore,
          ),
        )
        .toList();
    lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return lista;
  }

  /// Dados públicos mínimos de uma unidade, seguros antes do login.
  Stream<IgrejaModel?> streamIgreja(IgrejaId id) {
    return _catalogo.doc(id.valor).snapshots().map((d) {
      if (!d.exists) return null;
      return IgrejaModel.doMapa(
        id: d.id,
        dados: d.data()!,
        lerData: lerDataFirestore,
      );
    });
  }

  /// Documento operacional completo, permitido pelas Rules somente para um
  /// membro aprovado da própria unidade (ou superadministrador).
  ///
  /// A escolha entre este stream e [streamIgreja] acontece nos providers,
  /// depois que o vínculo daquela unidade foi confirmado. Visitantes nunca
  /// tentam ler o documento privado.
  Stream<IgrejaModel?> streamIgrejaPrivada(IgrejaId id) {
    return _igrejas.doc(id.valor).snapshots().map((d) {
      if (!d.exists) return null;
      return IgrejaModel.doMapa(
        id: d.id,
        dados: d.data()!,
        lerData: (v) => v is Timestamp ? v.toDate() : null,
      );
    });
  }

  Future<IgrejaModel?> buscar(IgrejaId id) async {
    final snap = await _catalogo.doc(id.valor).get();
    if (!snap.exists) return null;
    return IgrejaModel.doMapa(
      id: snap.id,
      dados: snap.data()!,
      lerData: lerDataFirestore,
    );
  }

  /// Vínculo do usuário numa unidade. `null` quando não há vínculo.
  Stream<VinculoIgreja?> streamVinculo(IgrejaId igrejaId, String uid) {
    return _igrejas
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
    await _igrejas.doc(igrejaId.valor).collection('membros').doc(uid).set({
      'perfil': PerfilComunitario.membro.valor,
      'status': StatusVinculo.pendente.valor,
      'funcoes_admin': <String>[],
      'ministerio_ids': <String>[],
      'criado_em': FieldValue.serverTimestamp(),
    });
  }
}
