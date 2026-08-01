import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Data/hora no fuso **America/Recife** (a comunidade fica em Olinda-PE).
///
/// A "Palavra do Dia" muda à meia-noite de Recife, garantindo que todos os
/// usuários vejam o mesmo conteúdo na mesma data, independentemente do fuso do
/// aparelho. O fuso é fixo em UTC-3 (sem horário de verão desde 2019).
class RecifeTime {
  RecifeTime._();

  static tz.Location? _loc;

  static tz.Location get _recife {
    final cached = _loc;
    if (cached != null) return cached;
    tz.Location loc;
    try {
      loc = tz.getLocation('America/Recife');
    } catch (_) {
      // A base de fusos ainda não foi carregada — inicializa e tenta de novo.
      tzdata.initializeTimeZones();
      loc = tz.getLocation('America/Recife');
    }
    _loc = loc;
    return loc;
  }

  /// Agora, no fuso de Recife.
  static tz.TZDateTime agora() => tz.TZDateTime.now(_recife);

  /// Data de hoje (apenas ano/mês/dia) no fuso de Recife.
  static DateTime hoje() {
    final n = agora();
    return DateTime(n.year, n.month, n.day);
  }

  /// Chave de cache estável para uma data (ex.: "2026-03-15").
  static String chaveData(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Tempo restante até a próxima meia-noite de Recife (para agendar a virada
  /// do dia enquanto o app está aberto).
  static Duration ateProximaMeiaNoite() {
    final n = agora();
    final amanha =
        tz.TZDateTime(_recife, n.year, n.month, n.day, 0, 0, 0)
            .add(const Duration(days: 1));
    final restante = amanha.difference(n);
    // Nunca retorna zero/negativo (evita timer em laço).
    return restante <= Duration.zero ? const Duration(minutes: 1) : restante;
  }
}
