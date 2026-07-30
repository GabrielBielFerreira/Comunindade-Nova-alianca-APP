import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../biblia/data/bible_book.dart';
import '../biblia/data/bible_models.dart';
import '../biblia/providers/bible_providers.dart';

/// Palavra do Dia (versículo edificante) — mesma fonte na Home e em Oração.
class PalavraDoDia {
  const PalavraDoDia({required this.texto, required this.referencia});
  final String texto;
  final String referencia;

  Map<String, dynamic> toJson() => {'texto': texto, 'referencia': referencia};
  factory PalavraDoDia.fromJson(Map<String, dynamic> j) =>
      PalavraDoDia(texto: j['texto'] as String? ?? '', referencia: j['referencia'] as String? ?? '');
}

/// Referências (apenas referência — o texto vem da Bíblia configurada).
const List<(String, int, int)> _referencias = [
  ('Salmos', 23, 1),
  ('Filipenses', 4, 13),
  ('João', 3, 16),
  ('Provérbios', 3, 5),
  ('Isaías', 41, 10),
  ('Josué', 1, 9),
  ('Salmos', 46, 1),
  ('Mateus', 6, 33),
  ('Romanos', 8, 28),
  ('Salmos', 37, 5),
  ('Jeremias', 29, 11),
  ('2 Coríntios', 12, 9),
  ('Salmos', 91, 1),
  ('Hebreus', 11, 1),
  ('Gálatas', 5, 22),
  ('Salmos', 121, 1),
  ('Mateus', 11, 28),
  ('Provérbios', 16, 3),
  ('Salmos', 118, 24),
  ('1 Coríntios', 13, 4),
];

int _diaDoAno() {
  final agora = DateTime.now();
  return agora.difference(DateTime(agora.year)).inDays;
}

const _kCache = 'palavra_do_dia_cache';

/// Palavra do Dia: prioriza um override no Firebase
/// (`configuracoes/palavra_do_dia`); senão, escolhe deterministicamente por
/// data. Faz cache local para funcionar offline.
final palavraDoDiaProvider =
    FutureProvider.autoDispose<PalavraDoDia>((ref) async {
  final prefs = await SharedPreferences.getInstance();

  // 1) Override configurável pela liderança.
  try {
    final doc = await FirebaseFirestore.instance
        .collection('configuracoes')
        .doc('palavra_do_dia')
        .get();
    final d = doc.data();
    final texto = d?['texto'] as String?;
    if (d != null && texto != null && texto.isNotEmpty) {
      final p = PalavraDoDia(texto: texto, referencia: d['referencia'] as String? ?? '');
      await prefs.setString(_kCache, jsonEncode(p.toJson()));
      return p;
    }
  } catch (_) {/* segue para o determinístico */}

  // 2) Determinístico por data, buscando o texto na Bíblia.
  final r = _referencias[_diaDoAno() % _referencias.length];
  final livro = livroPorNome(r.$1);
  try {
    if (livro != null) {
      final v = await ref.read(bibleRepositoryProvider).carregarVersiculo(
            BibleVerseRef(
              livroNome: livro.nome,
              livroApiName: livro.apiName,
              capitulo: r.$2,
              versiculo: r.$3,
            ),
          );
      final p = PalavraDoDia(texto: v.texto, referencia: '${livro.nome} ${r.$2}:${r.$3}');
      await prefs.setString(_kCache, jsonEncode(p.toJson()));
      return p;
    }
  } catch (_) {/* usa cache */}

  // 3) Offline: último conteúdo salvo.
  final raw = prefs.getString(_kCache);
  if (raw != null) {
    return PalavraDoDia.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }
  return const PalavraDoDia(
      texto: 'O Senhor é o meu pastor; nada me faltará.',
      referencia: 'Salmos 23:1');
});
