import 'dart:io';

import 'package:flutter/foundation.dart';

/// Notifier global para a foto de perfil selecionada localmente.
///
/// Protótipo visual, sem backend: a foto vive apenas enquanto o app estiver
/// aberto. Permite que a foto escolhida em "Dados pessoais" apareça no
/// `_ProfileHero` da tela de Perfil.
final profilePhotoNotifier = ValueNotifier<File?>(null);
