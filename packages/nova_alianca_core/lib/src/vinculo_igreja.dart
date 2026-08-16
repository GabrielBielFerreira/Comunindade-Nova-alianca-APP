import 'funcao_admin.dart';
import 'igreja_id.dart';
import 'perfil_comunitario.dart';
import 'status_vinculo.dart';

/// Vínculo de uma pessoa com uma unidade: o documento
/// `/igrejas/{igrejaId}/membros/{uid}`.
///
/// É a ÚNICA fonte de autorização por unidade. Status, perfil e funções vivem
/// aqui — nunca no documento global `/usuarios/{uid}` — porque autorização é
/// sempre relativa a uma igreja.
class VinculoIgreja {
  const VinculoIgreja({
    required this.uid,
    required this.igrejaId,
    required this.status,
    required this.perfil,
    this.funcoesAdmin = const <FuncaoAdmin>{},
    this.ministerioIds = const <String>[],
    this.aprovadoPor,
    this.aprovadoEm,
    this.atualizadoPor,
    this.atualizadoEm,
  });

  final String uid;
  final IgrejaId igrejaId;
  final StatusVinculo status;
  final PerfilComunitario perfil;
  final Set<FuncaoAdmin> funcoesAdmin;
  final List<String> ministerioIds;
  final String? aprovadoPor;
  final DateTime? aprovadoEm;
  final String? atualizadoPor;
  final DateTime? atualizadoEm;

  /// Reconstrói a partir do mapa cru do Firestore. Tolerante a grafias com
  /// acento e a campos ausentes, sempre caindo no menor privilégio.
  factory VinculoIgreja.doMapa({
    required String uid,
    required IgrejaId igrejaId,
    required Map<String, dynamic> dados,
    DateTime? Function(dynamic)? lerData,
  }) {
    final converterData = lerData ?? _dataPadrao;
    return VinculoIgreja(
      uid: uid,
      igrejaId: igrejaId,
      status: StatusVinculo.deTexto(dados['status'] as String?),
      perfil: PerfilComunitario.deTexto(dados['perfil'] as String?),
      funcoesAdmin: FuncaoAdmin.deLista(dados['funcoes_admin'] as Iterable<dynamic>?),
      ministerioIds: (dados['ministerio_ids'] as Iterable<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      aprovadoPor: dados['aprovado_por'] as String?,
      aprovadoEm: converterData(dados['aprovado_em']),
      atualizadoPor: dados['atualizado_por'] as String?,
      atualizadoEm: converterData(dados['atualizado_em']),
    );
  }

  static DateTime? _dataPadrao(dynamic valor) =>
      valor is DateTime ? valor : null;

  Map<String, dynamic> paraMapa() => {
        'status': status.valor,
        'perfil': perfil.valor,
        'funcoes_admin': FuncaoAdmin.paraLista(funcoesAdmin),
        'ministerio_ids': ministerioIds,
        'aprovado_por': aprovadoPor,
        'aprovado_em': aprovadoEm,
        'atualizado_por': atualizadoPor,
        'atualizado_em': atualizadoEm,
      };

  /// Um vínculo só concede algo quando está aprovado.
  bool get isAtivo => status.isAprovado;

  bool get isLiderancaMinisterial => isAtivo && perfil.isLiderancaMinisterial;

  bool get isPastor => isAtivo && perfil.isPastor;

  bool temFuncao(FuncaoAdmin funcao) => isAtivo && funcoesAdmin.contains(funcao);

  VinculoIgreja copiarCom({
    StatusVinculo? status,
    PerfilComunitario? perfil,
    Set<FuncaoAdmin>? funcoesAdmin,
    String? atualizadoPor,
    DateTime? atualizadoEm,
  }) {
    return VinculoIgreja(
      uid: uid,
      igrejaId: igrejaId,
      status: status ?? this.status,
      perfil: perfil ?? this.perfil,
      funcoesAdmin: funcoesAdmin ?? this.funcoesAdmin,
      ministerioIds: ministerioIds,
      aprovadoPor: aprovadoPor,
      aprovadoEm: aprovadoEm,
      atualizadoPor: atualizadoPor ?? this.atualizadoPor,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
