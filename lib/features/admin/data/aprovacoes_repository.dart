import 'package:cloud_functions/cloud_functions.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../../../core/config/app_config.dart';

/// Aprovação e recusa de cadastros, via Cloud Functions.
///
/// A versão anterior gravava direto no Firestore (usuário + notificação +
/// auditoria em um batch). Isso não sobrevive à arquitetura multi-igreja:
/// as Rules negam ao cliente escrever `status` de vínculo e criar auditoria,
/// justamente para impedir autopromoção e log forjado. Toda a mutação passou
/// para o servidor, que repete a autorização e grava a auditoria com Admin SDK.
class AprovacoesRepository {
  AprovacoesRepository({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  final FirebaseFunctions _fn;

  Future<void> aprovar({
    required IgrejaId igrejaId,
    required String uid,
  }) async {
    await _fn.httpsCallable('aprovarMembro').call({
      'igrejaId': igrejaId.valor,
      'uid': uid,
    });
  }

  /// Recusa/inativa o vínculo. O motivo é obrigatório no servidor e entra na
  /// auditoria; o documento do vínculo é preservado.
  Future<void> recusar({
    required IgrejaId igrejaId,
    required String uid,
    required String motivo,
  }) async {
    await _fn.httpsCallable('recusarMembro').call({
      'igrejaId': igrejaId.valor,
      'uid': uid,
      'motivo': motivo,
    });
  }
}
