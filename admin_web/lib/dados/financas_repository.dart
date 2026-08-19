import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import 'conteudo_repository.dart' show Pagina;

/// Filtros do painel financeiro.
class FiltroFinancas {
  const FiltroFinancas({this.inicio, this.fim, this.status, this.tipo});

  final DateTime? inicio;
  final DateTime? fim;
  final StatusTransacao? status;
  final TipoContribuicao? tipo;

  FiltroFinancas copiarCom({
    DateTime? inicio,
    DateTime? fim,
    StatusTransacao? status,
    TipoContribuicao? tipo,
    bool limparInicio = false,
    bool limparFim = false,
    bool limparStatus = false,
    bool limparTipo = false,
  }) {
    return FiltroFinancas(
      inicio: limparInicio ? null : (inicio ?? this.inicio),
      fim: limparFim ? null : (fim ?? this.fim),
      status: limparStatus ? null : (status ?? this.status),
      tipo: limparTipo ? null : (tipo ?? this.tipo),
    );
  }

  bool get vazio => inicio == null && fim == null && status == null && tipo == null;

  /// Aplicado no cliente para dispensar índices compostos nesta fase. O
  /// ISOLAMENTO por igreja não depende disto: ele vem do caminho da coleção
  /// e das Rules.
  bool aceita(Transacao t) {
    final criado = t.criadoEm;
    if (inicio != null && (criado == null || criado.isBefore(inicio!))) return false;
    if (fim != null && (criado == null || criado.isAfter(fim!))) return false;
    if (status != null && t.status != status) return false;
    if (tipo != null && t.tipo != tipo) return false;
    return true;
  }
}

/// Totais financeiros da unidade, calculados no SERVIDOR.
///
/// O dashboard não baixa o histórico de transações só para somar: uma unidade
/// com anos de contribuições tornaria isso caro e lento.
class ResumoFinanceiroUnidade {
  const ResumoFinanceiroUnidade({
    required this.aprovadoCentavos,
    required this.pendenteCentavos,
    required this.quantidade,
  });

  final int aprovadoCentavos;
  final int pendenteCentavos;
  final int quantidade;
}

/// Leitura SOMENTE LEITURA das transações de uma unidade.
///
/// Não existe método de escrita neste repositório, de propósito: o painel
/// jamais aprova, edita valor ou altera status. As Rules também negam
/// qualquer escrita de cliente em `transacoes`.
class FinancasRepository {
  FinancasRepository({FirebaseFirestore? db}) : _dbInjetado = db;

  final FirebaseFirestore? _dbInjetado;

  /// Resolvido sob demanda — ver [MembrosRepository].
  late final FirebaseFirestore _db = _dbInjetado ?? FirebaseFirestore.instance;

  /// Teto da tela de finanças. Os filtros da tela agem dentro desta página; os
  /// TOTAIS do dashboard vêm de [resumo], que agrega no servidor e não depende
  /// deste limite.
  static const int limitePadrao = 500;

  DateTime? _lerData(dynamic valor) =>
      valor is Timestamp ? valor.toDate() : (valor is DateTime ? valor : null);

  CollectionReference<Map<String, dynamic>> _colecao(IgrejaId igrejaId) =>
      _db.collection('igrejas/${igrejaId.valor}/transacoes');

  Stream<Pagina<Transacao>> observar(
    IgrejaId igrejaId, {
    int limite = limitePadrao,
  }) {
    return _colecao(igrejaId).limit(limite + 1).snapshots().map((snap) {
      final truncada = snap.docs.length > limite;
      final docs = truncada ? snap.docs.take(limite) : snap.docs;

      final lista = docs
          .map((doc) => Transacao.doMapa(
                id: doc.id,
                dados: doc.data(),
                lerData: _lerData,
              ))
          .toList()
        ..sort((a, b) {
          final da = a.criadoEm;
          final dbb = b.criadoEm;
          if (da == null && dbb == null) return 0;
          if (da == null) return 1;
          if (dbb == null) return -1;
          return dbb.compareTo(da);
        });

      return Pagina(itens: lista, truncada: truncada);
    });
  }

  /// Soma e contagem agregadas no servidor, por status.
  ///
  /// Usa o contrato canônico `valor_centavos` (secção 16.4 do CLAUDE.md).
  Future<ResumoFinanceiroUnidade> resumo(IgrejaId igrejaId) async {
    final col = _colecao(igrejaId);

    Future<(int soma, int quantidade)> porStatus(StatusTransacao status) async {
      final r = await col
          .where('status', isEqualTo: status.valor)
          .aggregate(sum('valor_centavos'), count())
          .get();
      return ((r.getSum('valor_centavos') ?? 0).round(), r.count ?? 0);
    }

    final (aprovado, qtdAprovado) = await porStatus(StatusTransacao.aprovado);
    final (pendente, qtdPendente) = await porStatus(StatusTransacao.pendente);

    return ResumoFinanceiroUnidade(
      aprovadoCentavos: aprovado,
      pendenteCentavos: pendente,
      quantidade: qtdAprovado + qtdPendente,
    );
  }
}
