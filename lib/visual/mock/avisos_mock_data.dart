enum AvisoFilter { todos, comunidade, ministerios, escalas }

class AvisoFilterData {
  const AvisoFilterData(this.filter, this.label);

  final AvisoFilter filter;
  final String label;
}

class AvisoData {
  const AvisoData({
    required this.filter,
    required this.category,
    required this.title,
    required this.description,
    required this.publishedAt,
    required this.publishedMetadata,
    required this.detailDescription,
    required this.detailDate,
    required this.detailTime,
    required this.detailLocation,
    required this.detailAddress,
    this.imageAsset,
    this.showScaleAction = false,
    this.attachments = const [],
  });

  final AvisoFilter filter;
  final String category;
  final String title;
  final String description;
  final String publishedAt;
  final String publishedMetadata;
  final String detailDescription;
  final String detailDate;
  final String detailTime;
  final String detailLocation;
  final String detailAddress;
  final String? imageAsset;
  final bool showScaleAction;
  final List<AvisoAttachmentData> attachments;
}

class AvisoAttachmentData {
  const AvisoAttachmentData({required this.name, required this.details});

  final String name;
  final String details;
}

abstract class AvisosMockData {
  static const cristoNoLarAsset =
      'assets/images/figma/avisos/cristo_no_lar.jpg';
  static const festividadeJovensAsset =
      'assets/images/figma/avisos/festividade_jovens.jpg';
  static const escalaIconAsset = 'assets/images/figma/avisos/escala_icon.svg';
  static const detailsBackAsset = 'assets/images/figma/avisos/details_back.svg';
  static const detailsShareAsset =
      'assets/images/figma/avisos/details_share.svg';
  static const detailsPublishedAsset =
      'assets/images/figma/avisos/details_published.svg';
  static const detailsCalendarAsset =
      'assets/images/figma/avisos/details_calendar.svg';
  static const detailsClockAsset =
      'assets/images/figma/avisos/details_clock.svg';
  static const detailsHomeAsset = 'assets/images/figma/avisos/details_home.svg';
  static const detailsLocationAsset =
      'assets/images/figma/avisos/details_location.svg';
  static const detailsFileAsset = 'assets/images/figma/avisos/details_file.svg';
  static const detailsDownloadAsset =
      'assets/images/figma/avisos/details_download.svg';

  static const filters = <AvisoFilterData>[
    AvisoFilterData(AvisoFilter.todos, 'Todos'),
    AvisoFilterData(AvisoFilter.comunidade, 'Comunidade'),
    AvisoFilterData(AvisoFilter.ministerios, 'Ministérios'),
    AvisoFilterData(AvisoFilter.escalas, 'Escalas'),
  ];

  static const escalaLouvor = AvisoData(
    filter: AvisoFilter.escalas,
    category: 'ESCALAS',
    title: 'Escala de Louvor Atualizada',
    description:
        'Atenção líderes do louvor: a escala de ministração para o mês de Julho foi liberada. Verifiquem suas equipes.',
    publishedAt: 'Ontem',
    publishedMetadata: 'Publicado ontem • Ministério de Louvor',
    detailDescription:
        'A escala de ministração do louvor para o mês de Julho foi atualizada. Confira as datas e orientações da sua equipe.',
    detailDate: 'Julho',
    detailTime: 'Conforme escala',
    detailLocation: 'Comunidade Nova Aliança',
    detailAddress: 'Av. Leopoldino Canuto de Melo, 846',
    showScaleAction: true,
    attachments: [
      AvisoAttachmentData(
        name: 'Escala de Louvor - Julho.pdf',
        details: 'PDF • 820 KB',
      ),
    ],
  );

  static const ensaioGeral = AvisoData(
    filter: AvisoFilter.ministerios,
    category: 'MINISTÉRIO LOUVOR',
    title: 'Ensaio Geral festividade',
    description:
        'Tivemos uma mudança no local do ensaio que já está na programação peço aos irmãos que veja peço a compreensão dos irmãos e que nos ajude',
    publishedAt: '1 dias atrás',
    publishedMetadata: 'Publicado há 1 dia • Ministério de Louvor',
    detailDescription:
        'O local do ensaio geral da festividade foi alterado. Consulte as informações abaixo e organize sua participação com a equipe.',
    detailDate: 'A confirmar',
    detailTime: '19:30',
    detailLocation: 'Templo principal',
    detailAddress: 'Av. Leopoldino Canuto de Melo, 846',
  );

  static const mudancaHorario = AvisoData(
    filter: AvisoFilter.comunidade,
    category: 'COMUNIDADE',
    title: 'Mudança de horário do culto',
    description:
        'Já estão abertas as inscrições para o nosso acampamento anual. Vagas limitadas, garanta a sua vaga no local previsto',
    publishedAt: '3 dias atrás',
    publishedMetadata: 'Publicado há 3 dias • Secretaria Pastoral',
    detailDescription:
        'O horário do próximo culto foi atualizado. Confira a programação e chegue com antecedência para participar conosco.',
    detailDate: 'Domingo',
    detailTime: '18:00',
    detailLocation: 'Comunidade Nova Aliança',
    detailAddress: 'Av. Leopoldino Canuto de Melo, 846',
  );

  static const cristoNoLar = AvisoData(
    filter: AvisoFilter.comunidade,
    category: 'COMUNIDADE',
    title: 'Cristo no Lar',
    description:
        'Participe do encontro na casa do irmão Lício hoje às 19:30h, peço aos irmão que levem algo para',
    publishedAt: '4 dias atrás',
    publishedMetadata: 'Publicado hoje, 10:30 • Secretaria Pastoral',
    detailDescription:
        'Venha participar de mais um encontro do Cristo no Lar. Hoje, às 19:30h, na casa do irmão Lício. O encontro na frente da igreja será na casa ao lado.',
    detailDate: 'Hoje',
    detailTime: '19:30',
    detailLocation: 'Casa do irmão Lício',
    detailAddress: 'Av. Leopoldino Canuto de Melo (casa ao lado da igreja)',
    imageAsset: cristoNoLarAsset,
    attachments: [
      AvisoAttachmentData(
        name: 'Programação completa.pdf',
        details: 'PDF • 1,2 MB',
      ),
      AvisoAttachmentData(
        name: 'Orientações aos participantes.pdf',
        details: 'PDF • 480 KB',
      ),
    ],
  );

  static const festividadeJovens = AvisoData(
    filter: AvisoFilter.comunidade,
    category: 'COMUNIDADE',
    title: 'Festividade dos jovens',
    description:
        'Participe deste momento especial de comunhão e celebração nossa festividade dos jovens da igreja',
    publishedAt: '5 dias atrás',
    publishedMetadata: 'Publicado há 5 dias • Ministério de Jovens',
    detailDescription:
        'Participe deste momento especial de comunhão e celebração na festividade dos jovens da Comunidade Nova Aliança.',
    detailDate: 'Em breve',
    detailTime: '19:00',
    detailLocation: 'Comunidade Nova Aliança',
    detailAddress: 'Av. Leopoldino Canuto de Melo, 846',
    imageAsset: festividadeJovensAsset,
  );

  static const notices = <AvisoData>[
    escalaLouvor,
    ensaioGeral,
    mudancaHorario,
    cristoNoLar,
    festividadeJovens,
  ];
}
