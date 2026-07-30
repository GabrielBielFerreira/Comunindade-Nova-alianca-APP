import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoCelula { jovens, adultos, mulheres, homens, idosos, mista }

enum DiaSemana { domingo, segunda, terca, quarta, quinta, sexta, sabado }

class CelulaModel {
  final String id;
  final String nome;
  final TipoCelula tipo;
  final String liderId;
  final DiaSemana diaSemana;
  final String horario;
  final String endereco;
  final bool ativa;
  final int membrosCount;

  const CelulaModel({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.liderId,
    required this.diaSemana,
    required this.horario,
    required this.endereco,
    required this.ativa,
    required this.membrosCount,
  });

  factory CelulaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CelulaModel(
      id: doc.id,
      nome: data['nome'] as String? ?? '',
      tipo: TipoCelula.values.firstWhere(
        (e) => e.name == (data['tipo'] as String? ?? 'mista'),
        orElse: () => TipoCelula.mista,
      ),
      liderId: data['lider_id'] as String? ?? '',
      diaSemana: DiaSemana.values.firstWhere(
        (e) => e.name == (data['dia_semana'] as String? ?? 'domingo'),
        orElse: () => DiaSemana.domingo,
      ),
      horario: data['horario'] as String? ?? '',
      endereco: data['endereco'] as String? ?? '',
      ativa: data['ativa'] as bool? ?? true,
      membrosCount: data['membros_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'tipo': tipo.name,
        'lider_id': liderId,
        'dia_semana': diaSemana.name,
        'horario': horario,
        'endereco': endereco,
        'ativa': ativa,
        'membros_count': membrosCount,
      };
}

class ReuniaoModel {
  final String id;
  final DateTime data;
  final String tema;
  final String observacoes;
  final List<String> presentes;
  final List<String> ausentes;
  final String registradaPor;

  const ReuniaoModel({
    required this.id,
    required this.data,
    required this.tema,
    required this.observacoes,
    required this.presentes,
    required this.ausentes,
    required this.registradaPor,
  });

  factory ReuniaoModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReuniaoModel(
      id: doc.id,
      data: (d['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tema: d['tema'] as String? ?? '',
      observacoes: d['observacoes'] as String? ?? '',
      presentes: List<String>.from(d['presentes'] as List? ?? []),
      ausentes: List<String>.from(d['ausentes'] as List? ?? []),
      registradaPor: d['registrada_por'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'data': Timestamp.fromDate(data),
        'tema': tema,
        'observacoes': observacoes,
        'presentes': presentes,
        'ausentes': ausentes,
        'registrada_por': registradaPor,
      };
}
