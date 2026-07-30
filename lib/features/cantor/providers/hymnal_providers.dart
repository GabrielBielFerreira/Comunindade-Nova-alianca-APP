import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/asset_hymnal_repository.dart';
import '../data/hino.dart';
import '../data/hymnal_local_store.dart';
import '../data/hymnal_repository.dart';

final hymnalStoreProvider =
    Provider<HymnalLocalStore>((ref) => HymnalLocalStore());

final hymnalRepositoryProvider =
    Provider<HymnalRepository>((ref) => AssetHymnalRepository());

/// Todos os hinos (lista vazia = conteúdo autorizado ainda não fornecido).
final hinosProvider = FutureProvider<List<Hino>>((ref) {
  return ref.read(hymnalRepositoryProvider).carregarHinos();
});

/// Fonte/edição carregada (créditos).
final hinarioFonteProvider = Provider<String>(
  (ref) => ref.read(hymnalRepositoryProvider).fonte,
);

/// Tamanho da fonte de leitura (persistido).
class HymnalFontScaleNotifier extends Notifier<double> {
  @override
  double build() {
    _carregar();
    return 1.0;
  }

  Future<void> _carregar() async {
    state = await ref.read(hymnalStoreProvider).lerFontScale();
  }

  Future<void> _definir(double valor) async {
    state = valor;
    await ref.read(hymnalStoreProvider).salvarFontScale(valor);
  }

  void aumentar() => _definir((state + 0.1).clamp(0.8, 2.0));
  void diminuir() => _definir((state - 0.1).clamp(0.8, 2.0));
}

final hymnalFontScaleProvider =
    NotifierProvider<HymnalFontScaleNotifier, double>(
        HymnalFontScaleNotifier.new);

/// Favoritos (números de hinos).
class HinosFavoritosNotifier extends AsyncNotifier<List<int>> {
  @override
  Future<List<int>> build() => ref.read(hymnalStoreProvider).lerFavoritos();

  Future<void> alternar(int numero) async {
    await ref.read(hymnalStoreProvider).alternarFavorito(numero);
    state = AsyncData(await ref.read(hymnalStoreProvider).lerFavoritos());
  }
}

final hinosFavoritosProvider =
    AsyncNotifierProvider<HinosFavoritosNotifier, List<int>>(
        HinosFavoritosNotifier.new);

final hinosHistoricoProvider = FutureProvider.autoDispose<List<int>>((ref) {
  return ref.read(hymnalStoreProvider).lerHistorico();
});
