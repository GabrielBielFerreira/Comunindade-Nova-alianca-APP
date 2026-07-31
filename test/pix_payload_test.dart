import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/features/contribuir/data/pix_payload.dart';

/// CRC-16/CCITT-FALSE independente (poly 0x1021, init 0xFFFF) para validar o
/// gerador sem depender da sua própria implementação.
String _crc16(String payload) {
  var crc = 0xFFFF;
  for (final b in payload.codeUnits) {
    crc ^= b << 8;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1;
      crc &= 0xFFFF;
    }
  }
  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}

void main() {
  group('PixPayload', () {
    test('CRC-16/CCITT-FALSE tem valor de verificação correto', () {
      // Valor de verificação padrão do algoritmo.
      expect(_crc16('123456789'), '29B1');
    });

    test('gera BR Code com estrutura EMV e CRC válido', () {
      final p = PixPayload.gerar(
        chave: 'cnarecife01@gmail.com',
        valor: 250.0,
        nomeRecebedor: 'Comunidade Nova Aliança',
        cidade: 'Olinda',
      );

      expect(p.startsWith('000201'), isTrue); // Payload Format Indicator
      expect(p.contains('br.gov.bcb.pix'), isTrue);
      expect(p.contains('cnarecife01@gmail.com'), isTrue);
      expect(p.contains('5303986'), isTrue); // moeda BRL
      expect(p.contains('5406250.00'), isTrue); // valor 250.00
      expect(p.contains('5802BR'), isTrue); // país

      // O código termina com '6304' + CRC de 4 dígitos, calculado sobre o resto.
      expect(p.substring(p.length - 8, p.length - 4), '6304');
      final semCrc = p.substring(0, p.length - 4);
      expect(p.substring(p.length - 4), _crc16(semCrc));
    });

    test('sem valor não inclui o campo de valor (54)', () {
      final p = PixPayload.gerar(
        chave: 'chave@igreja.com',
        nomeRecebedor: 'IGREJA',
        cidade: 'OLINDA',
      );
      // Não deve haver campo de valor "5406..." / "54xx" antes do país.
      final antesPais = p.substring(0, p.indexOf('5802BR'));
      expect(antesPais.contains('5406'), isFalse);
      // Mesmo assim o CRC final é consistente.
      final semCrc = p.substring(0, p.length - 4);
      expect(p.substring(p.length - 4), _crc16(semCrc));
    });

    test('nome e cidade são normalizados (sem acento, maiúsculas)', () {
      final p = PixPayload.gerar(
        chave: 'x@y.com',
        valor: 10,
        nomeRecebedor: 'Comunidade Nova Aliança',
        cidade: 'Olinda',
      );
      expect(p.contains('COMUNIDADE NOVA ALIANCA'), isTrue);
      expect(p.contains('OLINDA'), isTrue);
      expect(p.contains('ç'), isFalse);
    });
  });
}
