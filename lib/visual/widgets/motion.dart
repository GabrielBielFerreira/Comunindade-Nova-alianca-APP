import 'dart:async';

import 'package:flutter/material.dart';

/// Entrada suave (fade + leve deslize para cima) usada para dar vida ao
/// conteúdo sem redesenhar as telas. Respeita a preferência de "reduzir
/// movimento" do sistema (mostra o conteúdo direto, sem animar).
///
/// Use [delay] para escalonar itens de uma lista/seção.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offsetY = 14,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  /// Constrói uma lista de filhos já com o escalonamento aplicado.
  static List<Widget> stagger(
    List<Widget> children, {
    Duration step = const Duration(milliseconds: 70),
    Duration base = Duration.zero,
    Duration maxDelay = const Duration(milliseconds: 500),
  }) {
    return [
      for (var i = 0; i < children.length; i++)
        FadeSlideIn(
          delay: Duration(
            milliseconds: (base.inMilliseconds + step.inMilliseconds * i)
                .clamp(0, maxDelay.inMilliseconds),
          ),
          child: children[i],
        ),
    ];
  }

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final reduzir = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduzir) {
      _controller.value = 1.0;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        return Opacity(
          opacity: _curve.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _curve.value) * widget.offsetY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Barra de progresso que anima de 0 até [value] ao aparecer (usada nas
/// campanhas). Dá a sensação de "preenchimento" sem lógica de controller.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    required this.minHeight,
    this.background = const Color(0xFFE5E2E1),
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final Color color;
  final double minHeight;
  final Color background;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: v,
          minHeight: minHeight,
          backgroundColor: background,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

/// Transição de página calma e consistente em todo o app: a tela que entra
/// aparece com fade + um leve deslize para cima; a que sai recua suavemente.
/// Substitui as transições padrão (que variam por plataforma) por uma única
/// identidade de movimento.
class CalmPageTransitionsBuilder extends PageTransitionsBuilder {
  const CalmPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final entra = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final sai = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: entra,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(entra),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0, -0.012),
          ).animate(sai),
          child: child,
        ),
      ),
    );
  }
}
