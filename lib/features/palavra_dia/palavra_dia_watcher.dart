import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'palavra_do_dia.dart';
import 'recife_time.dart';

/// Mantém a Palavra do Dia sempre atualizada, sem depender de nova versão do
/// app: atualiza ao abrir, ao retornar ao app e na virada da meia-noite de
/// Recife. Envolve a árvore de widgets no root (não renderiza UI própria).
class PalavraDiaWatcher extends ConsumerStatefulWidget {
  const PalavraDiaWatcher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PalavraDiaWatcher> createState() => _PalavraDiaWatcherState();
}

class _PalavraDiaWatcherState extends ConsumerState<PalavraDiaWatcher>
    with WidgetsBindingObserver {
  Timer? _timerVirada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _agendarVirada();
  }

  @override
  void dispose() {
    _timerVirada?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sincronizar();
      _agendarVirada();
    }
  }

  void _sincronizar() {
    if (!mounted) return;
    final hoje = RecifeTime.hoje();
    final atual = ref.read(dataHojeProvider);
    final mudouODia =
        hoje.year != atual.year || hoje.month != atual.month || hoje.day != atual.day;
    if (mudouODia) {
      // Muda a data → o palavraDoDiaProvider recalcula automaticamente.
      ref.read(dataHojeProvider.notifier).state = hoje;
    } else {
      // Mesmo dia: revalida (uma publicação especial pode ter começado/expirado).
      ref.invalidate(palavraDoDiaProvider);
    }
  }

  void _agendarVirada() {
    _timerVirada?.cancel();
    _timerVirada = Timer(
      RecifeTime.ateProximaMeiaNoite() + const Duration(seconds: 1),
      () {
        _sincronizar();
        _agendarVirada();
      },
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
