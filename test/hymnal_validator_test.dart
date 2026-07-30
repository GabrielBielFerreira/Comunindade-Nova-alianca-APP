import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/features/cantor/data/hino.dart';

void main() {
  group('validarHinario', () {
    test('aceita hinário válido e ordena por número', () {
      final r = validarHinario({
        'hinos': [
          {'numero': 2, 'titulo': 'B', 'estrofes': ['x']},
          {'numero': 1, 'titulo': 'A', 'estrofes': ['y']},
        ],
      });
      expect(r.valido, isTrue);
      expect(r.hinos.first.numero, 1);
      expect(r.hinos.length, 2);
    });

    test('rejeita sem campo hinos', () {
      final r = validarHinario({});
      expect(r.valido, isFalse);
      expect(r.hinos, isEmpty);
    });

    test('ignora hino sem título e reporta erro', () {
      final r = validarHinario({
        'hinos': [
          {'numero': 1, 'estrofes': ['x']},
        ],
      });
      expect(r.hinos, isEmpty);
      expect(r.erros, isNotEmpty);
    });

    test('detecta número duplicado', () {
      final r = validarHinario({
        'hinos': [
          {'numero': 1, 'titulo': 'A', 'estrofes': ['x']},
          {'numero': 1, 'titulo': 'B', 'estrofes': ['y']},
        ],
      });
      expect(r.erros.any((e) => e.contains('duplicado')), isTrue);
    });

    test('rejeita hino sem estrofes', () {
      final r = validarHinario({
        'hinos': [
          {'numero': 1, 'titulo': 'A', 'estrofes': []},
        ],
      });
      expect(r.hinos, isEmpty);
    });
  });
}
