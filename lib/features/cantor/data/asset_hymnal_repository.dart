import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'hino.dart';
import 'hymnal_repository.dart';

/// Carrega o Cantor Cristão de um arquivo JSON AUTORIZADO em
/// `assets/hinos/cantor_cristao.json`. Enquanto o arquivo não for fornecido
/// pelo responsável, retorna lista vazia (estado vazio honesto) — nunca
/// preenche com letras inventadas.
///
/// Formato esperado documentado em [validarHinario].
class AssetHymnalRepository implements HymnalRepository {
  static const String assetPath = 'assets/hinos/cantor_cristao.json';

  List<Hino>? _cache;
  String _fonte = 'Conteúdo autorizado ainda não fornecido';

  @override
  String get fonte => _fonte;

  @override
  Future<List<Hino>> carregarHinos() async {
    if (_cache != null) return _cache!;

    String raw;
    try {
      raw = await rootBundle.loadString(assetPath);
    } catch (_) {
      // Asset ausente → sem conteúdo autorizado ainda.
      _cache = const [];
      return _cache!;
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw const HymnalException('Arquivo de hinário não é um JSON válido.');
    }

    final resultado = validarHinario(json);
    if (resultado.hinos.isEmpty) {
      throw HymnalException(
        'Hinário inválido: ${resultado.erros.take(3).join('; ')}',
      );
    }
    _fonte = json['edicao'] as String? ?? 'Fonte autorizada';
    _cache = resultado.hinos;
    return _cache!;
  }
}
