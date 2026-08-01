import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/features/biblia/data/bible_book.dart';
import 'package:nova_alianca_app/features/palavra_dia/palavra_dia_calendario.dart';

void main() {
  group('PalavraDiaCalendario', () {
    test('possui exatamente 366 conteúdos', () {
      expect(PalavraDiaCalendario.todas().length, 366);
    });

    test('não repete referências no ciclo anual', () {
      final refs =
          PalavraDiaCalendario.todas().map((r) => r.referencia).toList();
      expect(refs.toSet().length, refs.length);
    });

    test('índice do dia usa disposição de ano bissexto (trata 29/02)', () {
      expect(PalavraDiaCalendario.indiceDoDia(DateTime(2024, 1, 1)), 0);
      // 29/02 (ano bissexto) → índice 59, sem sobrepor 01/03.
      expect(PalavraDiaCalendario.indiceDoDia(DateTime(2024, 2, 29)), 59);
      expect(PalavraDiaCalendario.indiceDoDia(DateTime(2024, 3, 1)), 60);
      expect(PalavraDiaCalendario.indiceDoDia(DateTime(2024, 12, 31)), 365);
    });

    test('29/02 tem conteúdo próprio e distinto de 01/03', () {
      final feb29 = PalavraDiaCalendario.paraData(DateTime(2024, 2, 29));
      final mar1 = PalavraDiaCalendario.paraData(DateTime(2024, 3, 1));
      expect(feb29.referencia, isNotEmpty);
      expect(feb29.referencia, isNot(mar1.referencia));
    });

    test('mesma data → mesmo conteúdo (determinístico para todos)', () {
      final a = PalavraDiaCalendario.paraData(DateTime(2026, 5, 10));
      final b = PalavraDiaCalendario.paraData(DateTime(2026, 5, 10));
      expect(a.referencia, b.referencia);
    });

    test('dois dias consecutivos → conteúdos diferentes (troca diária)', () {
      final d1 = PalavraDiaCalendario.paraData(DateTime(2026, 6, 1));
      final d2 = PalavraDiaCalendario.paraData(DateTime(2026, 6, 2));
      expect(d1.referencia, isNot(d2.referencia));
    });

    test('todas as referências têm capítulo e versículo válidos (>=1)', () {
      for (final r in PalavraDiaCalendario.todas()) {
        expect(r.capitulo, greaterThanOrEqualTo(1), reason: r.referencia);
        expect(r.versiculo, greaterThanOrEqualTo(1), reason: r.referencia);
        expect(r.livro.trim(), isNotEmpty);
      }
    });

    test('toda referência aponta para um livro do cânon e capítulo existente',
        () {
      for (final r in PalavraDiaCalendario.todas()) {
        final livro = livroPorNome(r.livro);
        expect(livro, isNotNull,
            reason: 'Livro inexistente no cânon: "${r.livro}"');
        expect(r.capitulo, lessThanOrEqualTo(livro!.capitulos),
            reason:
                '${r.referencia} excede ${livro.capitulos} capítulos de ${livro.nome}');
      }
    });
  });
}
