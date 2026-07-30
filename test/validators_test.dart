import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejeita vazio', () => expect(Validators.email(''), isNotNull));
    test('rejeita inválido', () => expect(Validators.email('abc'), isNotNull));
    test('aceita válido', () {
      expect(Validators.email('pessoa@cna.app'), isNull);
    });
  });

  group('Validators.senha', () {
    test('rejeita curta', () => expect(Validators.senha('123'), isNotNull));
    test('aceita 6+', () => expect(Validators.senha('123456'), isNull));
  });

  group('Validators.confirmarSenha', () {
    test('divergente', () {
      expect(Validators.confirmarSenha('a', 'b'), isNotNull);
    });
    test('igual', () {
      expect(Validators.confirmarSenha('123456', '123456'), isNull);
    });
  });

  group('Validators.nome', () {
    test('exige sobrenome', () => expect(Validators.nome('Ana'), isNotNull));
    test('aceita completo', () => expect(Validators.nome('Ana Maria'), isNull));
  });

  group('Validators.telefone', () {
    test('rejeita curto', () => expect(Validators.telefone('123'), isNotNull));
    test('aceita 11 dígitos', () {
      expect(Validators.telefone('(81) 99999-9999'), isNull);
    });
  });

  group('Validators.valor', () {
    test('rejeita zero', () => expect(Validators.valor('0'), isNotNull));
    test('aceita positivo formatado', () {
      expect(Validators.valor('R\$ 50,00'), isNull);
    });
  });
}
