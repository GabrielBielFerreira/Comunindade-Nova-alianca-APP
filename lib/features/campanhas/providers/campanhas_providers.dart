import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/campanha_model.dart';
import '../data/campanhas_repository.dart';

final campanhasRepositoryProvider =
    Provider<CampanhasRepository>((ref) => CampanhasRepository());

/// Campanhas ativas (lista vazia = nenhuma campanha publicada ainda).
final campanhasAtivasProvider =
    StreamProvider.autoDispose<List<CampanhaModel>>((ref) {
  return ref.watch(campanhasRepositoryProvider).streamAtivas();
});
