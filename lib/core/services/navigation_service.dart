import 'package:flutter/widgets.dart';

/// Chave de navegação global — permite navegar a partir de fora da árvore de
/// widgets (ex.: ao abrir o app por uma notificação push / deep link).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
