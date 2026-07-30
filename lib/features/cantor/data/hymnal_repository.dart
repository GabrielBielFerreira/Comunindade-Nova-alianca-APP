import 'hino.dart';

/// Abstração da fonte de hinos. Implementações podem ler de asset autorizado,
/// arquivo importado, banco local, etc. A interface não depende do formato.
abstract class HymnalRepository {
  /// Descrição da edição/fonte carregada (para exibir créditos/direitos).
  String get fonte;

  /// Retorna todos os hinos ordenados por número. Lista vazia = sem conteúdo
  /// autorizado disponível ainda (estado vazio honesto).
  Future<List<Hino>> carregarHinos();
}

class HymnalException implements Exception {
  const HymnalException(this.mensagem);
  final String mensagem;
  @override
  String toString() => mensagem;
}
