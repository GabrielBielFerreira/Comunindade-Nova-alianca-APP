import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'bible_models.dart';

/// Persistência local da Bíblia (offline, favoritos, histórico, último capítulo,
/// tamanho da fonte). Usa SharedPreferences — sem armazenar a Bíblia inteira,
/// apenas o que o usuário acessou/marcou.
class BibleLocalStore {
  static const _kChapterPrefix = 'bible_chapter_';
  static const _kFavorites = 'bible_favorites';
  static const _kHistory = 'bible_history';
  static const _kLastRead = 'bible_last_read';
  static const _kFontScale = 'bible_font_scale';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  String _chapterKey(String apiName, int capitulo) =>
      '$_kChapterPrefix${apiName}_$capitulo';

  // ── Cache de capítulos ────────────────────────────────────────────────
  Future<BibleChapter?> lerCapituloCache(String apiName, int capitulo) async {
    final p = await _prefs;
    final raw = p.getString(_chapterKey(apiName, capitulo));
    if (raw == null) return null;
    try {
      return BibleChapter.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> salvarCapituloCache(BibleChapter cap) async {
    final p = await _prefs;
    await p.setString(
        _chapterKey(cap.livroApiName, cap.capitulo), jsonEncode(cap.toJson()));
  }

  // ── Último capítulo lido ──────────────────────────────────────────────
  Future<void> salvarUltimoLido(String apiName, int capitulo, String nome) async {
    final p = await _prefs;
    await p.setString(_kLastRead,
        jsonEncode({'apiName': apiName, 'capitulo': capitulo, 'nome': nome}));
  }

  Future<Map<String, dynamic>?> lerUltimoLido() async {
    final p = await _prefs;
    final raw = p.getString(_kLastRead);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  // ── Histórico de capítulos ────────────────────────────────────────────
  Future<void> registrarHistorico(String apiName, int capitulo, String nome) async {
    final p = await _prefs;
    final lista = p.getStringList(_kHistory) ?? [];
    final entry = jsonEncode({'apiName': apiName, 'capitulo': capitulo, 'nome': nome});
    lista.removeWhere((e) {
      final m = jsonDecode(e) as Map;
      return m['apiName'] == apiName && m['capitulo'] == capitulo;
    });
    lista.insert(0, entry);
    if (lista.length > 50) lista.removeRange(50, lista.length);
    await p.setStringList(_kHistory, lista);
  }

  Future<List<Map<String, dynamic>>> lerHistorico() async {
    final p = await _prefs;
    final lista = p.getStringList(_kHistory) ?? [];
    return lista
        .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
        .toList();
  }

  // ── Favoritos (versículos) ────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> lerFavoritos() async {
    final p = await _prefs;
    final lista = p.getStringList(_kFavorites) ?? [];
    return lista
        .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
        .toList();
  }

  Future<bool> isFavorito(BibleVerseRef ref) async {
    final favs = await lerFavoritos();
    return favs.any((m) =>
        m['livroApiName'] == ref.livroApiName &&
        m['capitulo'] == ref.capitulo &&
        m['versiculo'] == ref.versiculo);
  }

  Future<void> alternarFavorito(BibleVerseRef ref, String texto) async {
    final p = await _prefs;
    final lista = p.getStringList(_kFavorites) ?? [];
    final existe = lista.indexWhere((e) {
      final m = jsonDecode(e) as Map;
      return m['livroApiName'] == ref.livroApiName &&
          m['capitulo'] == ref.capitulo &&
          m['versiculo'] == ref.versiculo;
    });
    if (existe >= 0) {
      lista.removeAt(existe);
    } else {
      final m = ref.toJson()..['texto'] = texto;
      lista.insert(0, jsonEncode(m));
    }
    await p.setStringList(_kFavorites, lista);
  }

  // ── Tamanho da fonte ──────────────────────────────────────────────────
  Future<double> lerFontScale() async {
    final p = await _prefs;
    return p.getDouble(_kFontScale) ?? 1.0;
  }

  Future<void> salvarFontScale(double valor) async {
    final p = await _prefs;
    await p.setDouble(_kFontScale, valor);
  }
}
