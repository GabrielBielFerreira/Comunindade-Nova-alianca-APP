import 'package:cloud_firestore/cloud_firestore.dart';

import 'pedido_oracao_model.dart';

/// Acesso ao Firestore para pedidos de oração (coleção `pedidos_oracao`).
///
/// A ordenação é feita no cliente para evitar índices compostos. As regras de
/// segurança garantem que pedidos privados só sejam lidos pelo autor/liderança.
class OracaoRepository {
  OracaoRepository({FirebaseFirestore? db})
      : _col = (db ?? FirebaseFirestore.instance).collection('pedidos_oracao');

  final CollectionReference<Map<String, dynamic>> _col;

  /// Mural da comunidade: pedidos públicos (não privados), mais recentes antes.
  Stream<List<PedidoOracaoModel>> streamMural() {
    return _col.where('privado', isEqualTo: false).snapshots().map((snap) {
      final lista =
          snap.docs.map(PedidoOracaoModel.fromFirestore).toList();
      lista.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return lista;
    });
  }

  /// Pedidos do próprio usuário (inclui privados).
  Stream<List<PedidoOracaoModel>> streamMeusPedidos(String uid) {
    return _col.where('autor_id', isEqualTo: uid).snapshots().map((snap) {
      final lista =
          snap.docs.map(PedidoOracaoModel.fromFirestore).toList();
      lista.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
      return lista;
    });
  }

  Future<void> criarPedido({
    required String autorId,
    required String autorNome,
    required String texto,
    required bool privado,
    bool anonimo = false,
    bool urgente = false,
  }) async {
    final pedido = PedidoOracaoModel(
      id: '',
      autorId: autorId,
      autorNome: autorNome,
      texto: texto.trim(),
      privado: privado,
      anonimo: anonimo,
      urgente: urgente,
      status: StatusPedidoOracao.recebido,
      criadoEm: DateTime.now(),
    );
    await _col.add(pedido.toMap());
    // Observação: a NOTIFICAÇÃO push para a equipe de intercessão (pedido
    // urgente) deve ser disparada por Cloud Function no create deste documento
    // (o cliente não tem permissão de escrever em `notificacoes`). O registro
    // urgente (urgente=true) já fica persistido aqui.
  }

  /// Reação "Estou orando" — idempotente por usuário.
  Future<void> estouOrando({
    required String pedidoId,
    required String uid,
    required bool jaOrou,
  }) async {
    if (jaOrou) return;
    await _col.doc(pedidoId).update({
      'oram_count': FieldValue.increment(1),
      'oram_por': FieldValue.arrayUnion([uid]),
    });
  }
}
