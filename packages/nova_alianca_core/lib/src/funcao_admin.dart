import 'normalizacao.dart';

/// Função administrativa atribuída a alguém **dentro de uma unidade**.
///
/// É independente do perfil comunitário: um `membro` pode ser `tesoureiro`, e
/// um `lider` pode não ter nenhuma função administrativa.
enum FuncaoAdmin {
  /// Função administrativa do pastor da unidade. Só é concedida junto com o
  /// perfil comunitário `pastor`.
  pastor,

  /// Acesso financeiro sem exigir perfil de liderança ministerial.
  tesoureiro,

  /// CRUD de conteúdo. NÃO concede acesso financeiro.
  editor,

  /// Moderação de pedidos de oração. NÃO concede acesso financeiro.
  moderadorOracao;

  /// Valor persistido no Firestore (snake_case).
  String get valor => switch (this) {
        FuncaoAdmin.pastor => 'pastor',
        FuncaoAdmin.tesoureiro => 'tesoureiro',
        FuncaoAdmin.editor => 'editor',
        FuncaoAdmin.moderadorOracao => 'moderador_oracao',
      };

  /// Grafias alternativas aceitas para a mesma função. Existem porque
  /// documentos editados à mão no console aparecem como
  /// `moderador de oração` / `moderador-oracao`.
  static const Map<String, FuncaoAdmin> _apelidos = {
    'moderador_de_oracao': FuncaoAdmin.moderadorOracao,
    'moderadororacao': FuncaoAdmin.moderadorOracao,
  };

  /// Aceita `moderador de oração`, `moderador_oracao`, `Tesoureiro`, etc.
  /// Retorna `null` quando não reconhece — nunca adivinha uma função.
  static FuncaoAdmin? deTexto(String? bruto) {
    if (bruto == null) return null;
    final chave = normalizarChave(bruto);
    for (final funcao in FuncaoAdmin.values) {
      if (funcao.valor == chave) return funcao;
    }
    return _apelidos[chave];
  }

  /// Converte a lista crua do Firestore, descartando valores desconhecidos.
  static Set<FuncaoAdmin> deLista(Iterable<dynamic>? bruto) {
    if (bruto == null) return const <FuncaoAdmin>{};
    return bruto
        .map((item) => deTexto(item?.toString()))
        .whereType<FuncaoAdmin>()
        .toSet();
  }

  static List<String> paraLista(Iterable<FuncaoAdmin> funcoes) =>
      funcoes.map((f) => f.valor).toList()..sort();

  String get rotulo => switch (this) {
        FuncaoAdmin.pastor => 'Pastor',
        FuncaoAdmin.tesoureiro => 'Tesoureiro',
        FuncaoAdmin.editor => 'Editor',
        FuncaoAdmin.moderadorOracao => 'Moderador de oração',
      };
}
