import 'bible_models.dart';

/// Abstração do provedor de conteúdo bíblico. A interface NÃO depende de nenhuma
/// API específica — implementações podem usar HTTP, assets locais autorizados,
/// etc. Trocar de provedor não deve exigir mudança na camada de UI.
abstract class BibleRepository {
  /// Nome da tradução/versão em uso (ex.: "Almeida (domínio público)").
  String get traducao;

  /// Carrega um capítulo completo. Deve usar cache quando disponível e lançar
  /// [BibleException] com mensagem amigável em caso de falha.
  Future<BibleChapter> carregarCapitulo(String livroApiName, int capitulo,
      {String? livroNome});

  /// Carrega um único versículo (usado por favoritos e Palavra do Dia).
  Future<BibleVerse> carregarVersiculo(BibleVerseRef ref);

  /// Indica se o provedor suporta busca textual (varia por licença/provedor).
  bool get suportaBuscaTextual;

  /// Busca textual (opcional). Lança [UnsupportedError] se não suportada.
  Future<List<BibleVerseRef>> buscarTexto(String termo);
}
