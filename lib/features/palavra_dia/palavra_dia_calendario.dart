/// Referência de um versículo do calendário anual da Palavra do Dia.
///
/// IMPORTANTE: aqui ficam apenas **referências** (livro/capítulo/versículo) e
/// uma reflexão opcional (conteúdo autoral). O TEXTO bíblico nunca é digitado à
/// mão — é obtido em tempo de execução pela integração bíblica já existente
/// (Almeida, domínio público), evitando invenção ou atribuição incorreta.
class PalavraDiaRef {
  const PalavraDiaRef(this.livro, this.capitulo, this.versiculo, [this.reflexao]);

  final String livro;
  final int capitulo;
  final int versiculo;

  /// Pequena mensagem de reflexão (quando aplicável). Texto autoral, não
  /// bíblico — pode ser nulo.
  final String? reflexao;

  String get referencia => '$livro $capitulo:$versiculo';

  /// Identificador único e estável da posição no calendário (0..365).
  String idPara(int indice) =>
      'anual-${indice.toString().padLeft(3, '0')}';
}

/// Calendário anual da Palavra do Dia: **366 conteúdos** (um por data possível,
/// incluindo 29 de fevereiro), sem repetição dentro do ciclo.
///
/// A seleção é determinística por data (mesmo conteúdo para todos os usuários no
/// mesmo dia) e independe de nova versão do app.
class PalavraDiaCalendario {
  const PalavraDiaCalendario._();

  /// Índice de início de cada mês num ano **bissexto** (fevereiro com 29 dias).
  /// Garante 366 posições fixas e trata o 29/02 (índice 59) sem sobreposição.
  static const List<int> _inicioMes = [
    0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335,
  ];

  static List<PalavraDiaRef>? _cache;

  /// Lista imutável com exatamente 366 referências únicas.
  static List<PalavraDiaRef> todas() => _cache ??= _construir();

  /// Índice do calendário (0..365) para uma data, na disposição de ano
  /// bissexto. Em anos não bissextos o índice 59 (29/02) simplesmente não
  /// ocorre; as demais datas permanecem estáveis ano após ano.
  static int indiceDoDia(DateTime data) =>
      _inicioMes[data.month - 1] + (data.day - 1);

  /// Referência do dia para a data informada.
  static PalavraDiaRef paraData(DateTime data) {
    final lista = todas();
    final i = indiceDoDia(data) % lista.length;
    return lista[i];
  }

  static List<PalavraDiaRef> _construir() {
    final refs = <PalavraDiaRef>[];
    final vistos = <String>{};

    void add(String livro, int cap, int ver, [String? refl]) {
      if (refs.length >= 366) return;
      final chave = '$livro $cap:$ver';
      if (vistos.add(chave)) {
        refs.add(PalavraDiaRef(livro, cap, ver, refl));
      }
    }

    // ── Núcleo curado (versículos clássicos, existência garantida) ─────────
    // Muitos com reflexão autoral curta; os demais ficam sem reflexão.
    add('Gênesis', 1, 1, 'No princípio Deus já cuidava de tudo — inclusive de você.');
    add('Salmos', 23, 1, 'O Senhor é o teu pastor: descanse no cuidado d\'Ele hoje.');
    add('Filipenses', 4, 13, 'A tua força vem de Cristo, não das circunstâncias.');
    add('João', 3, 16, 'O amor de Deus por você tem nome: Jesus.');
    add('Provérbios', 3, 5, 'Confie mais em Deus do que no seu próprio entendimento.');
    add('Isaías', 41, 10, 'Não tema: Deus segura a tua mão.');
    add('Josué', 1, 9, 'Seja forte e corajoso — o Senhor vai com você.');
    add('Salmos', 46, 1, 'Deus é refúgio presente na hora da angústia.');
    add('Mateus', 6, 33, 'Busque primeiro o Reino; o restante vem por acréscimo.');
    add('Romanos', 8, 28, 'Deus faz todas as coisas cooperarem para o bem.');
    add('Salmos', 37, 5, 'Entregue o teu caminho ao Senhor e confie.');
    add('Jeremias', 29, 11, 'Os planos de Deus para você são de paz e esperança.');
    add('2 Coríntios', 12, 9, 'A graça de Deus basta; a força d\'Ele se aperfeiçoa na fraqueza.');
    add('Salmos', 91, 1, 'Quem habita no esconderijo do Altíssimo descansa seguro.');
    add('Hebreus', 11, 1, 'Fé é a certeza daquilo que se espera.');
    add('Gálatas', 5, 22, 'O Espírito produz em você amor, alegria e paz.');
    add('Salmos', 121, 1, 'O teu socorro vem do Senhor, que fez os céus e a terra.');
    add('Mateus', 11, 28, 'Venha a Jesus e encontre descanso para a alma.');
    add('Provérbios', 16, 3, 'Confie ao Senhor as suas obras, e os seus planos terão êxito.');
    add('Salmos', 118, 24, 'Este é o dia que o Senhor fez: alegre-se nele.');
    add('1 Coríntios', 13, 4, 'O amor é paciente e bondoso.');
    add('Salmos', 27, 1, 'O Senhor é a tua luz: a quem temerás?');
    add('Salmos', 34, 8, 'Prove e veja como o Senhor é bom.');
    add('Isaías', 40, 31, 'Os que esperam no Senhor renovam as suas forças.');
    add('Filipenses', 4, 6, 'Não ande ansioso: apresente tudo a Deus em oração.');
    add('Filipenses', 4, 7, 'A paz de Deus guarda o teu coração e a tua mente.');
    add('João', 14, 6, null);
    add('João', 14, 27, 'A paz que Jesus dá não é como a do mundo — não se abale.');
    add('Salmos', 119, 105, 'A Palavra de Deus ilumina os teus passos.');
    add('Provérbios', 3, 6, null);
    add('Mateus', 5, 16, 'Que a tua luz brilhe diante das pessoas.');
    add('Romanos', 12, 12, 'Alegres na esperança, pacientes na tribulação.');
    add('1 Pedro', 5, 7, 'Lance sobre Deus toda a tua ansiedade, porque Ele cuida de você.');
    add('Salmos', 46, 10, 'Aquiete-se e saiba que Ele é Deus.');
    add('Josué', 1, 8, null);
    add('Salmos', 51, 10, 'Peça a Deus um coração puro e um espírito renovado.');
    add('Isaías', 26, 3, 'Deus guarda em perfeita paz quem n\'Ele confia.');
    add('Lamentações', 3, 22, 'As misericórdias do Senhor se renovam a cada manhã.');
    add('Lamentações', 3, 23, null);
    add('Sofonias', 3, 17, 'O Senhor se alegra em você com cânticos.');

    // ── Salmos (edificantes, existência garantida) ─────────────────────────
    add('Salmos', 1, 1);
    add('Salmos', 1, 2);
    add('Salmos', 1, 3);
    add('Salmos', 3, 3);
    add('Salmos', 4, 8);
    add('Salmos', 5, 3);
    add('Salmos', 8, 1);
    add('Salmos', 9, 9);
    add('Salmos', 9, 10);
    add('Salmos', 13, 5);
    add('Salmos', 16, 8);
    add('Salmos', 16, 11);
    add('Salmos', 18, 2);
    add('Salmos', 19, 1);
    add('Salmos', 19, 14);
    add('Salmos', 20, 7);
    add('Salmos', 23, 4);
    add('Salmos', 24, 1);
    add('Salmos', 25, 4);
    add('Salmos', 27, 4);
    add('Salmos', 28, 7);
    add('Salmos', 29, 11);
    add('Salmos', 30, 5);
    add('Salmos', 31, 24);
    add('Salmos', 32, 8);
    add('Salmos', 33, 20);
    add('Salmos', 34, 18);
    add('Salmos', 36, 5);
    add('Salmos', 37, 4);
    add('Salmos', 37, 7);
    add('Salmos', 37, 23);
    add('Salmos', 40, 1);
    add('Salmos', 42, 1);
    add('Salmos', 42, 11);
    add('Salmos', 43, 5);
    add('Salmos', 46, 2);
    add('Salmos', 48, 14);
    add('Salmos', 55, 22);
    add('Salmos', 56, 3);
    add('Salmos', 57, 1);
    add('Salmos', 59, 16);
    add('Salmos', 61, 2);
    add('Salmos', 62, 1);
    add('Salmos', 62, 5);
    add('Salmos', 63, 1);
    add('Salmos', 66, 1);
    add('Salmos', 68, 19);
    add('Salmos', 71, 5);
    add('Salmos', 73, 26);
    add('Salmos', 84, 11);
    add('Salmos', 86, 5);
    add('Salmos', 89, 1);
    add('Salmos', 90, 12);
    add('Salmos', 91, 2);
    add('Salmos', 91, 11);
    add('Salmos', 92, 1);
    add('Salmos', 94, 19);
    add('Salmos', 95, 1);
    add('Salmos', 96, 1);
    add('Salmos', 98, 1);
    add('Salmos', 100, 4);
    add('Salmos', 103, 1);
    add('Salmos', 103, 2);
    add('Salmos', 105, 1);
    add('Salmos', 107, 1);
    add('Salmos', 108, 1);
    add('Salmos', 111, 10);
    add('Salmos', 112, 1);
    add('Salmos', 113, 3);
    add('Salmos', 115, 1);
    add('Salmos', 116, 1);
    add('Salmos', 117, 1);
    add('Salmos', 118, 6);
    add('Salmos', 118, 8);
    add('Salmos', 119, 11);
    add('Salmos', 119, 114);
    add('Salmos', 121, 2);
    add('Salmos', 121, 7);
    add('Salmos', 121, 8);
    add('Salmos', 126, 5);
    add('Salmos', 127, 1);
    add('Salmos', 130, 5);
    add('Salmos', 133, 1);
    add('Salmos', 136, 1);
    add('Salmos', 138, 8);
    add('Salmos', 139, 7);
    add('Salmos', 139, 14);
    add('Salmos', 139, 23);
    add('Salmos', 141, 2);
    add('Salmos', 143, 8);
    add('Salmos', 145, 9);
    add('Salmos', 145, 18);
    add('Salmos', 146, 2);
    add('Salmos', 147, 1);
    add('Salmos', 147, 3);
    add('Salmos', 149, 1);
    add('Salmos', 150, 6);

    // ── Provérbios ─────────────────────────────────────────────────────────
    add('Provérbios', 2, 6);
    add('Provérbios', 3, 9);
    add('Provérbios', 4, 23, 'Guarde o teu coração: dele procedem as fontes da vida.');
    add('Provérbios', 11, 25);
    add('Provérbios', 15, 1, 'A resposta branda desvia o furor.');
    add('Provérbios', 16, 9);
    add('Provérbios', 17, 17, 'O amigo ama em todo o tempo.');
    add('Provérbios', 17, 22);
    add('Provérbios', 18, 10, 'O nome do Senhor é torre forte.');
    add('Provérbios', 18, 24);
    add('Provérbios', 19, 21);
    add('Provérbios', 21, 31);
    add('Provérbios', 22, 6);
    add('Provérbios', 27, 17, 'Como o ferro afia o ferro, o amigo edifica o amigo.');
    add('Provérbios', 28, 13);
    add('Provérbios', 31, 25);

    // ── Isaías / Profetas ──────────────────────────────────────────────────
    add('Isaías', 40, 28);
    add('Isaías', 40, 29);
    add('Isaías', 41, 13);
    add('Isaías', 43, 2, 'Nas águas e no fogo, Deus vai com você.');
    add('Isaías', 12, 2);
    add('Isaías', 30, 15);
    add('Isaías', 53, 5);
    add('Isaías', 54, 10);
    add('Isaías', 55, 6);
    add('Isaías', 55, 8);
    add('Isaías', 55, 9);
    add('Isaías', 61, 1);
    add('Jeremias', 29, 12);
    add('Jeremias', 29, 13);
    add('Jeremias', 31, 3, 'Deus te amou com amor eterno.');
    add('Jeremias', 33, 3, 'Clame a Deus, e Ele responderá.');
    add('Jeremias', 17, 7);
    add('Miquéias', 6, 8);
    add('Miquéias', 7, 7);
    add('Naum', 1, 7, 'O Senhor é bom, um refúgio no dia da angústia.');
    add('Habacuque', 3, 19);
    add('Zacarias', 4, 6);
    add('Malaquias', 3, 10);

    // ── Antigo Testamento (diversos) ───────────────────────────────────────
    add('Êxodo', 14, 14, 'O Senhor pelejará por você; fique tranquilo.');
    add('Êxodo', 15, 2);
    add('Êxodo', 33, 14);
    add('Números', 6, 24, 'O Senhor te abençoe e te guarde.');
    add('Números', 6, 25);
    add('Números', 6, 26);
    add('Deuteronômio', 31, 6, 'Sê forte: o Senhor não te desampara.');
    add('Deuteronômio', 31, 8);
    add('Deuteronômio', 6, 5);
    add('Josué', 24, 15, 'Eu e a minha casa serviremos ao Senhor.');
    add('Rute', 1, 16);
    add('1 Samuel', 16, 7, 'O Senhor olha para o coração.');
    add('2 Samuel', 22, 31);
    add('1 Crônicas', 16, 11);
    add('1 Crônicas', 16, 34);
    add('2 Crônicas', 7, 14);
    add('Neemias', 8, 10, 'A alegria do Senhor é a vossa força.');
    add('Jó', 19, 25);
    add('Jó', 23, 10);
    add('Jó', 42, 2);

    // ── Evangelhos ─────────────────────────────────────────────────────────
    add('Mateus', 5, 3);
    add('Mateus', 5, 4);
    add('Mateus', 5, 6);
    add('Mateus', 5, 8);
    add('Mateus', 5, 9);
    add('Mateus', 5, 14);
    add('Mateus', 6, 34, 'Basta a cada dia o seu mal: viva hoje confiando.');
    add('Mateus', 7, 7, 'Peça, busque, bata — e a porta se abrirá.');
    add('Mateus', 11, 29);
    add('Mateus', 19, 26, 'Para Deus tudo é possível.');
    add('Mateus', 22, 37);
    add('Mateus', 28, 19);
    add('Mateus', 28, 20);
    add('Marcos', 9, 23, 'Tudo é possível ao que crê.');
    add('Marcos', 10, 27);
    add('Marcos', 11, 24);
    add('Marcos', 12, 30);
    add('Marcos', 16, 15);
    add('Lucas', 1, 37, 'Para Deus nada é impossível.');
    add('Lucas', 6, 31);
    add('Lucas', 6, 38);
    add('Lucas', 11, 9);
    add('João', 1, 1);
    add('João', 1, 12);
    add('João', 8, 12, 'Jesus é a luz do mundo: siga-O e não andará em trevas.');
    add('João', 8, 32);
    add('João', 10, 10, 'Jesus veio para que você tenha vida em abundância.');
    add('João', 11, 25);
    add('João', 13, 34, 'Ame como Jesus amou você.');
    add('João', 14, 1);
    add('João', 15, 5);
    add('João', 15, 12);
    add('João', 16, 33, 'Tenha bom ânimo: Jesus venceu o mundo.');

    // ── Atos e Cartas ──────────────────────────────────────────────────────
    add('Atos', 1, 8);
    add('Atos', 16, 31);
    add('Atos', 20, 35);
    add('Romanos', 5, 8, 'Cristo morreu por nós quando ainda éramos pecadores.');
    add('Romanos', 8, 31);
    add('Romanos', 8, 38);
    add('Romanos', 8, 39);
    add('Romanos', 10, 9);
    add('Romanos', 12, 1);
    add('Romanos', 12, 2, 'Deixe Deus renovar a sua mente.');
    add('Romanos', 12, 21);
    add('Romanos', 15, 13);
    add('1 Coríntios', 10, 13, 'Deus é fiel: com a tentação dá também o escape.');
    add('1 Coríntios', 13, 13);
    add('1 Coríntios', 15, 58);
    add('1 Coríntios', 16, 14, 'Tudo o que fizerem, façam com amor.');
    add('2 Coríntios', 5, 7, 'Ande por fé, e não por vista.');
    add('2 Coríntios', 5, 17, 'Em Cristo você é uma nova criatura.');
    add('2 Coríntios', 4, 16);
    add('2 Coríntios', 4, 18);
    add('2 Coríntios', 9, 7);
    add('Gálatas', 2, 20);
    add('Gálatas', 6, 9, 'Não desanime de fazer o bem: a colheita vem.');
    add('Efésios', 2, 8);
    add('Efésios', 2, 10);
    add('Efésios', 3, 20, 'Deus pode muito mais do que pedimos ou pensamos.');
    add('Efésios', 4, 32);
    add('Efésios', 6, 10);
    add('Filipenses', 4, 4, 'Alegrem-se sempre no Senhor.');
    add('Filipenses', 4, 8);
    add('Filipenses', 4, 19);
    add('Filipenses', 1, 6, 'Deus terminará a boa obra que começou em você.');
    add('Filipenses', 2, 3);
    add('Filipenses', 2, 13);
    add('Colossenses', 3, 2);
    add('Colossenses', 3, 15);
    add('Colossenses', 3, 23, 'Faça tudo de coração, como para o Senhor.');
    add('1 Tessalonicenses', 5, 16);
    add('1 Tessalonicenses', 5, 17);
    add('1 Tessalonicenses', 5, 18, 'Em tudo dê graças: esta é a vontade de Deus.');
    add('2 Timóteo', 1, 7, 'Deus não te deu espírito de temor, mas de poder, amor e moderação.');
    add('2 Timóteo', 3, 16);
    add('2 Timóteo', 4, 7);
    add('Hebreus', 11, 6);
    add('Hebreus', 12, 1);
    add('Hebreus', 12, 2, 'Olhe para Jesus, o autor e consumador da fé.');
    add('Hebreus', 13, 5);
    add('Hebreus', 13, 6);
    add('Hebreus', 13, 8, 'Jesus é o mesmo ontem, hoje e para sempre.');
    add('Hebreus', 4, 16);
    add('Hebreus', 10, 23);
    add('Tiago', 1, 2);
    add('Tiago', 1, 5, 'Falta-lhe sabedoria? Peça a Deus, que dá com generosidade.');
    add('Tiago', 1, 12);
    add('Tiago', 1, 17, 'Toda boa dádiva vem do alto, do Pai.');
    add('Tiago', 4, 7);
    add('Tiago', 4, 8, 'Aproxime-se de Deus, e Ele se aproximará de você.');
    add('Tiago', 5, 16);
    add('1 Pedro', 5, 6);
    add('1 Pedro', 4, 8);
    add('1 Pedro', 2, 9);
    add('1 Pedro', 1, 3);
    add('2 Pedro', 3, 9);
    add('2 Pedro', 3, 18);
    add('1 João', 1, 9, 'Se confessarmos, Ele é fiel para perdoar.');
    add('1 João', 4, 7);
    add('1 João', 4, 8);
    add('1 João', 4, 18, 'No amor perfeito não há medo.');
    add('1 João', 4, 19);
    add('1 João', 3, 1);
    add('1 João', 5, 4);
    add('1 João', 5, 14);
    add('Apocalipse', 3, 20, 'Jesus bate à porta: abra o seu coração.');
    add('Apocalipse', 21, 4, 'Deus enxugará toda lágrima dos seus olhos.');
    add('Apocalipse', 22, 13);

    // ── Preenchimento seguro até 366 (referências de existência garantida) ──
    // Provérbios: capítulos 1..31, versículos 1..18 (todos existem no cânon).
    for (var c = 1; c <= 31 && refs.length < 366; c++) {
      for (var v = 1; v <= 18 && refs.length < 366; v++) {
        add('Provérbios', c, v);
      }
    }
    // Salmos: capítulo 1..150, versículo 1 (sempre existe).
    for (var c = 1; c <= 150 && refs.length < 366; c++) {
      add('Salmos', c, 1);
    }

    assert(refs.length == 366,
        'O calendário anual deve ter exatamente 366 conteúdos (tem ${refs.length}).');
    return refs;
  }
}
