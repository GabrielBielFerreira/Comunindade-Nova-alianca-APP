import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/core/utils/formatters.dart';

void main() {
  group('Formatters.telefone', () {
    test('formata celular (11 dígitos)', () {
      expect(Formatters.telefone('81999998888'), '(81) 99999-8888');
    });

    test('formata fixo (10 dígitos)', () {
      expect(Formatters.telefone('8133334444'), '(81) 3333-4444');
    });

    test('mantém entrada quando tamanho inesperado', () {
      expect(Formatters.telefone('123'), '123');
    });
  });
}
