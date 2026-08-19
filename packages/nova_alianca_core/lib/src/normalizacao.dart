/// Normaliza um texto para comparação: minúsculas, sem acentos, sem espaços
/// nas bordas e com espaços internos convertidos em `_`.
///
/// Existe porque documentos gravados manualmente no console do Firestore
/// aparecem como `Líder`, `Diácono`, `moderador de oração` etc. O servidor e o
/// cliente precisam reconhecer todas essas grafias como a mesma chave, senão o
/// usuário vê a interface administrativa mas as regras negam as operações.
String normalizarChave(String valor) {
  const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const semAcento = 'aaaaaeeeeiiiiooooouuuucn';

  final buffer = StringBuffer();
  for (final caractere in valor.toLowerCase().trim().split('')) {
    final indice = comAcento.indexOf(caractere);
    if (indice >= 0) {
      buffer.write(semAcento[indice]);
    } else if (caractere == ' ' || caractere == '-') {
      buffer.write('_');
    } else {
      buffer.write(caractere);
    }
  }
  return buffer.toString();
}
