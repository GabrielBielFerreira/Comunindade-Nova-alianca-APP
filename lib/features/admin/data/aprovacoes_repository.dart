import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/data/usuario_model.dart';

/// Aprovação/recusa de cadastros pendentes (exceção operacional dentro do app).
///
/// As regras de segurança só permitem estas escritas para liderança
/// (isLider). Cada ação: atualiza o usuário, envia uma notificação ao membro
/// e grava um registro de auditoria.
class AprovacoesRepository {
  AprovacoesRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<UsuarioModel>> streamPendentes() {
    return _db
        .collection('usuarios')
        .where('status', isEqualTo: 'pendente')
        .snapshots()
        .map((snap) {
      final lista = snap.docs.map(UsuarioModel.fromFirestore).toList();
      lista.sort((a, b) => a.dataCadastro.compareTo(b.dataCadastro));
      return lista;
    });
  }

  Future<void> aprovar({
    required String uid,
    required String aprovadorUid,
    required String aprovadorNome,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('usuarios').doc(uid), {
      'status': 'aprovado',
      'aprovado_por': aprovadorUid,
      'aprovado_em': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('notificacoes').doc(), {
      'destinatario_id': uid,
      'titulo': 'Cadastro aprovado',
      'corpo':
          'Bem-vindo(a)! Seu acesso à Comunidade Nova Aliança foi liberado.',
      'tipo': 'sistema',
      'lida': false,
      'criado_em': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('auditoria').doc(), {
      'acao': 'aprovar_cadastro',
      'alvo_id': uid,
      'autor_id': aprovadorUid,
      'autor_nome': aprovadorNome,
      'em': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> recusar({
    required String uid,
    required String aprovadorUid,
    required String aprovadorNome,
    String? motivo,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('usuarios').doc(uid), {
      'status': 'inativo',
      'aprovado_por': aprovadorUid,
      'aprovado_em': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('notificacoes').doc(), {
      'destinatario_id': uid,
      'titulo': 'Cadastro não aprovado',
      'corpo': motivo ??
          'Seu cadastro não foi aprovado no momento. Fale com a liderança.',
      'tipo': 'sistema',
      'lida': false,
      'criado_em': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('auditoria').doc(), {
      'acao': 'recusar_cadastro',
      'alvo_id': uid,
      'autor_id': aprovadorUid,
      'autor_nome': aprovadorNome,
      'motivo': motivo,
      'em': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
