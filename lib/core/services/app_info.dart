import 'package:package_info_plus/package_info_plus.dart';

/// Versão do app lida da build instalada (nunca hardcoded), para exibir em
/// "Configurações"/"Sobre" de forma que sempre coincida com o APK/AAB.
class AppInfo {
  AppInfo._();

  static String _versao = '';
  static String _build = '';

  /// Ex.: "1.1.3". Vazio até a primeira leitura concluir.
  static String get versao => _versao;

  /// Ex.: "1.1.3 (5)".
  static String get versaoCompleta =>
      _build.isEmpty ? _versao : '$_versao ($_build)';

  static Future<void> carregar() async {
    if (_versao.isNotEmpty) return;
    final info = await PackageInfo.fromPlatform();
    _versao = info.version;
    _build = info.buildNumber;
  }
}
