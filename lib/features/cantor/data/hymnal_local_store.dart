import 'package:shared_preferences/shared_preferences.dart';

/// Persistência local do Cantor Cristão: favoritos, histórico e tamanho de
/// fonte. Guarda apenas números de hinos (o conteúdo vem do repositório).
class HymnalLocalStore {
  static const _kFavorites = 'hymnal_favorites';
  static const _kHistory = 'hymnal_history';
  static const _kFontScale = 'hymnal_font_scale';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<int>> lerFavoritos() async {
    final p = await _prefs;
    return (p.getStringList(_kFavorites) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
  }

  Future<bool> isFavorito(int numero) async {
    final favs = await lerFavoritos();
    return favs.contains(numero);
  }

  Future<void> alternarFavorito(int numero) async {
    final p = await _prefs;
    final favs = (p.getStringList(_kFavorites) ?? []);
    if (favs.contains('$numero')) {
      favs.remove('$numero');
    } else {
      favs.insert(0, '$numero');
    }
    await p.setStringList(_kFavorites, favs);
  }

  Future<List<int>> lerHistorico() async {
    final p = await _prefs;
    return (p.getStringList(_kHistory) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
  }

  Future<void> registrarHistorico(int numero) async {
    final p = await _prefs;
    final hist = (p.getStringList(_kHistory) ?? []);
    hist.remove('$numero');
    hist.insert(0, '$numero');
    if (hist.length > 50) hist.removeRange(50, hist.length);
    await p.setStringList(_kHistory, hist);
  }

  Future<double> lerFontScale() async {
    final p = await _prefs;
    return p.getDouble(_kFontScale) ?? 1.0;
  }

  Future<void> salvarFontScale(double valor) async {
    final p = await _prefs;
    await p.setDouble(_kFontScale, valor);
  }
}
