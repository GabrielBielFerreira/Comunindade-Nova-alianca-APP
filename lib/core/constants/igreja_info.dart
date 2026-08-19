/// Constantes institucionais da SEDE DE OLINDA.
///
/// ## Não use para dado que varia por unidade
///
/// Na arquitetura multi-igreja, nome, pastor, endereço, cidade, Instagram,
/// PIX e programação pertencem a `igrejas/{igrejaId}` e devem ser lidos de
/// `igrejaAtualDadosProvider`. Usar estas constantes numa tela faz o
/// aplicativo mostrar dados de Olinda enquanto a pessoa visualiza Petrolina —
/// e, no caso do PIX, enviaria dinheiro para a unidade errada.
///
/// O que ainda pode ficar aqui: identidade do PRODUTO (sigla, id de
/// documento), nunca identidade de uma congregação específica.
///
/// Telas já migradas: contribuição PIX, "Sobre a comunidade", seleção e troca
/// de igreja, configurações.
class IgrejaInfo {
  IgrejaInfo._();

  static const String nome = 'Comunidade Nova Aliança';
  static const String sigla = 'CNA';
  static const String slogan = 'Reconstruindo muros e formando alianças';
  @Deprecated('Varia por unidade: use IgrejaExibicao.pastoresExibicao')
  static const String pastor = 'José Victor Carvalho P. Santos';
  static const String endereco =
      'Av. Leopoldino Canuto de Melo, 846, Caixa D\'Água, Olinda-PE';
  static const String cep = '53210-250';
  static const String cidadeEstado = 'Olinda — PE';
  @Deprecated('Varia por unidade: use igrejaAtualDadosProvider.pixChave')
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

/// Identidade da REDE Nova Aliança — o que não varia por unidade.
///
/// Separado de [IgrejaInfo] de propósito: aqui ficam apenas dados
/// institucionais da rede/produto. Nome, endereço, Instagram, PIX e
/// programação de uma congregação específica vivem em `igrejas/{igrejaId}`.
class RedeNovaAlianca {
  RedeNovaAlianca._();

  static const String nome = 'Comunidade Nova Aliança';
  static const String sigla = 'CNA';

  /// Contato de suporte do aplicativo (privacidade, exclusão de conta, ajuda).
  ///
  /// Antes as telas usavam `IgrejaInfo.pixChave` para isto — a chave PIX de
  /// Olinda servindo de e-mail. Além de errado semanticamente, virava contato
  /// de Olinda para quem estava visualizando outra unidade.
  static const String suporteEmail = 'cnarecife01@gmail.com';
}
