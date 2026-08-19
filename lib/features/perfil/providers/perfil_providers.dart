import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/perfil_repository.dart';

final perfilRepositoryProvider = Provider<PerfilRepository>(
  (ref) => PerfilRepository(),
);
