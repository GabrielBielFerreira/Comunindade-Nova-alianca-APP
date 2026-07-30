/// Modelo de um hino do Cantor Cristão. O conteúdo (letra) deve vir de uma
/// fonte AUTORIZADA fornecida pelo responsável — nunca é inventado nem copiado
/// de terceiros sem licença.
class Hino {
  const Hino({
    required this.numero,
    required this.titulo,
    required this.estrofes,
    this.coro,
    this.autoria,
    this.direitos,
  });

  final int numero;
  final String titulo;

  /// Estrofes na ordem oficial.
  final List<String> estrofes;

  /// Coro/refrão, se houver.
  final String? coro;

  final String? autoria;
  final String? direitos;

  factory Hino.fromJson(Map<String, dynamic> json) => Hino(
        numero: (json['numero'] as num).toInt(),
        titulo: (json['titulo'] as String).trim(),
        estrofes: (json['estrofes'] as List<dynamic>)
            .map((e) => e.toString())
            .toList(),
        coro: (json['coro'] as String?)?.trim(),
        autoria: (json['autoria'] as String?)?.trim(),
        direitos: (json['direitos'] as String?)?.trim(),
      );

  Map<String, dynamic> toJson() => {
        'numero': numero,
        'titulo': titulo,
        'estrofes': estrofes,
        if (coro != null) 'coro': coro,
        if (autoria != null) 'autoria': autoria,
        if (direitos != null) 'direitos': direitos,
      };
}

/// Resultado da validação de um arquivo de hinário.
class HymnalValidationResult {
  const HymnalValidationResult(this.hinos, this.erros);
  final List<Hino> hinos;
  final List<String> erros;

  bool get valido => erros.isEmpty && hinos.isNotEmpty;
}

/// Valida e converte o JSON do hinário no formato esperado:
/// {
///   "edicao": "Cantor Cristão — edição autorizada",
///   "direitos": "detentor / licença",
///   "hinos": [
///     {"numero": 1, "titulo": "...", "autoria": "...",
///      "coro": "...", "estrofes": ["estrofe 1", "estrofe 2"]}
///   ]
/// }
HymnalValidationResult validarHinario(Map<String, dynamic> json) {
  final erros = <String>[];
  final hinos = <Hino>[];
  final numerosVistos = <int>{};

  final lista = json['hinos'];
  if (lista is! List) {
    return const HymnalValidationResult([], ['Campo "hinos" ausente ou inválido.']);
  }

  for (var i = 0; i < lista.length; i++) {
    final item = lista[i];
    if (item is! Map) {
      erros.add('Hino na posição $i não é um objeto.');
      continue;
    }
    final map = Map<String, dynamic>.from(item);
    final numero = (map['numero'] as num?)?.toInt();
    final titulo = (map['titulo'] as String?)?.trim();
    final estrofes = map['estrofes'];

    if (numero == null || numero <= 0) {
      erros.add('Hino na posição $i sem número válido.');
      continue;
    }
    if (numerosVistos.contains(numero)) {
      erros.add('Número de hino duplicado: $numero.');
      continue;
    }
    if (titulo == null || titulo.isEmpty) {
      erros.add('Hino $numero sem título.');
      continue;
    }
    if (estrofes is! List || estrofes.isEmpty) {
      erros.add('Hino $numero sem estrofes.');
      continue;
    }
    numerosVistos.add(numero);
    hinos.add(Hino.fromJson(map));
  }

  hinos.sort((a, b) => a.numero.compareTo(b.numero));
  return HymnalValidationResult(hinos, erros);
}
