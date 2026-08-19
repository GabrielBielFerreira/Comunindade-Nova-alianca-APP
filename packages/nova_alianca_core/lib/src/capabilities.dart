import 'funcao_admin.dart';
import 'igreja_id.dart';
import 'perfil_comunitario.dart';
import 'vinculo_igreja.dart';

/// Autorização de UM usuário sobre UMA unidade.
///
/// Fonte única da matriz de permissões. É consumida pelo aplicativo, pelo
/// painel e espelhada pelas Firestore Rules e pelas Cloud Functions — se a
/// regra mudar, muda aqui e nos testes correspondentes.
///
/// Princípios que este tipo materializa:
/// - Autorização é sempre relativa a uma igreja; não existe permissão "global"
///   exceto `super_admin`.
/// - Selecionar uma unidade no frontend NUNCA concede acesso: a instância é
///   construída a partir do vínculo aprovado daquela unidade.
/// - Vínculo não aprovado (pendente/inativo) não concede nada, mesmo que o
///   perfil registrado seja de liderança.
class Autorizacao {
  const Autorizacao({
    required this.uid,
    required this.igrejaId,
    required this.vinculo,
    this.isSuperAdmin = false,
  });

  /// Autorização de quem não possui vínculo com a unidade consultada.
  /// Um `super_admin` continua autorizado mesmo sem vínculo.
  const Autorizacao.semVinculo({
    required this.uid,
    required this.igrejaId,
    this.isSuperAdmin = false,
  }) : vinculo = null;

  final String uid;
  final IgrejaId igrejaId;

  /// Vínculo do usuário NESTA unidade. `null` quando não há vínculo.
  final VinculoIgreja? vinculo;

  /// Concedido por custom claim, verificado no servidor. Nunca lido de um
  /// documento gravável pelo cliente.
  final bool isSuperAdmin;

  // ── Base ────────────────────────────────────────────────────────────

  /// Vínculo existente, aprovado e pertencente à unidade consultada.
  ///
  /// A conferência de `igrejaId` é deliberada: impede que um vínculo de outra
  /// unidade seja usado por engano como autorização nesta.
  bool get temVinculoAtivo {
    final v = vinculo;
    return v != null && v.isAtivo && v.igrejaId == igrejaId;
  }

  bool get _isLiderancaMinisterial =>
      temVinculoAtivo && vinculo!.perfil.isLiderancaMinisterial;

  bool get _isPastorDaUnidade => temVinculoAtivo && vinculo!.perfil.isPastor;

  bool _temFuncao(FuncaoAdmin funcao) =>
      temVinculoAtivo && vinculo!.funcoesAdmin.contains(funcao);

  /// Perfil efetivo nesta unidade (`membro` quando não há vínculo ativo).
  PerfilComunitario get perfilEfetivo =>
      temVinculoAtivo ? vinculo!.perfil : PerfilComunitario.membro;

  // ── Matriz de permissões ────────────────────────────────────────────

  /// Acesso ao painel administrativo desta unidade.
  bool get podeAcessarPainel =>
      isSuperAdmin ||
      _isLiderancaMinisterial ||
      _temFuncao(FuncaoAdmin.tesoureiro) ||
      _temFuncao(FuncaoAdmin.editor) ||
      _temFuncao(FuncaoAdmin.moderadorOracao);

  /// Leitura das finanças da unidade.
  ///
  /// Liderança ministerial (pastor, diácono, evangelista, líder) OU tesoureiro.
  /// Editor e moderador NÃO recebem acesso financeiro por essas funções.
  bool get podeLerFinancas =>
      isSuperAdmin || _isLiderancaMinisterial || _temFuncao(FuncaoAdmin.tesoureiro);

  /// Ninguém edita valor ou aprova pagamento pelo cliente. O status definitivo
  /// vem do backend/webhook. Constante por decisão de arquitetura.
  bool get podeEscreverFinancas => false;

  /// CRUD de avisos, eventos, campanhas, ministérios e devocionais.
  bool get podeGerenciarConteudo =>
      isSuperAdmin || _isLiderancaMinisterial || _temFuncao(FuncaoAdmin.editor);

  /// Moderação de pedidos de oração da unidade.
  bool get podeModerarOracao =>
      isSuperAdmin ||
      _isLiderancaMinisterial ||
      _temFuncao(FuncaoAdmin.moderadorOracao);

  /// Aprovar/recusar cadastros de membros comuns.
  bool get podeAprovarMembro => isSuperAdmin || _isLiderancaMinisterial;

  /// Acesso ao módulo de gestão da liderança. Somente pastor da unidade ou
  /// `super_admin` — líder, diácono, evangelista e tesoureiro não entram.
  bool get podeGerenciarLideranca => isSuperAdmin || _isPastorDaUnidade;

  /// Editar a configuração institucional da unidade.
  bool get podeConfigurarIgreja => isSuperAdmin || _isPastorDaUnidade;

  /// Criar/remover unidades da rede.
  bool get podeGerenciarIgrejas => isSuperAdmin;

  /// Leitura da auditoria da unidade.
  bool get podeLerAuditoria => isSuperAdmin || _isLiderancaMinisterial;

  /// Auditoria é sempre gravada pelo Admin SDK. Constante por decisão de
  /// arquitetura: nenhum cliente escreve auditoria.
  bool get podeEscreverAuditoria => false;

  // ── Ciclo de vida da liderança ──────────────────────────────────────

  /// Pode alterar o perfil/vínculo de [alvo] (promover, rebaixar, inativar)?
  ///
  /// Restrições, além de exigir pastor da unidade ou `super_admin`:
  /// - pastor não age sobre si mesmo;
  /// - pastor não age sobre outro pastor (troca de pastor exige `super_admin`);
  /// - o alvo precisa pertencer à mesma unidade.
  bool podeGerenciarCicloDeVidaDe(VinculoIgreja alvo) {
    if (alvo.igrejaId != igrejaId) return false;
    if (isSuperAdmin) return true;
    if (!_isPastorDaUnidade) return false;
    if (alvo.uid == uid) return false;
    if (alvo.perfil.isPastor) return false;
    return true;
  }

  /// Motivo pelo qual a operação foi negada — para mensagem de interface.
  /// `null` quando é permitida.
  String? motivoNegativaCicloDeVida(VinculoIgreja alvo) {
    if (alvo.igrejaId != igrejaId) {
      return 'Esta pessoa pertence a outra unidade.';
    }
    if (isSuperAdmin) return null;
    if (!_isPastorDaUnidade) {
      return 'Somente o pastor da unidade ou o superadministrador pode alterar a liderança.';
    }
    if (alvo.uid == uid) {
      return 'Um pastor não pode alterar o próprio vínculo. Solicite ao superadministrador.';
    }
    if (alvo.perfil.isPastor) {
      return 'Alterar o vínculo de um pastor exige o superadministrador.';
    }
    return null;
  }
}
