import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _data = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _dataHora = DateFormat('dd/MM/yyyy • HH:mm', 'pt_BR');
  static final _hora = DateFormat('HH:mm', 'pt_BR');
  static final _mes = DateFormat('MMMM yyyy', 'pt_BR');
  static final _diaSemana = DateFormat('EEEE', 'pt_BR');

  static String moeda(double valor) => _moeda.format(valor);

  static String moedaCentavos(int centavos) => _moeda.format(centavos / 100);

  static String data(DateTime dt) => _data.format(dt);

  static String dataHora(DateTime dt) => _dataHora.format(dt);

  static String hora(DateTime dt) => _hora.format(dt);

  static String mes(DateTime dt) => _mes.format(dt);

  static String diaSemana(DateTime dt) => _diaSemana.format(dt);

  static String dataRelativa(DateTime dt) {
    final agora = DateTime.now();
    final diff = agora.difference(dt);

    if (diff.inMinutes < 1) return 'agora mesmo';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';
    return _data.format(dt);
  }

  static String telefone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return raw;
  }
}
