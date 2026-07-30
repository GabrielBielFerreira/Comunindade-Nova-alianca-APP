/// Modelos de domínio da Bíblia, independentes de qualquer provedor.
class BibleVerse {
  const BibleVerse({required this.numero, required this.texto});

  final int numero;
  final String texto;

  Map<String, dynamic> toJson() => {'n': numero, 't': texto};

  factory BibleVerse.fromJson(Map<String, dynamic> json) => BibleVerse(
        numero: (json['n'] as num).toInt(),
        texto: json['t'] as String? ?? '',
      );
}

class BibleChapter {
  const BibleChapter({
    required this.livroNome,
    required this.livroApiName,
    required this.capitulo,
    required this.versiculos,
  });

  final String livroNome;
  final String livroApiName;
  final int capitulo;
  final List<BibleVerse> versiculos;

  String get referencia => '$livroNome $capitulo';

  Map<String, dynamic> toJson() => {
        'livroNome': livroNome,
        'livroApiName': livroApiName,
        'capitulo': capitulo,
        'versiculos': versiculos.map((v) => v.toJson()).toList(),
      };

  factory BibleChapter.fromJson(Map<String, dynamic> json) => BibleChapter(
        livroNome: json['livroNome'] as String? ?? '',
        livroApiName: json['livroApiName'] as String? ?? '',
        capitulo: (json['capitulo'] as num?)?.toInt() ?? 1,
        versiculos: (json['versiculos'] as List<dynamic>? ?? [])
            .map((e) => BibleVerse.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// Referência a um único versículo (favoritos, palavra do dia).
class BibleVerseRef {
  const BibleVerseRef({
    required this.livroNome,
    required this.livroApiName,
    required this.capitulo,
    required this.versiculo,
  });

  final String livroNome;
  final String livroApiName;
  final int capitulo;
  final int versiculo;

  String get referencia => '$livroNome $capitulo:$versiculo';

  String get chave => '$livroApiName|$capitulo|$versiculo';

  Map<String, dynamic> toJson() => {
        'livroNome': livroNome,
        'livroApiName': livroApiName,
        'capitulo': capitulo,
        'versiculo': versiculo,
      };

  factory BibleVerseRef.fromJson(Map<String, dynamic> json) => BibleVerseRef(
        livroNome: json['livroNome'] as String? ?? '',
        livroApiName: json['livroApiName'] as String? ?? '',
        capitulo: (json['capitulo'] as num?)?.toInt() ?? 1,
        versiculo: (json['versiculo'] as num?)?.toInt() ?? 1,
      );

  @override
  bool operator ==(Object other) =>
      other is BibleVerseRef && other.chave == chave;

  @override
  int get hashCode => chave.hashCode;
}

/// Exceção de domínio da Bíblia (mensagens amigáveis).
class BibleException implements Exception {
  const BibleException(this.mensagem, {this.semConexao = false});
  final String mensagem;
  final bool semConexao;

  @override
  String toString() => mensagem;
}
