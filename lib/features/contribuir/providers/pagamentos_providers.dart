import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pagamentos_service.dart';

final pagamentosServiceProvider =
    Provider<PagamentosService>((ref) => PagamentosService());
