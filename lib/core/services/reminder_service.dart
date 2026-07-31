import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Lembretes de eventos por **notificação local real** (não simulada). Agenda
/// um aviso antes do evento; a entrega é feita pelo próprio aparelho, sem
/// depender de servidor.
class ReminderService {
  ReminderService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;

  static Future<void> _init() async {
    if (_inicializado) return;
    tzdata.initializeTimeZones();
    try {
      // A comunidade fica em Olinda-PE; usa o fuso local do Brasil.
      tz.setLocalLocation(tz.getLocation('America/Recife'));
    } catch (_) {
      // Mantém UTC se a zona não existir; melhor que falhar.
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
    _inicializado = true;
  }

  static Future<bool> _pedirPermissao() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    var ok = true;
    if (android != null) {
      ok = await android.requestNotificationsPermission() ?? true;
    }
    if (ios != null) {
      ok = await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          true;
    }
    return ok;
  }

  /// Deriva um id estável a partir do identificador do evento.
  static int idDoEvento(String eventoId) => eventoId.hashCode & 0x7fffffff;

  /// Agenda um lembrete ~2h antes do evento (ou na hora, se faltar menos).
  /// Retorna o horário agendado, ou `null` se o evento já passou / sem permissão.
  static Future<DateTime?> agendarEvento({
    required int id,
    required String titulo,
    required DateTime dataEvento,
    String? local,
  }) async {
    await _init();
    if (!await _pedirPermissao()) return null;

    final agora = DateTime.now();
    var quando = dataEvento.subtract(const Duration(hours: 2));
    if (quando.isBefore(agora)) quando = dataEvento;
    if (quando.isBefore(agora)) return null; // evento já ocorreu

    final corpo = (local != null && local.trim().isNotEmpty)
        ? 'Está chegando • $local'
        : 'Está chegando o horário do evento.';

    await _plugin.zonedSchedule(
      id,
      'Lembrete: $titulo',
      corpo,
      tz.TZDateTime.from(quando, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lembretes_eventos',
          'Lembretes de eventos',
          channelDescription: 'Avisos antes dos eventos da programação',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    return quando;
  }

  static Future<void> cancelar(int id) async {
    await _init();
    await _plugin.cancel(id);
  }
}
