import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
import 'palavra_do_dia.dart';

bool _urlValida(String u) =>
    u.isNotEmpty && (u.startsWith('http://') || u.startsWith('https://'));

/// Link oficial do app, centralizado: 1) Firestore `configuracoes/app`
/// (`url_oficial`) — permite trocar sem publicar nova versão; 2) `APP_URL`
/// (`--dart-define`); 3) vazio (nunca um link falso/provisório).
final linkOficialProvider = FutureProvider<String>((ref) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('configuracoes')
        .doc('app')
        .get();
    final url = (doc.data()?['url_oficial'] as String? ?? '').trim();
    if (_urlValida(url)) return url;
  } catch (_) {/* usa o dart-define */}
  final env = AppConfig.appOfficialUrl.trim();
  return _urlValida(env) ? env : '';
});

/// Geração da imagem e compartilhamento nativo da Palavra do Dia.
class PalavraDiaShareService {
  const PalavraDiaShareService._();

  static const _prefixoArquivo = 'palavra_dia_share_';

  /// Captura o [RepaintBoundary] identificado por [key] como PNG de alta
  /// resolução (largura nativa do card, tipicamente 1080 px).
  static Future<Uint8List> capturarPng(GlobalKey key) async {
    final obj = key.currentContext?.findRenderObject();
    if (obj is! RenderRepaintBoundary) {
      throw StateError('Card ainda não está pronto para captura.');
    }
    final larguraLogica = obj.size.width;
    // Garante a largura-alvo mesmo se o boundary estiver escalado na tela.
    final pixelRatio =
        larguraLogica > 0 ? (1080.0 / larguraLogica).clamp(1.0, 4.0) : 3.0;
    final image = await obj.toImage(pixelRatio: pixelRatio.toDouble());
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('Falha ao converter a imagem.');
      }
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Monta a legenda curta (referência + chamada + convite + link).
  static String montarLegenda(PalavraDoDia p, String link) {
    final chamada = (p.reflexao?.trim().isNotEmpty ?? false)
        ? p.reflexao!.trim()
        : 'Fortaleça sua fé todos os dias.';
    final linhas = <String>[
      'Palavra do Dia — ${p.referencia}',
      '',
      chamada,
      '',
      'Receba diariamente mensagens, Bíblia, Cantor Cristão, devocionais e '
          'outros conteúdos no Nova Aliança App.',
    ];
    if (link.isNotEmpty) {
      linhas
        ..add('')
        ..add(link);
    }
    return linhas.join('\n');
  }

  /// Grava o PNG num arquivo temporário e abre o compartilhamento nativo,
  /// removendo o arquivo ao final. Também limpa imagens anteriores.
  static Future<void> compartilhar({
    required Uint8List png,
    required String legenda,
  }) async {
    final dir = await getTemporaryDirectory();
    await _limparAntigos(dir);

    final arquivo = File(
      '${dir.path}${Platform.pathSeparator}$_prefixoArquivo'
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await arquivo.writeAsBytes(png, flush: true);

    try {
      await Share.shareXFiles(
        [XFile(arquivo.path, mimeType: 'image/png')],
        text: legenda,
      );
    } finally {
      // Remove o arquivo temporário após o uso.
      try {
        if (await arquivo.exists()) await arquivo.delete();
      } catch (_) {/* limpo na próxima vez, em _limparAntigos */}
    }
  }

  static Future<void> _limparAntigos(Directory dir) async {
    try {
      await for (final ent in dir.list()) {
        if (ent is File &&
            ent.uri.pathSegments.last.startsWith(_prefixoArquivo)) {
          try {
            await ent.delete();
          } catch (_) {/* ignora */}
        }
      }
    } catch (_) {/* ignora */}
  }
}
