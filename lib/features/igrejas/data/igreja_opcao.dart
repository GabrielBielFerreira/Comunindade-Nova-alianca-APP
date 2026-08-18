import 'package:nova_alianca_core/nova_alianca_core.dart';

/// Uma unidade como aparece nas telas de escolha/visualização.
///
/// Existe para que a interface nunca trafegue apenas o NOME da igreja: o que
/// define escopo de dados é o [IgrejaId]. Duas unidades podem ter nomes
/// parecidos, e escolher por texto foi exatamente o que fez a troca de igreja
/// não mudar contexto nenhum.
class IgrejaOpcao {
  const IgrejaOpcao({
    required this.id,
    required this.nome,
    required this.endereco,
    required this.configurada,
  });

  final IgrejaId id;
  final String nome;

  /// Endereço já formatado para exibição. Nunca inventado: quando a unidade
  /// ainda não tem dados oficiais, vem o rótulo honesto.
  final String endereco;

  /// `false` quando os dados institucionais oficiais ainda não chegaram.
  final bool configurada;

  factory IgrejaOpcao.de(IgrejaModel igreja) {
    final partes = <String>[
      if (igreja.endereco != null) igreja.endereco!,
      if (igreja.cidadeEstado != null) igreja.cidadeEstado!,
    ];

    return IgrejaOpcao(
      id: igreja.id,
      nome: igreja.nome,
      endereco: partes.isEmpty ? 'Endereço não informado' : partes.join(' — '),
      configurada: igreja.configurada,
    );
  }

  /// Texto usado na busca por nome ou endereço.
  String get buscavel => '$nome $endereco';
}
