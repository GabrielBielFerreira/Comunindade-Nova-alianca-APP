/// Gerador do "copia e cola" do PIX (BR Code / EMV MPM), padrão do Banco
/// Central. É um PIX **estático e manual**: o app apenas monta o código a
/// partir da chave pública da igreja — nenhum segredo, nenhuma confirmação
/// automática. O recebimento é conferido pela tesouraria.
///
/// Referência: Manual de Padrões para Iniciação do PIX (EMV® MPM).
class PixPayload {
  const PixPayload._();

  /// Monta o payload "copia e cola" para a [chave] PIX informada.
  ///
  /// [valor] em reais (ex.: 250.0). Se `null` ou `<= 0`, gera um código sem
  /// valor definido (o pagador digita o valor no app do banco).
  /// [nomeRecebedor] e [cidade] são normalizados (sem acento, maiúsculas) e
  /// truncados aos limites do padrão (25 e 15 caracteres).
  static String gerar({
    required String chave,
    double? valor,
    required String nomeRecebedor,
    required String cidade,
    String txid = '***',
  }) {
    final nome = _sanitizar(nomeRecebedor, 25);
    final cidadeSan = _sanitizar(cidade, 15);
    final chaveTrim = chave.trim();

    // ID 26 — Merchant Account Information (GUI + chave).
    final mai = _campo('00', 'br.gov.bcb.pix') + _campo('01', chaveTrim);

    // ID 62 — Additional Data Field (txid).
    final txidSan = _sanitizarTxid(txid);
    final adf = _campo('05', txidSan.isEmpty ? '***' : txidSan);

    final buffer = StringBuffer()
      ..write(_campo('00', '01')) // Payload Format Indicator
      ..write(_campo('26', mai)) // Merchant Account Information
      ..write(_campo('52', '0000')) // Merchant Category Code
      ..write(_campo('53', '986')); // Moeda: BRL

    if (valor != null && valor > 0) {
      buffer.write(_campo('54', valor.toStringAsFixed(2)));
    }

    buffer
      ..write(_campo('58', 'BR')) // País
      ..write(_campo('59', nome)) // Nome do recebedor
      ..write(_campo('60', cidadeSan)) // Cidade
      ..write(_campo('62', adf)); // Additional Data Field

    // ID 63 — CRC16 calculado sobre tudo, incluindo "6304".
    final semCrc = '${buffer}6304';
    final crc = _crc16(semCrc);
    return '$semCrc$crc';
  }

  static String _campo(String id, String valor) {
    final tam = valor.length.toString().padLeft(2, '0');
    return '$id$tam$valor';
  }

  /// Remove acentos e caracteres fora do intervalo imprimível ASCII, coloca em
  /// maiúsculas e trunca para [max] caracteres.
  static String _sanitizar(String texto, int max) {
    final semAcento = _removerAcentos(texto).toUpperCase();
    final limpo = semAcento.replaceAll(RegExp(r'[^A-Z0-9 ]'), '').trim();
    return limpo.length <= max ? limpo : limpo.substring(0, max).trim();
  }

  static String _sanitizarTxid(String texto) {
    final limpo =
        _removerAcentos(texto).replaceAll(RegExp(r'[^A-Za-z0-9*]'), '');
    return limpo.length <= 25 ? limpo : limpo.substring(0, 25);
  }

  static String _removerAcentos(String s) {
    const com = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const sem = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
    final buffer = StringBuffer();
    for (final code in s.runes) {
      final ch = String.fromCharCode(code);
      final idx = com.indexOf(ch);
      buffer.write(idx >= 0 ? sem[idx] : ch);
    }
    return buffer.toString();
  }

  /// CRC16-CCITT (polinômio 0x1021, valor inicial 0xFFFF) em HEX maiúsculo,
  /// 4 dígitos — conforme exigido pelo BR Code.
  static String _crc16(String payload) {
    var crc = 0xFFFF;
    for (final byte in payload.codeUnits) {
      crc ^= byte << 8;
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc = crc << 1;
        }
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
