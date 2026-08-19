import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/data/igreja_scope.dart';
import 'pedido_oracao_model.dart';

/// Pedidos de oração de UMA unidade: `igrejas/{igrejaId}/pedidos_oracao`.
///
/// Ordenação no cliente; filtros de igualdade estáveis vão ao servidor.
class OracaoRepository {
  OracaoRepository(this._scope);

  final IgrejaScope _scope;

  CollectionReference<Map<String, dynamic>> get _col => _scope.pedidosOracao;

  /// Mural: pedidos públicos já aprovados, mais recentes primeiro.
  Stream<List<PedidoOracaoModel>> streamMural() {
    return _col
        .where('privado', isEqualTo: false)
        .where('aprovado', isEqualTo: true)
        .snapshots()
        .map((snap) => _ordenar(snap, decrescente: true));
  }

  /// Fila reservada da equipe: TODOS os pedidos ainda não concluídos.
  ///
  /// O moderador autorizado pelas Rules pode ler públicos e privados. Filtrar
  /// `privado == false` aqui fazia justamente os pedidos pastorais reservados
  /// desaparecerem da única fila que deveria acolhê-los.
  Stream<List<PedidoOracaoModel>> streamPendentesModeracao() {
    return _col.where('aprovado', isEqualTo: false).snapshots().map((snap) {
      final lista = _ordenar(snap, decrescente: false);
      // Recusados continuam no banco (histórico) mas saem da fila.
      return lista.where((p) => !p.recusado).toList();
    });
  }

  Stream<List<PedidoOracaoModel>> streamMeusPedidos(String uid) {
    return _col
        .where('autor_id', isEqualTo: uid)
        .snapshots()
        .map((snap) => _ordenar(snap, decrescente: true));
  }

  List<PedidoOracaoModel> _ordenar(
    QuerySnapshot<Map<String, dynamic>> snap, {
    required bool decrescente,
  }) {
    final lista = snap.docs.map(PedidoOracaoModel.fromFirestore).toList();
    lista.sort(
      (a, b) => decrescente
          ? b.criadoEm.compareTo(a.criadoEm)
          : a.criadoEm.compareTo(b.criadoEm),
    );
    return lista;
  }

  Future<void> aprovarPedido(String id, {required String moderadorUid}) {
    return _col.doc(id).update({
      'aprovado': true,
      'recusado': false,
      'moderado_por': moderadorUid,
      'moderado_em': FieldValue.serverTimestamp(),
    });
  }

  /// Recusa por MARCAÇÃO DE STATUS — nunca `delete()`.
  ///
  /// Apagar o documento destruiria o registro de que alguém pediu oração e de
  /// quem decidiu não publicá-lo. O pedido sai do mural e da fila, mas
  /// continua auditável.
  Future<void> recusarPedido(
    String id, {
    required String moderadorUid,
    required String motivo,
  }) {
    return _col.doc(id).update({
      'aprovado': false,
      'recusado': true,
      'motivo_recusa': motivo,
      'moderado_por': moderadorUid,
      'moderado_em': FieldValue.serverTimestamp(),
    });
  }

  Future<void> criarPedido({
    required String autorId,
    required String autorNome,
    required String texto,
    required bool privado,
    bool anonimo = false,
    bool urgente = false,
    String? categoria,
    bool solicitaVisita = false,
    bool solicitaLigacao = false,
  }) async {
    final pedido = PedidoOracaoModel(
      id: '',
      autorId: autorId,
      autorNome: autorNome,
      texto: texto.trim(),
      privado: privado,
      anonimo: anonimo,
      urgente: urgente,
      categoria: categoria,
      solicitaVisita: solicitaVisita,
      solicitaLigacao: solicitaLigacao,
      status: StatusPedidoOracao.recebido,
      criadoEm: DateTime.now(),
    );
    await _col.add(pedido.toMap());
    // A Function de urgência decide no servidor se o autor é elegível para
    // push. Sessões anônimas permanecem na fila, mas não disparam notificação.
  }

  /// Reação "Estou orando".
  ///
  /// As Rules exigem incremento de exatamente 1 e a inclusão do PRÓPRIO uid,
  /// uma única vez. Por isso a checagem local não é só otimização: enviar um
  /// valor arbitrário faria a gravação ser negada.
  Future<void> estouOrando({
    required String pedidoId,
    required String uid,
    required int oramCountAtual,
    required bool jaOrou,
  }) async {
    if (jaOrou) return;
    await _col.doc(pedidoId).update({
      'oram_count': oramCountAtual + 1,
      'oram_por': FieldValue.arrayUnion([uid]),
    });
  }
}
