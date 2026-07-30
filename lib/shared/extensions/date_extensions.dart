extension DateTimeExt on DateTime {
  bool get isHoje {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isAmanha {
    final amanha = DateTime.now().add(const Duration(days: 1));
    return year == amanha.year && month == amanha.month && day == amanha.day;
  }

  bool get isFuturo => isAfter(DateTime.now());

  bool get isPassado => isBefore(DateTime.now());

  String get diaSemanaPortugues {
    const dias = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    return dias[weekday - 1];
  }
}
