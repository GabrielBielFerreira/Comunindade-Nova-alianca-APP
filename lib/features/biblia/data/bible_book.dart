/// Catálogo dos 66 livros do cânon protestante.
///
/// Contém apenas fatos não sujeitos a direito autoral: nome em português,
/// testamento, número de capítulos e o identificador usado pelo provedor
/// (nome em inglês, aceito pela bible-api.com). O texto bíblico em si é
/// obtido em tempo de execução pelo [BibleRepository].
enum Testamento { antigo, novo }

class BibleBook {
  const BibleBook({
    required this.nome,
    required this.abreviacao,
    required this.apiName,
    required this.capitulos,
    required this.testamento,
  });

  /// Nome em português (exibição).
  final String nome;

  /// Abreviação curta (ex.: "Gn", "Jo").
  final String abreviacao;

  /// Identificador para o provedor (nome em inglês, ex.: "genesis", "1 john").
  final String apiName;

  /// Quantidade de capítulos.
  final int capitulos;

  final Testamento testamento;
}

/// Lista imutável dos 66 livros, em ordem canônica.
const List<BibleBook> kBibliaLivros = [
  // ── Antigo Testamento ────────────────────────────────────────────────
  BibleBook(nome: 'Gênesis', abreviacao: 'Gn', apiName: 'genesis', capitulos: 50, testamento: Testamento.antigo),
  BibleBook(nome: 'Êxodo', abreviacao: 'Êx', apiName: 'exodus', capitulos: 40, testamento: Testamento.antigo),
  BibleBook(nome: 'Levítico', abreviacao: 'Lv', apiName: 'leviticus', capitulos: 27, testamento: Testamento.antigo),
  BibleBook(nome: 'Números', abreviacao: 'Nm', apiName: 'numbers', capitulos: 36, testamento: Testamento.antigo),
  BibleBook(nome: 'Deuteronômio', abreviacao: 'Dt', apiName: 'deuteronomy', capitulos: 34, testamento: Testamento.antigo),
  BibleBook(nome: 'Josué', abreviacao: 'Js', apiName: 'joshua', capitulos: 24, testamento: Testamento.antigo),
  BibleBook(nome: 'Juízes', abreviacao: 'Jz', apiName: 'judges', capitulos: 21, testamento: Testamento.antigo),
  BibleBook(nome: 'Rute', abreviacao: 'Rt', apiName: 'ruth', capitulos: 4, testamento: Testamento.antigo),
  BibleBook(nome: '1 Samuel', abreviacao: '1Sm', apiName: '1 samuel', capitulos: 31, testamento: Testamento.antigo),
  BibleBook(nome: '2 Samuel', abreviacao: '2Sm', apiName: '2 samuel', capitulos: 24, testamento: Testamento.antigo),
  BibleBook(nome: '1 Reis', abreviacao: '1Rs', apiName: '1 kings', capitulos: 22, testamento: Testamento.antigo),
  BibleBook(nome: '2 Reis', abreviacao: '2Rs', apiName: '2 kings', capitulos: 25, testamento: Testamento.antigo),
  BibleBook(nome: '1 Crônicas', abreviacao: '1Cr', apiName: '1 chronicles', capitulos: 29, testamento: Testamento.antigo),
  BibleBook(nome: '2 Crônicas', abreviacao: '2Cr', apiName: '2 chronicles', capitulos: 36, testamento: Testamento.antigo),
  BibleBook(nome: 'Esdras', abreviacao: 'Ed', apiName: 'ezra', capitulos: 10, testamento: Testamento.antigo),
  BibleBook(nome: 'Neemias', abreviacao: 'Ne', apiName: 'nehemiah', capitulos: 13, testamento: Testamento.antigo),
  BibleBook(nome: 'Ester', abreviacao: 'Et', apiName: 'esther', capitulos: 10, testamento: Testamento.antigo),
  BibleBook(nome: 'Jó', abreviacao: 'Jó', apiName: 'job', capitulos: 42, testamento: Testamento.antigo),
  BibleBook(nome: 'Salmos', abreviacao: 'Sl', apiName: 'psalms', capitulos: 150, testamento: Testamento.antigo),
  BibleBook(nome: 'Provérbios', abreviacao: 'Pv', apiName: 'proverbs', capitulos: 31, testamento: Testamento.antigo),
  BibleBook(nome: 'Eclesiastes', abreviacao: 'Ec', apiName: 'ecclesiastes', capitulos: 12, testamento: Testamento.antigo),
  BibleBook(nome: 'Cânticos', abreviacao: 'Ct', apiName: 'song of solomon', capitulos: 8, testamento: Testamento.antigo),
  BibleBook(nome: 'Isaías', abreviacao: 'Is', apiName: 'isaiah', capitulos: 66, testamento: Testamento.antigo),
  BibleBook(nome: 'Jeremias', abreviacao: 'Jr', apiName: 'jeremiah', capitulos: 52, testamento: Testamento.antigo),
  BibleBook(nome: 'Lamentações', abreviacao: 'Lm', apiName: 'lamentations', capitulos: 5, testamento: Testamento.antigo),
  BibleBook(nome: 'Ezequiel', abreviacao: 'Ez', apiName: 'ezekiel', capitulos: 48, testamento: Testamento.antigo),
  BibleBook(nome: 'Daniel', abreviacao: 'Dn', apiName: 'daniel', capitulos: 12, testamento: Testamento.antigo),
  BibleBook(nome: 'Oséias', abreviacao: 'Os', apiName: 'hosea', capitulos: 14, testamento: Testamento.antigo),
  BibleBook(nome: 'Joel', abreviacao: 'Jl', apiName: 'joel', capitulos: 3, testamento: Testamento.antigo),
  BibleBook(nome: 'Amós', abreviacao: 'Am', apiName: 'amos', capitulos: 9, testamento: Testamento.antigo),
  BibleBook(nome: 'Obadias', abreviacao: 'Ob', apiName: 'obadiah', capitulos: 1, testamento: Testamento.antigo),
  BibleBook(nome: 'Jonas', abreviacao: 'Jn', apiName: 'jonah', capitulos: 4, testamento: Testamento.antigo),
  BibleBook(nome: 'Miquéias', abreviacao: 'Mq', apiName: 'micah', capitulos: 7, testamento: Testamento.antigo),
  BibleBook(nome: 'Naum', abreviacao: 'Na', apiName: 'nahum', capitulos: 3, testamento: Testamento.antigo),
  BibleBook(nome: 'Habacuque', abreviacao: 'Hc', apiName: 'habakkuk', capitulos: 3, testamento: Testamento.antigo),
  BibleBook(nome: 'Sofonias', abreviacao: 'Sf', apiName: 'zephaniah', capitulos: 3, testamento: Testamento.antigo),
  BibleBook(nome: 'Ageu', abreviacao: 'Ag', apiName: 'haggai', capitulos: 2, testamento: Testamento.antigo),
  BibleBook(nome: 'Zacarias', abreviacao: 'Zc', apiName: 'zechariah', capitulos: 14, testamento: Testamento.antigo),
  BibleBook(nome: 'Malaquias', abreviacao: 'Ml', apiName: 'malachi', capitulos: 4, testamento: Testamento.antigo),
  // ── Novo Testamento ──────────────────────────────────────────────────
  BibleBook(nome: 'Mateus', abreviacao: 'Mt', apiName: 'matthew', capitulos: 28, testamento: Testamento.novo),
  BibleBook(nome: 'Marcos', abreviacao: 'Mc', apiName: 'mark', capitulos: 16, testamento: Testamento.novo),
  BibleBook(nome: 'Lucas', abreviacao: 'Lc', apiName: 'luke', capitulos: 24, testamento: Testamento.novo),
  BibleBook(nome: 'João', abreviacao: 'Jo', apiName: 'john', capitulos: 21, testamento: Testamento.novo),
  BibleBook(nome: 'Atos', abreviacao: 'At', apiName: 'acts', capitulos: 28, testamento: Testamento.novo),
  BibleBook(nome: 'Romanos', abreviacao: 'Rm', apiName: 'romans', capitulos: 16, testamento: Testamento.novo),
  BibleBook(nome: '1 Coríntios', abreviacao: '1Co', apiName: '1 corinthians', capitulos: 16, testamento: Testamento.novo),
  BibleBook(nome: '2 Coríntios', abreviacao: '2Co', apiName: '2 corinthians', capitulos: 13, testamento: Testamento.novo),
  BibleBook(nome: 'Gálatas', abreviacao: 'Gl', apiName: 'galatians', capitulos: 6, testamento: Testamento.novo),
  BibleBook(nome: 'Efésios', abreviacao: 'Ef', apiName: 'ephesians', capitulos: 6, testamento: Testamento.novo),
  BibleBook(nome: 'Filipenses', abreviacao: 'Fp', apiName: 'philippians', capitulos: 4, testamento: Testamento.novo),
  BibleBook(nome: 'Colossenses', abreviacao: 'Cl', apiName: 'colossians', capitulos: 4, testamento: Testamento.novo),
  BibleBook(nome: '1 Tessalonicenses', abreviacao: '1Ts', apiName: '1 thessalonians', capitulos: 5, testamento: Testamento.novo),
  BibleBook(nome: '2 Tessalonicenses', abreviacao: '2Ts', apiName: '2 thessalonians', capitulos: 3, testamento: Testamento.novo),
  BibleBook(nome: '1 Timóteo', abreviacao: '1Tm', apiName: '1 timothy', capitulos: 6, testamento: Testamento.novo),
  BibleBook(nome: '2 Timóteo', abreviacao: '2Tm', apiName: '2 timothy', capitulos: 4, testamento: Testamento.novo),
  BibleBook(nome: 'Tito', abreviacao: 'Tt', apiName: 'titus', capitulos: 3, testamento: Testamento.novo),
  BibleBook(nome: 'Filemom', abreviacao: 'Fm', apiName: 'philemon', capitulos: 1, testamento: Testamento.novo),
  BibleBook(nome: 'Hebreus', abreviacao: 'Hb', apiName: 'hebrews', capitulos: 13, testamento: Testamento.novo),
  BibleBook(nome: 'Tiago', abreviacao: 'Tg', apiName: 'james', capitulos: 5, testamento: Testamento.novo),
  BibleBook(nome: '1 Pedro', abreviacao: '1Pe', apiName: '1 peter', capitulos: 5, testamento: Testamento.novo),
  BibleBook(nome: '2 Pedro', abreviacao: '2Pe', apiName: '2 peter', capitulos: 3, testamento: Testamento.novo),
  BibleBook(nome: '1 João', abreviacao: '1Jo', apiName: '1 john', capitulos: 5, testamento: Testamento.novo),
  BibleBook(nome: '2 João', abreviacao: '2Jo', apiName: '2 john', capitulos: 1, testamento: Testamento.novo),
  BibleBook(nome: '3 João', abreviacao: '3Jo', apiName: '3 john', capitulos: 1, testamento: Testamento.novo),
  BibleBook(nome: 'Judas', abreviacao: 'Jd', apiName: 'jude', capitulos: 1, testamento: Testamento.novo),
  BibleBook(nome: 'Apocalipse', abreviacao: 'Ap', apiName: 'revelation', capitulos: 22, testamento: Testamento.novo),
];

/// Busca um livro pelo nome em português (case-insensitive), ou null.
BibleBook? livroPorNome(String nome) {
  final alvo = nome.trim().toLowerCase();
  for (final livro in kBibliaLivros) {
    if (livro.nome.toLowerCase() == alvo) return livro;
  }
  return null;
}
