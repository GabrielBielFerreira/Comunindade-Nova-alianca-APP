import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bible_api_repository.dart';
import '../data/bible_local_store.dart';
import '../data/bible_models.dart';
import '../data/bible_repository.dart';

final bibleStoreProvider = Provider<BibleLocalStore>((ref) => BibleLocalStore());

final bibleRepositoryProvider = Provider<BibleRepository>(
  (ref) => BibleApiRepository(store: ref.watch(bibleStoreProvider)),
);

/// Argumento para carregar um capítulo (com igualdade por livro+capítulo).
class CapituloArg {
  const CapituloArg(this.apiName, this.capitulo, this.nome);
  final String apiName;
  final int capitulo;
  final String nome;

  @override
  bool operator ==(Object other) =>
      other is CapituloArg &&
      other.apiName == apiName &&
      other.capitulo == capitulo;

  @override
  int get hashCode => Object.hash(apiName, capitulo);
}

final capituloProvider =
    FutureProvider.autoDispose.family<BibleChapter, CapituloArg>((ref, arg) {
  return ref.read(bibleRepositoryProvider).carregarCapitulo(
        arg.apiName,
        arg.capitulo,
        livroNome: arg.nome,
      );
});

/// Tamanho da fonte de leitura (persistido).
class FontScaleNotifier extends Notifier<double> {
  @override
  double build() {
    _carregar();
    return 1.0;
  }

  Future<void> _carregar() async {
    state = await ref.read(bibleStoreProvider).lerFontScale();
  }

  Future<void> _definir(double valor) async {
    state = valor;
    await ref.read(bibleStoreProvider).salvarFontScale(valor);
  }

  void aumentar() => _definir((state + 0.1).clamp(0.8, 2.0));
  void diminuir() => _definir((state - 0.1).clamp(0.8, 2.0));
}

final fontScaleProvider =
    NotifierProvider<FontScaleNotifier, double>(FontScaleNotifier.new);

/// Favoritos (versículos com texto), persistidos localmente.
class FavoritosNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() {
    return ref.read(bibleStoreProvider).lerFavoritos();
  }

  Future<void> alternar(BibleVerseRef verseRef, String texto) async {
    await ref.read(bibleStoreProvider).alternarFavorito(verseRef, texto);
    state = AsyncData(await ref.read(bibleStoreProvider).lerFavoritos());
  }
}

final favoritosProvider =
    AsyncNotifierProvider<FavoritosNotifier, List<Map<String, dynamic>>>(
        FavoritosNotifier.new);

/// Histórico de capítulos lidos.
final historicoProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(bibleStoreProvider).lerHistorico();
});

/// Último capítulo lido (para "continuar leitura").
final ultimoLidoProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) {
  return ref.read(bibleStoreProvider).lerUltimoLido();
});
