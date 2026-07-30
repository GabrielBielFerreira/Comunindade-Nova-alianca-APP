import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/aviso_model.dart';
import '../data/avisos_repository.dart';

final avisosRepositoryProvider =
    Provider<AvisosRepository>((ref) => AvisosRepository());

final avisosStreamProvider =
    StreamProvider.autoDispose<List<AvisoModel>>((ref) {
  return ref.watch(avisosRepositoryProvider).stream();
});
