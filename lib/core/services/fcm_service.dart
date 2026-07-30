import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
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
    // Tratado pela UI — exibe snackbar ou dialog
  }

  static void _onNotificacaoAberta(RemoteMessage mensagem) {
    // Deep link via data payload — tratado pelo router
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
