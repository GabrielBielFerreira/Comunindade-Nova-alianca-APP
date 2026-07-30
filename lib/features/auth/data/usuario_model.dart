import 'package:cloud_firestore/cloud_firestore.dart';

enum PerfilUsuario { pastor, diacono, lider, membro, visitante }

enum StatusUsuario { pendente, aprovado, inativo }

extension PerfilUsuarioExt on PerfilUsuario {
  String get valor => name;

  static PerfilUsuario fromString(String v) =>
      PerfilUsuario.values.firstWhere((e) => e.name == v,
          orElse: () => PerfilUsuario.membro);
}

extension StatusUsuarioExt on StatusUsuario {
  String get valor => name;

  static StatusUsuario fromString(String v) =>
      StatusUsuario.values.firstWhere((e) => e.name == v,
          orElse: () => StatusUsuario.pendente);
}

class QualificacaoUsuario {
  final bool jaVisitou;
  final String tempoFrequencia; // menos_1_mes | 1_a_6_meses | 6_meses_a_1_ano | mais_1_ano
  final String participaGrupo;
  final bool desejaMembresia;

  const QualificacaoUsuario({
    required this.jaVisitou,
    required this.tempoFrequencia,
    required this.participaGrupo,
    required this.desejaMembresia,
  });

  factory QualificacaoUsuario.fromMap(Map<String, dynamic> map) {
    return QualificacaoUsuario(
      jaVisitou: map['ja_visitou'] as bool? ?? false,
      tempoFrequencia: map['tempo_frequencia'] as String? ?? '',
      participaGrupo: map['participa_grupo'] as String? ?? '',
      desejaMembresia: map['deseja_membresia'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'ja_visitou': jaVisitou,
        'tempo_frequencia': tempoFrequencia,
        'participa_grupo': participaGrupo,
        'deseja_membresia': desejaMembresia,
      };
}

class UsuarioModel {
  final String uid;
  final String nome;
  final String email;
  final String telefone;
  final String? fotoUrl;
  final DateTime? dataNascimento;
  final DateTime dataCadastro;
  final DateTime? dataConversao;
  final DateTime? dataBatismo;
  final PerfilUsuario perfil;
  final StatusUsuario status;
  final String? ministerioId;
  final QualificacaoUsuario? qualificacao;
  final String? aprovadoPor;
  final DateTime? aprovadoEm;

  const UsuarioModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.telefone,
    this.fotoUrl,
    this.dataNascimento,
    required this.dataCadastro,
    this.dataConversao,
    this.dataBatismo,
    required this.perfil,
    required this.status,
    this.ministerioId,
    this.qualificacao,
    this.aprovadoPor,
    this.aprovadoEm,
  });

  bool get isAprovado => status == StatusUsuario.aprovado;
  bool get isPendente => status == StatusUsuario.pendente;
  bool get isPastor => perfil == PerfilUsuario.pastor;
  bool get isDiacono =>
      perfil == PerfilUsuario.pastor || perfil == PerfilUsuario.diacono;
  bool get isLider =>
      perfil == PerfilUsuario.pastor ||
      perfil == PerfilUsuario.diacono ||
      perfil == PerfilUsuario.lider;

  String get primeiroNome => nome.split(' ').first;

  factory UsuarioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UsuarioModel.fromMap(doc.id, data);
  }

  factory UsuarioModel.fromMap(String uid, Map<String, dynamic> map) {
    return UsuarioModel(
      uid: uid,
      nome: map['nome'] as String? ?? '',
      email: map['email'] as String? ?? '',
      telefone: map['telefone'] as String? ?? '',
      fotoUrl: map['foto_url'] as String?,
      dataNascimento: (map['data_nascimento'] as Timestamp?)?.toDate(),
      dataCadastro:
          (map['data_cadastro'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataConversao: (map['data_conversao'] as Timestamp?)?.toDate(),
      dataBatismo: (map['data_batismo'] as Timestamp?)?.toDate(),
      perfil: PerfilUsuarioExt.fromString(map['perfil'] as String? ?? 'membro'),
      status: StatusUsuarioExt.fromString(map['status'] as String? ?? 'pendente'),
      ministerioId: map['ministerio_id'] as String?,
      qualificacao: map['qualificacao'] != null
          ? QualificacaoUsuario.fromMap(
              Map<String, dynamic>.from(map['qualificacao'] as Map))
          : null,
      aprovadoPor: map['aprovado_por'] as String?,
      aprovadoEm: (map['aprovado_em'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'foto_url': fotoUrl,
        'data_nascimento':
            dataNascimento != null ? Timestamp.fromDate(dataNascimento!) : null,
        'data_cadastro': Timestamp.fromDate(dataCadastro),
        'data_conversao':
            dataConversao != null ? Timestamp.fromDate(dataConversao!) : null,
        'data_batismo':
            dataBatismo != null ? Timestamp.fromDate(dataBatismo!) : null,
        'perfil': perfil.valor,
        'status': status.valor,
        'ministerio_id': ministerioId,
        'qualificacao': qualificacao?.toMap(),
        'aprovado_por': aprovadoPor,
        'aprovado_em':
            aprovadoEm != null ? Timestamp.fromDate(aprovadoEm!) : null,
      };

  UsuarioModel copyWith({
    String? nome,
    String? telefone,
    String? fotoUrl,
    DateTime? dataNascimento,
    PerfilUsuario? perfil,
    StatusUsuario? status,
    String? ministerioId,
  }) {
    return UsuarioModel(
      uid: uid,
      nome: nome ?? this.nome,
      email: email,
      telefone: telefone ?? this.telefone,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      dataCadastro: dataCadastro,
      dataConversao: dataConversao,
      dataBatismo: dataBatismo,
      perfil: perfil ?? this.perfil,
      status: status ?? this.status,
      ministerioId: ministerioId ?? this.ministerioId,
      qualificacao: qualificacao,
      aprovadoPor: aprovadoPor,
      aprovadoEm: aprovadoEm,
    );
  }
}
