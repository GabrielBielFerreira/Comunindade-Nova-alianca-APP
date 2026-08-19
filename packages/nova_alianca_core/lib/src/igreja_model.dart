import 'igreja_id.dart';

/// Situação da integração de pagamentos de uma unidade.
enum StatusMercadoPago {
  /// Nenhuma conta conectada. Estado inicial e honesto de toda unidade nova.
  naoConfigurado,

  /// Conta conectada em ambiente de teste/sandbox.
  sandbox,

  /// Conta própria conectada e habilitada a receber.
  conectado;

  String get valor => switch (this) {
        StatusMercadoPago.naoConfigurado => 'nao_configurado',
        StatusMercadoPago.sandbox => 'sandbox',
        StatusMercadoPago.conectado => 'conectado',
      };

  static StatusMercadoPago deTexto(String? bruto) {
    for (final s in StatusMercadoPago.values) {
      if (s.valor == bruto) return s;
    }
    return StatusMercadoPago.naoConfigurado;
  }

  String get rotulo => switch (this) {
        StatusMercadoPago.naoConfigurado => 'Não configurado',
        StatusMercadoPago.sandbox => 'Sandbox (teste)',
        StatusMercadoPago.conectado => 'Conectado',
      };
}

/// Uma unidade da rede.
///
/// Pode ser hidratada pelo catálogo público sanitizado
/// `/catalogo_igrejas/{igrejaId}` ou, em contexto administrativo autorizado,
/// pelo documento operacional privado `/igrejas/{igrejaId}`. Campos ausentes
/// no catálogo permanecem nulos; nenhum fallback inventa dados.
///
/// Campos institucionais são deliberadamente opcionais. Uma unidade recém
/// cadastrada aparece como "não configurada" em vez de exibir dado inventado.
class IgrejaModel {
  const IgrejaModel({
    required this.id,
    required this.nome,
    this.slug,
    this.ativa = false,
    this.configurada = false,
    this.pastorResponsavel,
    this.pastoresPublicos = const <String>[],
    this.responsavelAdministrativoUid,
    this.slogan,
    this.endereco,
    this.enderecoSecundario,
    this.youtubeUrl,
    this.cultosRecorrentes = const <String>[],
    this.cidadeEstado,
    this.cep,
    this.telefone,
    this.instagram,
    this.pixChave,
    this.pixTipo,
    this.mercadoPagoStatus = StatusMercadoPago.naoConfigurado,
    this.criadoEm,
    this.atualizadoEm,
  });

  final IgrejaId id;
  final String nome;
  final String? slug;

  /// Unidade visível/operante no aplicativo.
  final bool ativa;

  /// Dados institucionais oficiais já preenchidos. Quando `false`, a interface
  /// deve exibir "não configurado" em vez de preencher com suposições.
  final bool configurada;

  /// Pastor responsável, quando há UM só e ele já foi confirmado.
  ///
  /// Mantido por compatibilidade. Unidades com mais de um pastor público —
  /// ou com liderança ainda em confirmação — devem usar [pastoresPublicos] e
  /// deixar este campo nulo, em vez de eleger um nome silenciosamente.
  final String? pastorResponsavel;

  /// Pastores exibidos publicamente. Pode conter mais de um nome.
  ///
  /// Ser listado aqui NÃO concede acesso administrativo: quem administra a
  /// unidade é definido por vínculo/UID, nunca por um nome em texto.
  final List<String> pastoresPublicos;

  /// UID do responsável administrativo, separado da exibição pública.
  final String? responsavelAdministrativoUid;

  final String? slogan;
  final String? endereco;

  /// Segundo endereço, quando a unidade ocupa mais de um espaço.
  final String? enderecoSecundario;

  final String? youtubeUrl;

  /// Programação recorrente em texto livre (ex.: "domingo às 18h").
  final List<String> cultosRecorrentes;
  final String? cidadeEstado;
  final String? cep;
  final String? telefone;
  final String? instagram;
  final String? pixChave;
  final String? pixTipo;
  final StatusMercadoPago mercadoPagoStatus;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  factory IgrejaModel.doMapa({
    required String id,
    required Map<String, dynamic> dados,
    DateTime? Function(dynamic)? lerData,
  }) {
    final converterData = lerData ?? (dynamic v) => v is DateTime ? v : null;
    final institucional =
        (dados['dados_institucionais'] as Map<dynamic, dynamic>?) ?? const {};

    String? texto(String chave) {
      final valor = institucional[chave] ?? dados[chave];
      final s = valor?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    List<String> lista(String chave) {
      final bruto = institucional[chave] ?? dados[chave];
      if (bruto is! Iterable) return const <String>[];
      return bruto
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }

    return IgrejaModel(
      id: IgrejaId(id),
      nome: (dados['nome'] as String?)?.trim() ?? id,
      slug: dados['slug'] as String?,
      ativa: dados['ativa'] as bool? ?? false,
      configurada: dados['configurada'] as bool? ?? false,
      pastorResponsavel: texto('pastor_responsavel'),
      pastoresPublicos: lista('pastores_publicos'),
      responsavelAdministrativoUid: texto('responsavel_administrativo_uid'),
      slogan: texto('slogan'),
      enderecoSecundario: texto('endereco_secundario'),
      youtubeUrl: texto('youtube_url'),
      cultosRecorrentes: lista('cultos_recorrentes'),
      endereco: texto('endereco'),
      cidadeEstado: texto('cidade_estado'),
      cep: texto('cep'),
      telefone: texto('telefone'),
      instagram: texto('instagram'),
      pixChave: texto('pix_chave'),
      pixTipo: texto('pix_tipo'),
      mercadoPagoStatus:
          StatusMercadoPago.deTexto(dados['mercado_pago_status'] as String?),
      criadoEm: converterData(dados['criado_em']),
      atualizadoEm: converterData(dados['atualizado_em']),
    );
  }

  Map<String, dynamic> paraMapa() => {
        'nome': nome,
        'slug': slug ?? id.valor,
        'ativa': ativa,
        'configurada': configurada,
        'dados_institucionais': {
          'pastor_responsavel': pastorResponsavel,
          'pastores_publicos': pastoresPublicos,
          'responsavel_administrativo_uid': responsavelAdministrativoUid,
          'slogan': slogan,
          'endereco_secundario': enderecoSecundario,
          'youtube_url': youtubeUrl,
          'cultos_recorrentes': cultosRecorrentes,
          'endereco': endereco,
          'cidade_estado': cidadeEstado,
          'cep': cep,
          'telefone': telefone,
          'instagram': instagram,
          'pix_chave': pixChave,
          'pix_tipo': pixTipo,
        },
        'mercado_pago_status': mercadoPagoStatus.valor,
      };

  /// Rótulo seguro para campos ainda não confirmados.
  static const String naoConfigurado = 'Não configurado';

  String get pastorExibicao => pastorResponsavel ?? naoConfigurado;
  String get enderecoExibicao => endereco ?? naoConfigurado;
}

/// Extensões de EXIBIÇÃO.
///
/// Concentram as decisões de "o que mostrar quando o dado oficial não existe",
/// para que nenhuma tela invente um valor por conta própria nem repita a
/// escolha de fallback de um jeito diferente.
extension IgrejaExibicao on IgrejaModel {
  /// Como apresentar a liderança pastoral publicamente.
  ///
  /// Devolve lista vazia quando não há nome CONFIRMADO — a tela deve então
  /// dizer "não informado", nunca escolher um nome plausível.
  List<String> get pastoresExibicao {
    if (pastoresPublicos.isNotEmpty) return pastoresPublicos;
    final unico = pastorResponsavel?.trim();
    if (unico != null && unico.isNotEmpty) return [unico];
    return const <String>[];
  }

  /// Endereços conhecidos, na ordem (principal primeiro).
  List<String> get enderecosExibicao => <String>[
        ?endereco,
        ?enderecoSecundario,
      ];

  /// Consulta de mapa para o endereço principal. `null` sem endereço — a tela
  /// não deve oferecer um link de mapa que não leva a lugar nenhum.
  String? get mapaUrl {
    final principal = endereco?.trim();
    if (principal == null || principal.isEmpty) return null;
    final busca = [principal, ?cidadeEstado].join(', ');
    return 'https://www.google.com/maps/search/?api=1&query='
        '${Uri.encodeComponent(busca)}';
  }

  /// `true` quando a unidade pode receber contribuição pelo aplicativo.
  bool get aceitaContribuicao => (pixChave?.trim().isNotEmpty ?? false);
}
