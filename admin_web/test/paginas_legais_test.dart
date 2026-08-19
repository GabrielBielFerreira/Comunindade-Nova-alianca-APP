import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final raizPainel = Directory.current;
  final raizProjeto = raizPainel.parent;

  test('páginas legais públicas existem e identificam o aplicativo', () {
    final expectativas = {
      'privacidade.html': [
        'Política de Privacidade',
        'Comunidade Nova Aliança',
      ],
      'excluir-conta.html': ['Excluir sua conta', 'cnarecife01@gmail.com'],
      'termos.html': ['Termos de Uso', 'Comunidade Nova Aliança'],
    };

    for (final entrada in expectativas.entries) {
      final arquivo = File('${raizPainel.path}/web/${entrada.key}');
      expect(arquivo.existsSync(), isTrue, reason: entrada.key);

      final conteudo = arquivo.readAsStringSync();
      for (final trecho in entrada.value) {
        expect(conteudo, contains(trecho), reason: entrada.key);
      }
    }
  });

  test('Firebase Hosting expõe rotas legais antes do fallback do painel', () {
    final configuracao =
        jsonDecode(File('${raizProjeto.path}/firebase.json').readAsStringSync())
            as Map<String, dynamic>;
    final hostings = configuracao['hosting'] as List<dynamic>;
    final hosting =
        hostings.singleWhere(
              (item) => (item as Map<String, dynamic>)['target'] == 'painel',
            )
            as Map<String, dynamic>;
    final rewrites = hosting['rewrites'] as List<dynamic>;

    expect(rewrites.take(3), [
      {'source': '/privacidade', 'destination': '/privacidade.html'},
      {'source': '/excluir-conta', 'destination': '/excluir-conta.html'},
      {'source': '/termos', 'destination': '/termos.html'},
    ]);
    expect(rewrites.last, {'source': '**', 'destination': '/index.html'});
  });
}
