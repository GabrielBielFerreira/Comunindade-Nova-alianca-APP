class IgrejaInfo {
  IgrejaInfo._();

  static const String nome = 'Comunidade Nova Aliança';
  static const String sigla = 'CNA';
  static const String slogan = 'Reconstruindo muros e formando alianças';
  static const String pastor = 'José Victor Carvalho P. Santos';
  static const String endereco =
      'Av. Leopoldino Canuto de Melo, 846, Caixa D\'Água, Olinda-PE';
  static const String cep = '53210-250';
  static const String cidadeEstado = 'Olinda — PE';
  static const String pixChave = 'cnarecife01@gmail.com';
  static const String pixTipo = 'email';
  static const String instagram = '@novaaliancaolinda';
  static const String instagramUrl = 'https://instagram.com/novaaliancaolinda';

  static const List<Map<String, String>> cultos = [
    {'dia': 'domingo', 'horario': '19h', 'nome': 'Culto Principal'},
    {'dia': 'terca', 'horario': '19h', 'nome': 'Cristo no Lar'},
    {'dia': 'quinta', 'horario': '19h', 'nome': 'Culto de Jovens'},
  ];

  static const List<String> ministerios = [
    'Ministério de Louvor',
    'Mídia da Igreja',
    'Grupo de Jovens',
    'Grupo de Homens',
    'Grupo de Mulheres',
    'Ministério Infantil',
    'Grupo de Idosos',
  ];

  // ID do documento único da coleção igreja no Firestore
  static const String firestoreDocId = 'principal';
}
