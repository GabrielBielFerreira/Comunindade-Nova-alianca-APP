import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

DateTime? lerData(dynamic v) =>
    v is Timestamp ? v.toDate() : (v is DateTime ? v : null);

// ══════════════════════════════════════════════════════════════════════
// Modelos do painel
//
// Deliberadamente separados dos modelos do aplicativo: o painel edita
// campos que o app só lê, e acoplar os dois faria uma mudança de UI mexer
// no contrato de dados do app.
// ══════════════════════════════════════════════════════════════════════

class Aviso {
  const Aviso({
    required this.id,
    required this.titulo,
    required this.conteudo,
    this.prioridade = 'normal',
    this.publico = false,
    this.ativo = true,
    this.publicadoEm,
  });

  final String id;
  final String titulo;
  final String conteudo;
  final String prioridade; // normal | urgente
  final bool publico;
  final bool ativo;
  final DateTime? publicadoEm;

  bool get urgente => prioridade == 'urgente';

  factory Aviso.doMapa(String id, Map<String, dynamic> d) => Aviso(
        id: id,
        titulo: d['titulo'] as String? ?? '',
        // `conteudo` é canônico; `corpo` é legado aceito só na leitura.
        conteudo: (d['conteudo'] as String?) ?? (d['corpo'] as String?) ?? '',
        prioridade: d['prioridade'] as String? ?? 'normal',
        publico: d['publico'] as bool? ?? false,
        ativo: d['ativo'] as bool? ?? true,
        publicadoEm: lerData(d['publicado_em']),
      );

  Map<String, dynamic> paraMapa() => {
        'titulo': titulo,
        'conteudo': conteudo, // nunca grava `corpo`
        'prioridade': prioridade,
        'publico': publico,
        'ativo': ativo,
        'publicado_em': publicadoEm ?? FieldValue.serverTimestamp(),
        'atualizado_em': FieldValue.serverTimestamp(),
      };
}

class Evento {
  const Evento({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.data,
    this.local = '',
    this.tipo = 'culto',
    this.publico = true,
    this.cancelado = false,
    this.responsavelId,
    this.responsavelNome,
  });

  final String id;
  final String titulo;
  final String descricao;
  final DateTime data;
  final String local;
  final String tipo;
  final bool publico;
  final bool cancelado;
  final String? responsavelId;
  final String? responsavelNome;

  factory Evento.doMapa(String id, Map<String, dynamic> d) => Evento(
        id: id,
        titulo: d['titulo'] as String? ?? '',
        descricao: d['descricao'] as String? ?? '',
        data: lerData(d['data']) ?? DateTime.now(),
        local: d['local'] as String? ?? '',
        tipo: d['tipo'] as String? ?? 'culto',
        publico: d['publico'] as bool? ?? true,
        cancelado: d['cancelado'] as bool? ?? false,
        responsavelId: d['responsavel_id'] as String?,
        responsavelNome: d['responsavel_nome'] as String?,
      );

  Map<String, dynamic> paraMapa() => {
        'titulo': titulo,
        'descricao': descricao,
        'data': Timestamp.fromDate(data),
        'local': local,
        'tipo': tipo,
        'publico': publico,
        'cancelado': cancelado,
        'responsavel_id': responsavelId,
        'responsavel_nome': responsavelNome,
        'atualizado_em': FieldValue.serverTimestamp(),
      };
}

class Campanha {
  const Campanha({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.dataInicio,
    this.dataFim,
    this.metaCentavos = 0,
    this.status = 'ativa',
    this.publico = true,
  });

  final String id;
  final String titulo;
  final String descricao;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final int metaCentavos;
  final String status; // ativa | encerrada
  final bool publico;

  factory Campanha.doMapa(String id, Map<String, dynamic> d) => Campanha(
        id: id,
        titulo: d['titulo'] as String? ?? '',
        descricao: d['descricao'] as String? ?? '',
        dataInicio: lerData(d['data_inicio']) ?? DateTime.now(),
        dataFim: lerData(d['data_fim']),
        // Meta em centavos, mesmo contrato das transações.
        metaCentavos: (d['meta_centavos'] as num?)?.toInt() ?? 0,
        status: d['status'] as String? ?? 'ativa',
        publico: d['publico'] as bool? ?? true,
      );

  Map<String, dynamic> paraMapa() => {
        'titulo': titulo,
        'descricao': descricao,
        'data_inicio': Timestamp.fromDate(dataInicio),
        'data_fim': dataFim == null ? null : Timestamp.fromDate(dataFim!),
        'meta_centavos': metaCentavos,
        'status': status,
        'publico': publico,
        'atualizado_em': FieldValue.serverTimestamp(),
      };
}

class Ministerio {
  const Ministerio({
    required this.id,
    required this.nome,
    required this.descricao,
    this.ativo = true,
    this.liderId,
    this.liderNome,
    this.publico = true,
  });

  final String id;
  final String nome;
  final String descricao;
  final bool ativo;
  final String? liderId;
  final String? liderNome;
  final bool publico;

  factory Ministerio.doMapa(String id, Map<String, dynamic> d) => Ministerio(
        id: id,
        nome: d['nome'] as String? ?? '',
        descricao: d['descricao'] as String? ?? '',
        ativo: d['ativo'] as bool? ?? true,
        liderId: d['lider_id'] as String?,
        liderNome: d['lider_nome'] as String?,
        publico: d['publico'] as bool? ?? true,
      );

  Map<String, dynamic> paraMapa() => {
        'nome': nome,
        'descricao': descricao,
        'ativo': ativo,
        'lider_id': liderId,
        'lider_nome': liderNome,
        'publico': publico,
        'atualizado_em': FieldValue.serverTimestamp(),
      };
}

class Devocional {
  const Devocional({
    required this.id,
    required this.titulo,
    required this.corpo,
    required this.autor,
    required this.data,
    this.referencia,
    this.destaque = false,
    this.ativo = true,
  });

  final String id;
  final String titulo;
  final String corpo;
  final String autor;
  final DateTime data;
  final String? referencia;
  final bool destaque;
  final bool ativo;

  factory Devocional.doMapa(String id, Map<String, dynamic> d) => Devocional(
        id: id,
        titulo: d['titulo'] as String? ?? '',
        corpo: d['corpo'] as String? ?? '',
        autor: d['autor'] as String? ?? '',
        data: lerData(d['data']) ?? DateTime.now(),
        referencia: d['referencia'] as String?,
        destaque: d['destaque'] as bool? ?? false,
        ativo: d['ativo'] as bool? ?? true,
      );

  Map<String, dynamic> paraMapa() => {
        'titulo': titulo,
        'corpo': corpo,
        'autor': autor,
        'data': Timestamp.fromDate(data),
        'referencia': referencia,
        'destaque': destaque,
        'ativo': ativo,
        'atualizado_em': FieldValue.serverTimestamp(),
      };
}

class PedidoOracao {
  const PedidoOracao({
    required this.id,
    required this.texto,
    required this.autorNome,
    this.anonimo = false,
    this.privado = false,
    this.urgente = false,
    this.aprovado = false,
    this.recusado = false,
    this.motivoRecusa,
    this.criadoEm,
  });

  final String id;
  final String texto;
  final String autorNome;
  final bool anonimo;
  final bool privado;
  final bool urgente;
  final bool aprovado;
  final bool recusado;
  final String? motivoRecusa;
  final DateTime? criadoEm;

  String get nomeExibicao => anonimo ? 'Anônimo' : (autorNome.isEmpty ? '—' : autorNome);

  factory PedidoOracao.doMapa(String id, Map<String, dynamic> d) => PedidoOracao(
        id: id,
        texto: d['texto'] as String? ?? '',
        autorNome: d['autor_nome'] as String? ?? '',
        anonimo: d['anonimo'] as bool? ?? false,
        privado: d['privado'] as bool? ?? false,
        urgente: d['urgente'] as bool? ?? false,
        aprovado: d['aprovado'] as bool? ?? false,
        recusado: d['recusado'] as bool? ?? false,
        motivoRecusa: d['motivo_recusa'] as String?,
        criadoEm: lerData(d['criado_em']),
      );
}

// ══════════════════════════════════════════════════════════════════════
// Repositório
// ══════════════════════════════════════════════════════════════════════

/// CRUD de conteúdo SEMPRE dentro de `igrejas/{igrejaId}/...`.
///
/// Não existe método que receba caminho livre: o `igrejaId` é fixado na
/// construção, então nenhuma tela consegue gravar na unidade errada.
class ConteudoRepository {
  ConteudoRepository({required this.igrejaId, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final IgrejaId igrejaId;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String nome) =>
      _db.collection('igrejas/${igrejaId.valor}/$nome');

  // ── Avisos ──────────────────────────────────────────────────────────
  Stream<List<Aviso>> avisos() => _col('avisos').snapshots().map((s) {
        final l = s.docs.map((d) => Aviso.doMapa(d.id, d.data())).toList();
        l.sort((a, b) => (b.publicadoEm ?? DateTime(0))
            .compareTo(a.publicadoEm ?? DateTime(0)));
        return l;
      });

  Future<void> salvarAviso(Aviso a) => a.id.isEmpty
      ? _col('avisos').add(a.paraMapa())
      : _col('avisos').doc(a.id).update(a.paraMapa());

  /// Publica/despublica. Nunca apaga — o histórico da unidade é preservado.
  Future<void> definirAvisoAtivo(String id, bool ativo) =>
      _col('avisos').doc(id).update({'ativo': ativo});

  // ── Eventos ─────────────────────────────────────────────────────────
  Stream<List<Evento>> eventos() => _col('eventos').snapshots().map((s) {
        final l = s.docs.map((d) => Evento.doMapa(d.id, d.data())).toList();
        l.sort((a, b) => b.data.compareTo(a.data));
        return l;
      });

  Future<void> salvarEvento(Evento e) => e.id.isEmpty
      ? _col('eventos').add(e.paraMapa())
      : _col('eventos').doc(e.id).update(e.paraMapa());

  Future<void> definirEventoCancelado(String id, bool cancelado) =>
      _col('eventos').doc(id).update({'cancelado': cancelado});

  // ── Campanhas ───────────────────────────────────────────────────────
  Stream<List<Campanha>> campanhas() => _col('campanhas').snapshots().map((s) {
        final l = s.docs.map((d) => Campanha.doMapa(d.id, d.data())).toList();
        l.sort((a, b) => b.dataInicio.compareTo(a.dataInicio));
        return l;
      });

  Future<void> salvarCampanha(Campanha c) => c.id.isEmpty
      ? _col('campanhas').add(c.paraMapa())
      : _col('campanhas').doc(c.id).update(c.paraMapa());

  Future<void> definirCampanhaStatus(String id, String status) =>
      _col('campanhas').doc(id).update({'status': status});

  // ── Ministérios ─────────────────────────────────────────────────────
  Stream<List<Ministerio>> ministerios() =>
      _col('ministerios').snapshots().map((s) {
        final l = s.docs.map((d) => Ministerio.doMapa(d.id, d.data())).toList();
        l.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
        return l;
      });

  Future<void> salvarMinisterio(Ministerio m) => m.id.isEmpty
      ? _col('ministerios').add(m.paraMapa())
      : _col('ministerios').doc(m.id).update(m.paraMapa());

  Future<void> definirMinisterioAtivo(String id, bool ativo) =>
      _col('ministerios').doc(id).update({'ativo': ativo});

  // ── Devocionais ─────────────────────────────────────────────────────
  Stream<List<Devocional>> devocionais() =>
      _col('devocionais').snapshots().map((s) {
        final l = s.docs.map((d) => Devocional.doMapa(d.id, d.data())).toList();
        l.sort((a, b) => b.data.compareTo(a.data));
        return l;
      });

  Future<void> salvarDevocional(Devocional d) => d.id.isEmpty
      ? _col('devocionais').add(d.paraMapa())
      : _col('devocionais').doc(d.id).update(d.paraMapa());

  Future<void> definirDevocionalAtivo(String id, bool ativo) =>
      _col('devocionais').doc(id).update({'ativo': ativo});

  // ── Oração ──────────────────────────────────────────────────────────
  /// Fila de moderação: públicos ainda não decididos.
  Stream<List<PedidoOracao>> oracoesPendentes() => _col('pedidos_oracao')
          .where('privado', isEqualTo: false)
          .where('aprovado', isEqualTo: false)
          .snapshots()
          .map((s) {
        final l = s.docs
            .map((d) => PedidoOracao.doMapa(d.id, d.data()))
            .where((p) => !p.recusado)
            .toList();
        l.sort((a, b) => (a.criadoEm ?? DateTime(0))
            .compareTo(b.criadoEm ?? DateTime(0)));
        return l;
      });

  /// Mural: públicos aprovados.
  Stream<List<PedidoOracao>> oracoesAprovadas() => _col('pedidos_oracao')
          .where('privado', isEqualTo: false)
          .where('aprovado', isEqualTo: true)
          .snapshots()
          .map((s) {
        final l = s.docs.map((d) => PedidoOracao.doMapa(d.id, d.data())).toList();
        l.sort((a, b) => (b.criadoEm ?? DateTime(0))
            .compareTo(a.criadoEm ?? DateTime(0)));
        return l;
      });

  Future<void> aprovarOracao(String id, String moderadorUid) =>
      _col('pedidos_oracao').doc(id).update({
        'aprovado': true,
        'recusado': false,
        'moderado_por': moderadorUid,
        'moderado_em': FieldValue.serverTimestamp(),
      });

  /// Recusa por marcação — NUNCA `delete()`. O pedido sai do mural e da fila,
  /// mas continua auditável com motivo e autor da decisão.
  Future<void> recusarOracao(String id, String moderadorUid, String motivo) =>
      _col('pedidos_oracao').doc(id).update({
        'aprovado': false,
        'recusado': true,
        'motivo_recusa': motivo,
        'moderado_por': moderadorUid,
        'moderado_em': FieldValue.serverTimestamp(),
      });
}
