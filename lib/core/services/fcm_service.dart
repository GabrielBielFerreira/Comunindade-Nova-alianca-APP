import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'navigation_service.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // Permissão contextual (chamada após o login, pelo RootGate).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) await _salvarToken(token);

    _messaging.onTokenRefresh.listen(_salvarToken);

    FirebaseMessaging.onMessage.listen(_onMensagemForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificacaoAberta);

    // App aberto a partir de estado terminado por uma notificação.
    final inicial = await _messaging.getInitialMessage();
    if (inicial != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _onNotificacaoAberta(inicial));
    }
  }

  static Future<void> _salvarToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final db = FirebaseFirestore.instance;
    final query = await db
        .collection('tokens_dispositivo')
        .where('perfil_id', isEqualTo: uid)
        .where('token', isEqualTo: token)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      await db.collection('tokens_dispositivo').add({
        'perfil_id': uid,
        'token': token,
        'plataforma': 'android',
        'criado_em': Timestamp.now(),
        'ultimo_uso': Timestamp.now(),
        'ativo': true,
      });
    } else {
      await query.docs.first.reference.update({
        'ultimo_uso': Timestamp.now(),
        'ativo': true,
      });
    }
  }

  static void _onMensagemForeground(RemoteMessage mensagem) {
    // Com o app em primeiro plano, mostra um aviso discreto (sem depender de
    // um pacote de notificações locais). A Central de Notificações persiste o
    // histórico via Firestore.
    final ctx = navigatorKey.currentContext;
    final titulo = mensagem.notification?.title ?? mensagem.data['titulo'];
    if (ctx != null && titulo != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(titulo), behavior: SnackBarBehavior.floating),
      );
    }
  }

  /// Deep link: navega para a rota indicada no payload (`data['rota']`),
  /// se for uma rota conhecida do app.
  static void _onNotificacaoAberta(RemoteMessage mensagem) {
    final rota = mensagem.data['rota'];
    if (rota is String && rota.isNotEmpty) {
      navigatorKey.currentState?.pushNamed(rota);
    }
  }

  static Future<void> desativarToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    final db = FirebaseFirestore.instance;
    final query = await db
        .collection('tokens_dispositivo')
        .where('perfil_id', isEqualTo: uid)
        .where('token', isEqualTo: token)
        .limit(1)
        .get();

    for (final doc in query.docs) {
      await doc.reference.update({'ativo': false});
    }
  }
}
