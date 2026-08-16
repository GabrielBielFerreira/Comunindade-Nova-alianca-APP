import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

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

/// Leitura SOMENTE LEITURA das transações de uma unidade.
///
/// Não existe método de escrita neste repositório, de propósito: o painel
/// jamais aprova, edita valor ou altera status. As Rules também negam
/// qualquer escrita de cliente em `transacoes`.
class FinancasRepository {
  FinancasRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DateTime? _lerData(dynamic valor) =>
      valor is Timestamp ? valor.toDate() : (valor is DateTime ? valor : null);

  Stream<List<Transacao>> observar(IgrejaId igrejaId) {
    return _db
        .collection('igrejas/${igrejaId.valor}/transacoes')
        .snapshots()
        .map((snap) {
      final lista = snap.docs
          .map((doc) => Transacao.doMapa(
                id: doc.id,
                dados: doc.data(),
                lerData: _lerData,
              ))
          .toList();

      lista.sort((a, b) {
        final da = a.criadoEm;
        final dbb = b.criadoEm;
        if (da == null && dbb == null) return 0;
        if (da == null) return 1;
        if (dbb == null) return -1;
        return dbb.compareTo(da);
      });
      return lista;
    });
  }
}
