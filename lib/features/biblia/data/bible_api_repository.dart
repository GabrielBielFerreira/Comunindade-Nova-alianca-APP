import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'bible_local_store.dart';
import 'bible_models.dart';
import 'bible_repository.dart';

/// Implementação do [BibleRepository] sobre a bible-api.com (gratuita, sem
/// chave de API), usando a tradução configurada (padrão: Almeida, domínio
/// público). Faz cache local (offline) dos capítulos já acessados.
///
/// Provedor e tradução são configuráveis por --dart-define (ver [AppConfig]),
/// portanto trocar de fonte não exige alterar esta camada nem a UI.
class BibleApiRepository implements BibleRepository {
  BibleApiRepository({
    BibleLocalStore? store,
    http.Client? client,
    String? baseUrl,
    String? translation,
  })  : _store = store ?? BibleLocalStore(),
        _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.bibleApiBaseUrl,
        _translation = translation ?? AppConfig.bibleTranslation;

  final BibleLocalStore _store;
  final http.Client _client;
  final String _baseUrl;
  final String _translation;

  @override
  String get traducao => 'Almeida (domínio público)';

  @override
  bool get suportaBuscaTextual => false;

  Uri _uri(String reference) => Uri.parse(
      '$_baseUrl/${Uri.encodeComponent(reference)}?translation=$_translation');

  @override
  Future<BibleChapter> carregarCapitulo(String livroApiName, int capitulo,
      {String? livroNome}) async {
    // Cache-first: o texto de domínio público não muda, então serve offline.
    final cache = await _store.lerCapituloCache(livroApiName, capitulo);
    if (cache != null) return cache;

    try {
      final resp = await _client
          .get(_uri('$livroApiName $capitulo'))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw const BibleException('Não foi possível carregar o capítulo.');
      }
      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final versos = (data['verses'] as List<dynamic>? ?? [])
          .map((v) => BibleVerse(
                numero: (v['verse'] as num).toInt(),
                texto: (v['text'] as String? ?? '').trim(),
              ))
          .toList();
      if (versos.isEmpty) {
        throw const BibleException('Capítulo não encontrado.');
      }
      final chapter = BibleChapter(
        livroNome: livroNome ?? (data['reference'] as String? ?? livroApiName),
        livroApiName: livroApiName,
        capitulo: capitulo,
        versiculos: versos,
      );
      await _store.salvarCapituloCache(chapter);
      return chapter;
    } on BibleException {
      rethrow;
    } catch (_) {
      throw const BibleException(
        'Sem conexão. Conecte-se à internet para ler este capítulo pela primeira vez.',
        semConexao: true,
      );
    }
  }

  @override
  Future<BibleVerse> carregarVersiculo(BibleVerseRef ref) async {
    // Tenta a partir do capítulo em cache primeiro.
    final cache = await _store.lerCapituloCache(ref.livroApiName, ref.capitulo);
    if (cache != null) {
      for (final v in cache.versiculos) {
        if (v.numero == ref.versiculo) return v;
      }
    }
    try {
      final resp = await _client
          .get(_uri('${ref.livroApiName} ${ref.capitulo}:${ref.versiculo}'))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        throw const BibleException('Não foi possível carregar o versículo.');
      }
      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final versos = data['verses'] as List<dynamic>? ?? [];
      if (versos.isEmpty) {
        throw const BibleException('Versículo não encontrado.');
      }
      return BibleVerse(
        numero: (versos.first['verse'] as num).toInt(),
        texto: (versos.first['text'] as String? ?? '').trim(),
      );
    } on BibleException {
      rethrow;
    } catch (_) {
      throw const BibleException('Sem conexão para carregar o versículo.',
          semConexao: true);
    }
  }

  @override
  Future<List<BibleVerseRef>> buscarTexto(String termo) {
    throw UnsupportedError('Busca textual não suportada por este provedor.');
  }
}
