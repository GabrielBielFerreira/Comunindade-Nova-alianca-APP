class ProgramacaoAssets {
  const ProgramacaoAssets._();

  static const back = 'assets/images/figma/programacao/programacao_back.svg';
  static const calendar =
      'assets/images/figma/programacao/programacao_calendar.svg';
  static const weekLeft =
      'assets/images/figma/programacao/programacao_week_left.svg';
  static const weekRight =
      'assets/images/figma/programacao/programacao_week_right.svg';
  static const time = 'assets/images/figma/programacao/programacao_time.svg';
  static const location =
      'assets/images/figma/programacao/programacao_location.svg';
  static const empty = 'assets/images/figma/programacao/programacao_empty.svg';
  static const detailsBack = 'assets/images/figma/programacao/details_back.svg';
  static const detailsCast = 'assets/images/figma/programacao/details_cast.svg';
  static const detailsSummaryCalendar =
      'assets/images/figma/programacao/details_summary_calendar.svg';
  static const detailsSummaryLocation =
      'assets/images/figma/programacao/details_summary_location.svg';
  static const detailsInfoCalendar =
      'assets/images/figma/programacao/details_info_calendar.svg';
  static const detailsInfoClock =
      'assets/images/figma/programacao/details_info_clock.svg';
  static const detailsInfoPeople =
      'assets/images/figma/programacao/details_info_people.svg';
  static const detailsLocation =
      'assets/images/figma/programacao/details_location.svg';
  static const detailsBell = 'assets/images/figma/programacao/details_bell.svg';
  static const detailsShare =
      'assets/images/figma/programacao/details_share.svg';
}

class ProgramacaoDayData {
  const ProgramacaoDayData(this.weekday, this.day);

  final String weekday;
  final int day;
}

class ProgramacaoEventData {
  const ProgramacaoEventData({
    required this.category,
    required this.title,
    required this.time,
    required this.location,
    required this.reminderEnabled,
  });

  final String category;
  final String title;
  final String time;
  final String location;
  final bool reminderEnabled;

  ProgramacaoEventData copyWith({bool? reminderEnabled}) {
    return ProgramacaoEventData(
      category: category,
      title: title,
      time: time,
      location: location,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}

class ProgramacaoDetalhesData {
  const ProgramacaoDetalhesData({
    required this.title,
    required this.dayTimeSummary,
    required this.locationSummary,
    required this.description,
    required this.date,
    required this.time,
    required this.audience,
    required this.locationName,
    required this.address,
    required this.hasLiveStream,
  });

  final String title;
  final String dayTimeSummary;
  final String locationSummary;
  final String description;
  final String date;
  final String time;
  final String audience;
  final String locationName;
  final String address;
  final bool hasLiveStream;
}

class ProgramacaoMockData {
  const ProgramacaoMockData._();

  static const weekLabel = '10 a 16 de junho';
  static const eventDay = 15;
  static const _detailsDescription =
      'Junte-se a nós para o Culto da Família neste domingo. Devido a um '
      'evento especial de liderança à tarde, nosso horário noturno foi '
      'ajustado. Traga seus convidados para um tempo de adoração e palavra.';
  static const _detailsAddress =
      'Av. Leopoldino Canuto de Melo, 846 - Caixa D Água, Olinda - PE, '
      '53210-250';

  static const liveDetails = ProgramacaoDetalhesData(
    title: 'Culto de Domingo',
    dayTimeSummary: 'Domingo, 18h às 20h',
    locationSummary: 'Templo principal',
    description: _detailsDescription,
    date: 'Domingo, 16 de junho',
    time: '18h às 20h',
    audience: 'Toda a comunidade',
    locationName: 'Templo Principal Nova Aliança',
    address: _detailsAddress,
    hasLiveStream: true,
  );

  static const standardDetails = ProgramacaoDetalhesData(
    title: 'Culto de Domingo',
    dayTimeSummary: 'Domingo, 18h às 20h',
    locationSummary: 'Templo principal',
    description: _detailsDescription,
    date: 'Domingo, 16 de junho',
    time: '18h às 20h',
    audience: 'Toda a comunidade',
    locationName: 'Templo Principal Nova Aliança',
    address: _detailsAddress,
    hasLiveStream: false,
  );

  static const days = <ProgramacaoDayData>[
    ProgramacaoDayData('SEG', 10),
    ProgramacaoDayData('TER', 11),
    ProgramacaoDayData('QUA', 12),
    ProgramacaoDayData('QUI', 13),
    ProgramacaoDayData('SEX', 14),
    ProgramacaoDayData('SAB', 15),
  ];

  static const events = <ProgramacaoEventData>[
    ProgramacaoEventData(
      category: 'PROGRAMAÇÃO',
      title: 'Culto de doutrina',
      time: '17h',
      location: 'igreja sede',
      reminderEnabled: true,
    ),
    ProgramacaoEventData(
      category: 'PROGRAMAÇÃO',
      title: 'Sala de Oração',
      time: '20h',
      location: 'igreja sede',
      reminderEnabled: true,
    ),
    ProgramacaoEventData(
      category: 'REUNIÃO',
      title: 'Reunião de Planejamento',
      time: '22h',
      location: 'Casa do pastor',
      reminderEnabled: false,
    ),
  ];
}
