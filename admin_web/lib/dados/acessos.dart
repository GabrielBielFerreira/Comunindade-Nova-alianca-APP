import 'package:cloud_functions/cloud_functions.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../config/ambiente.dart';

/// Capacidades de um usuário sobre UMA unidade, conforme o servidor.
///
/// O painel nunca deriva permissão por conta própria: estes valores vêm da
/// Function `meusAcessos`, que repete a autorização no Admin SDK.
class AcessoIgreja {
  const AcessoIgreja({
    required this.igrejaId,
    required this.nome,
    required this.ativa,
    required this.perfil,
    required this.status,
    required this.funcoesAdmin,
    required this.acessarPainel,
    required this.lerFinancas,
    required this.gerenciarConteudo,
    required this.moderarOracao,
    required this.aprovarMembro,
    required this.gerenciarLideranca,
  });

  final IgrejaId igrejaId;
  final String nome;
  final bool ativa;
  final PerfilComunitario perfil;
  final String status;
  final Set<FuncaoAdmin> funcoesAdmin;

  final bool acessarPainel;
  final bool lerFinancas;
  final bool gerenciarConteudo;
  final bool moderarOracao;
  final bool aprovarMembro;
  final bool gerenciarLideranca;

  factory AcessoIgreja.doMapa(Map<String, dynamic> mapa) {
    final capacidades =
        Map<String, dynamic>.from(mapa['capacidades'] as Map? ?? const {});
    bool cap(String chave) => capacidades[chave] == true;

    return AcessoIgreja(
      igrejaId: IgrejaId(mapa['igrejaId'] as String),
      nome: mapa['nome'] as String? ?? '',
      ativa: mapa['ativa'] == true,
      perfil: PerfilComunitario.deTexto(mapa['perfil'] as String?),
      status: mapa['status'] as String? ?? 'sem_vinculo',
      funcoesAdmin: FuncaoAdmin.deLista(mapa['funcoesAdmin'] as Iterable<dynamic>?),
      acessarPainel: cap('acessarPainel'),
      lerFinancas: cap('lerFinancas'),
      gerenciarConteudo: cap('gerenciarConteudo'),
      moderarOracao: cap('moderarOracao'),
      aprovarMembro: cap('aprovarMembro'),
      gerenciarLideranca: cap('gerenciarLideranca'),
    );
  }
}

/// Resposta completa de `meusAcessos`.
class MeusAcessos {
  const MeusAcessos({
    required this.uid,
    required this.isSuperAdmin,
    required this.acessos,
  });

  final String uid;
  final bool isSuperAdmin;
  final List<AcessoIgreja> acessos;

  /// Nenhuma unidade administrável => o painel bloqueia o acesso.
  bool get semAcessoAdministrativo => acessos.isEmpty;

  /// O seletor de igreja só aparece com mais de uma unidade autorizada.
  bool get precisaSeletor => acessos.length > 1;

  AcessoIgreja? porId(IgrejaId? id) {
    if (id == null) return null;
    for (final acesso in acessos) {
      if (acesso.igrejaId == id) return acesso;
    }
    return null;
  }
}

/// Cliente da Function `meusAcessos`.
class AcessosRepository {
  AcessosRepository({FirebaseFunctions? functions})
      : _functionsInjetado = functions;

  final FirebaseFunctions? _functionsInjetado;

  /// Resolvido sob demanda: construir o repositório não exige Firebase
  /// inicializado, o que permite montar as telas em teste de widget.
  late final FirebaseFunctions _functions = _functionsInjetado ??
      FirebaseFunctions.instanceFor(
        region: ConfiguracaoFirebase.regiaoFunctions,
      );

  Future<MeusAcessos> carregar() async {
    final resultado = await _functions.httpsCallable('meusAcessos').call();
    final dados = Map<String, dynamic>.from(resultado.data as Map);

    final lista = (dados['acessos'] as List? ?? const [])
        .map((item) => AcessoIgreja.doMapa(Map<String, dynamic>.from(item as Map)))
        .toList();

    return MeusAcessos(
      uid: dados['uid'] as String? ?? '',
      isSuperAdmin: dados['isSuperAdmin'] == true,
      acessos: lista,
    );
  }
}
