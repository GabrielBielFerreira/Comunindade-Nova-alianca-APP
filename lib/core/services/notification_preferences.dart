import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferências de notificação REAIS: persistidas localmente e aplicadas via
/// tópicos do FCM (inscreve/cancela). Substitui os antigos toggles simulados.
///
/// A liderança/servidor envia notificações para os tópicos `transmissoes`,
/// `eventos` e `comunicacoes`; ao desligar um toggle, o aparelho cancela a
/// inscrição no tópico correspondente e deixa de recebê-las.
class NotificationPreferences {
  NotificationPreferences._();

  static const chaveTransmissoes = 'notif_transmissoes';
  static const chaveEventos = 'notif_eventos';
  static const chaveComunicacoes = 'notif_comunicacoes';

  static const _topicos = <String, String>{
    chaveTransmissoes: 'transmissoes',
    chaveEventos: 'eventos',
    chaveComunicacoes: 'comunicacoes',
  };

  /// Lê todas as preferências (padrão: ligado).
  static Future<Map<String, bool>> lerTodas() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final chave in _topicos.keys) chave: prefs.getBool(chave) ?? true,
    };
  }

  /// Salva a preferência e aplica imediatamente no FCM.
  static Future<void> definir(String chave, bool ativo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(chave, ativo);
    await _aplicar(chave, ativo);
  }

  /// Reaplica todas as inscrições (chamar após o login, no init do FCM).
  static Future<void> aplicarTodas() async {
    final valores = await lerTodas();
    for (final entry in valores.entries) {
      await _aplicar(entry.key, entry.value);
    }
  }

  static Future<void> _aplicar(String chave, bool ativo) async {
    final topico = _topicos[chave];
    if (topico == null) return;
    try {
      if (ativo) {
        await FirebaseMessaging.instance.subscribeToTopic(topico);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topico);
      }
    } catch (_) {
      // Falha de rede não deve quebrar a UI; é reaplicado no próximo start.
    }
  }
}
