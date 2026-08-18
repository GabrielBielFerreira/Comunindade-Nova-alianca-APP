import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import 'conteudo_repository.dart' show lerData;

/// Um registro de `igrejas/{igrejaId}/auditoria`.
///
/// Gravado exclusivamente pelo Admin SDK — as Rules negam create/update/delete
/// a qualquer cliente. Aqui o painel apenas LÊ, e só para liderança
/// ministerial ou `super_admin` (`canReadAudit` nas Rules).
class RegistroAuditoria {
  const RegistroAuditoria({
    required this.id,
    required this.acao,
    required this.autorId,
    this.autorSuperAdmin = false,
    this.alvoId,
    this.motivo,
    this.em,
  });

  final String id;
  final String acao;
  final String autorId;
  final bool autorSuperAdmin;
  final String? alvoId;
  final String? motivo;
  final DateTime? em;

  factory RegistroAuditoria.doMapa(String id, Map<String, dynamic> d) =>
      RegistroAuditoria(
        id: id,
        acao: d['acao'] as String? ?? '',
        autorId: d['autor_id'] as String? ?? '',
        autorSuperAdmin: d['autor_super_admin'] as bool? ?? false,
        alvoId: d['alvo_id'] as String?,
        motivo: d['motivo'] as String?,
        em: lerData(d['em']),
      );

  /// Rótulo legível. Ações desconhecidas caem no valor bruto em vez de sumir:
  /// auditoria não pode esconder o que aconteceu.
  String get rotulo => switch (acao) {
        'aprovar_membro' => 'Membro aprovado',
        'recusar_membro' => 'Cadastro recusado',
        'promover_para_lideranca' => 'Promoção para liderança',
        'remover_da_lideranca' => 'Remoção da liderança',
        'desvincular_da_igreja' => 'Vínculo inativado',
        'transferir_vinculo_igreja' => 'Vínculo transferido entre unidades',
        'atribuir_funcao_admin' => 'Função administrativa atribuída',
        'remover_funcao_admin' => 'Função administrativa removida',
        'criar_igreja' => 'Unidade criada',
        'atualizar_igreja' => 'Unidade atualizada',
        _ => acao.replaceAll('_', ' '),
      };
}

/// Leitura somente-leitura da auditoria da unidade.
class AuditoriaRepository {
  AuditoriaRepository({required this.igrejaId, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final IgrejaId igrejaId;
  final FirebaseFirestore _db;

  /// Últimos registros. `em` é gravado pelo servidor em todo registro, então
  /// ordenar no servidor não esconde nada.
  Stream<List<RegistroAuditoria>> recentes({int limite = 6}) => _db
      .collection('igrejas/${igrejaId.valor}/auditoria')
      .orderBy('em', descending: true)
      .limit(limite)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => RegistroAuditoria.doMapa(d.id, d.data())).toList());
}
