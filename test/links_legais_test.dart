import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/core/config/app_config.dart';

void main() {
  test('links legais padrão são públicos e usam HTTPS', () {
    expect(
      AppConfig.politicaPrivacidadeUrl,
      'https://nova-alianca-app.web.app/privacidade',
    );
    expect(
      AppConfig.exclusaoContaUrl,
      'https://nova-alianca-app.web.app/excluir-conta',
    );
    expect(AppConfig.termosUsoUrl, 'https://nova-alianca-app.web.app/termos');

    for (final endereco in [
      AppConfig.politicaPrivacidadeUrl,
      AppConfig.exclusaoContaUrl,
      AppConfig.termosUsoUrl,
    ]) {
      expect(Uri.parse(endereco).scheme, 'https');
    }
  });
}
