import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/features/biblia/data/bible_book.dart';

void main() {
  group('Catálogo bíblico', () {
    test('possui 66 livros', () {
      expect(kBibliaLivros.length, 66);
    });

    test('39 no Antigo e 27 no Novo Testamento', () {
      final at = kBibliaLivros
          .where((l) => l.testamento == Testamento.antigo)
          .length;
      final nt =
          kBibliaLivros.where((l) => l.testamento == Testamento.novo).length;
      expect(at, 39);
      expect(nt, 27);
    });

    test('Salmos tem 150 capítulos', () {
      expect(livroPorNome('Salmos')?.capitulos, 150);
    });

    test('livroPorNome é case-insensitive', () {
      expect(livroPorNome('joão')?.apiName, 'john');
    });

    test('nome inexistente retorna null', () {
      expect(livroPorNome('Livro Inexistente'), isNull);
    });
  });
}
