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

/// Uma unidade da rede: o documento `/igrejas/{igrejaId}`.
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
    this.endereco,
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

  final String? pastorResponsavel;
  final String? endereco;
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

    return IgrejaModel(
      id: IgrejaId(id),
      nome: (dados['nome'] as String?)?.trim() ?? id,
      slug: dados['slug'] as String?,
      ativa: dados['ativa'] as bool? ?? false,
      configurada: dados['configurada'] as bool? ?? false,
      pastorResponsavel: texto('pastor_responsavel'),
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
