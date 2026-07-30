import 'package:flutter/widgets.dart';

import 'mock/programacao_mock_data.dart';
import 'screens/cadastro_screen.dart';
import 'screens/avisos_screen.dart';
import 'screens/aviso_detalhes_screen.dart';
import 'screens/contribuir_screen.dart';
import 'mock/avisos_mock_data.dart';
import 'screens/email_enviado_screen.dart';
import 'screens/entraconta_screen.dart';
import 'screens/gestao_entry_screen.dart';
import 'screens/home_leader_screen.dart';
import 'screens/home_member_screen.dart';
import 'screens/historico_contribuicoes_screen.dart';
import 'screens/mural_oracao_screen.dart';
import 'screens/oracao_screen.dart';
import 'screens/pagamento_boleto_screen.dart';
import 'screens/pagamento_cartao_screen.dart';
import 'screens/pagamento_pix_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/programacao_detalhes_screen.dart';
import 'screens/programacao_screen.dart';
import 'screens/recuperar_senha_screen.dart';
import 'screens/revisar_contribuicao_screen.dart';
import 'screens/select_church_screen.dart';
import 'screens/status_contribuicao_screen.dart';
import 'screens/welcome_access_screen.dart';
import 'screens/home_visitante_screen.dart';
import 'screens/conhecer_visitante_screen.dart';
import 'screens/notificacoes_screen.dart';
import 'screens/configuracoes_screen.dart';
import 'screens/visualizar_outra_igreja_screen.dart';
import 'screens/dados_pessoais_screen.dart';
import '../features/admin/screens/cadastros_pendentes_screen.dart';
import '../features/biblia/screens/biblia_home_screen.dart';
import '../features/cantor/screens/cantor_home_screen.dart';
import '../features/devocionais/screens/devocionais_screen.dart';
import '../features/escola_louvor/screens/escola_louvor_screen.dart';
import '../features/ministerios/screens/meu_ministerio_screen.dart';

abstract class VisualRoutes {
  static const entraconta = '/';
  static const login = '/login';
  static const selectChurch = '/select-church';
  static const welcomeAccess = '/welcome-access';
  static const cadastro = '/cadastro';
  static const recuperarSenha = '/recuperar-senha';
  static const emailEnviado = '/email-enviado';
  static const home = '/home';
  static const homeMember = '/home-member';
  static const homeLeader = '/home-leader';
  static const gestao = '/gestao';
  static const avisos = '/avisos';
  static const avisosLeader = '/avisos-lider';
  static const avisoDetalhes = '/aviso-detalhes';
  static const programacao = '/programacao';
  static const programacaoLeader = '/programacao-lider';
  static const programacaoDetalhes = '/programacao-detalhes';
  static const oracao = '/oracao';
  static const oracaoLeader = '/oracao-lider';
  static const muralOracao = '/mural-oracao';
  static const muralOracaoLeader = '/mural-oracao-lider';
  static const contribuir = '/contribuir';
  static const contribuirLeader = '/contribuir-lider';
  static const escolherMetodoPagamento = '/escolher-metodo-pagamento';
  static const escolherMetodoPagamentoLeader =
      '/escolher-metodo-pagamento-lider';
  static const revisarContribuicao = '/revisar-contribuicao';
  static const revisarContribuicaoLeader = '/revisar-contribuicao-lider';
  static const pagamentoPix = '/pagamento-pix';
  static const pagamentoPixLeader = '/pagamento-pix-lider';
  static const pagamentoCartao = '/pagamento-cartao';
  static const pagamentoCartaoLeader = '/pagamento-cartao-lider';
  static const pagamentoBoleto = '/pagamento-boleto';
  static const pagamentoBoletoLeader = '/pagamento-boleto-lider';
  static const statusContribuicao = '/status-contribuicao';
  static const statusContribuicaoLeader = '/status-contribuicao-lider';
  static const historicoContribuicoes = '/historico-contribuicoes';
  static const historicoContribuicoesLeader = '/historico-contribuicoes-lider';
  static const perfil = '/perfil';
  static const perfilLeader = '/perfil-lider';
  static const visitorHome = '/visitor-home';
  static const conhecerVisitante = '/conhecer-visitante';
  static const programacaoVisitante = '/programacao-visitante';
  static const contribuirVisitante = '/contribuir-visitante';
  static const notificacoes = '/notificacoes';
  static const configuracoes = '/configuracoes';
  static const visualizarOutraIgreja = '/visualizar-outra-igreja';
  static const dadosPessoais = '/dados-pessoais';
  static const biblia = '/biblia';
  static const cantorCristao = '/cantor-cristao';
  static const cadastrosPendentes = '/cadastros-pendentes';
  static const meuMinisterio = '/meu-ministerio';
  static const devocionais = '/devocionais';
  static const escolaLouvor = '/escola-louvor';
}

final Map<String, WidgetBuilder> visualRoutes = {
  VisualRoutes.entraconta: (_) => const EntracontaScreen(),
  VisualRoutes.login: (_) => const EntracontaScreen(),
  VisualRoutes.selectChurch: (_) => const SelectChurchScreen(),
  VisualRoutes.welcomeAccess: (_) => const WelcomeAccessScreen(),
  VisualRoutes.cadastro: (_) => const CadastroScreen(),
  VisualRoutes.recuperarSenha: (_) => const RecuperarSenhaScreen(),
  VisualRoutes.emailEnviado: (_) => const EmailEnviadoScreen(),
  VisualRoutes.home: (_) => const HomeMemberScreen(),
  VisualRoutes.homeMember: (_) => const HomeMemberScreen(),
  VisualRoutes.homeLeader: (_) => const HomeLeaderScreen(),
  VisualRoutes.perfil: (_) => const PerfilScreen(isLeader: false),
  VisualRoutes.perfilLeader: (_) => const PerfilScreen(isLeader: true),
  VisualRoutes.gestao: (_) => const GestaoEntryScreen(),
  VisualRoutes.avisos: (_) => const AvisosScreen(isLeader: false),
  VisualRoutes.avisosLeader: (_) => const AvisosScreen(isLeader: true),
  VisualRoutes.programacao: (_) => const ProgramacaoScreen(isLeader: false),
  VisualRoutes.programacaoLeader: (_) =>
      const ProgramacaoScreen(isLeader: true),
  VisualRoutes.oracao: (_) => const OracaoScreen(isLeader: false),
  VisualRoutes.oracaoLeader: (_) => const OracaoScreen(isLeader: true),
  VisualRoutes.muralOracao: (_) => const MuralOracaoScreen(isLeader: false),
  VisualRoutes.muralOracaoLeader: (_) =>
      const MuralOracaoScreen(isLeader: true),
  VisualRoutes.contribuir: (_) => const ContribuirScreen(isLeader: false),
  VisualRoutes.contribuirLeader: (_) => const ContribuirScreen(isLeader: true),
  VisualRoutes.escolherMetodoPagamento: (_) =>
      const EscolherMetodoPagamentoScreen(isLeader: false),
  VisualRoutes.escolherMetodoPagamentoLeader: (_) =>
      const EscolherMetodoPagamentoScreen(isLeader: true),
  VisualRoutes.revisarContribuicao: (_) =>
      const RevisarContribuicaoScreen(isLeader: false),
  VisualRoutes.revisarContribuicaoLeader: (_) =>
      const RevisarContribuicaoScreen(isLeader: true),
  VisualRoutes.pagamentoPix: (_) => const PagamentoPixScreen(isLeader: false),
  VisualRoutes.pagamentoPixLeader: (_) =>
      const PagamentoPixScreen(isLeader: true),
  VisualRoutes.pagamentoCartao: (_) =>
      const PagamentoCartaoScreen(isLeader: false),
  VisualRoutes.pagamentoCartaoLeader: (_) =>
      const PagamentoCartaoScreen(isLeader: true),
  VisualRoutes.pagamentoBoleto: (_) =>
      const PagamentoBoletoScreen(isLeader: false),
  VisualRoutes.pagamentoBoletoLeader: (_) =>
      const PagamentoBoletoScreen(isLeader: true),
  VisualRoutes.statusContribuicao: (_) =>
      const StatusContribuicaoScreen(isLeader: false),
  VisualRoutes.statusContribuicaoLeader: (_) =>
      const StatusContribuicaoScreen(isLeader: true),
  VisualRoutes.historicoContribuicoes: (_) =>
      const HistoricoContribuicoesScreen(isLeader: false),
  VisualRoutes.historicoContribuicoesLeader: (_) =>
      const HistoricoContribuicoesScreen(isLeader: true),
  VisualRoutes.programacaoDetalhes: (_) => const ProgramacaoDetalhesScreen(
    details: ProgramacaoMockData.standardDetails,
    isLeader: false,
  ),
  VisualRoutes.avisoDetalhes: (_) => const AvisoDetalhesScreen(
    notice: AvisosMockData.cristoNoLar,
    isLeader: false,
  ),
  VisualRoutes.visitorHome: (_) => const HomeVisitanteScreen(),
  VisualRoutes.conhecerVisitante: (_) => const ConhecerVisitanteScreen(),
  VisualRoutes.programacaoVisitante: (_) =>
      const ProgramacaoScreen(isLeader: false, isVisitor: true),
  VisualRoutes.contribuirVisitante: (_) =>
      const ContribuirScreen(isLeader: false, isVisitor: true),
  VisualRoutes.notificacoes: (_) => const NotificacoesScreen(),
  VisualRoutes.configuracoes: (_) => const ConfiguracoesScreen(),
  VisualRoutes.visualizarOutraIgreja: (_) =>
      const VisualizarOutraIgrejaScreen(),
  VisualRoutes.dadosPessoais: (_) => const DadosPessoaisScreen(),
  VisualRoutes.biblia: (_) => const BibliaHomeScreen(),
  VisualRoutes.cantorCristao: (_) => const CantorHomeScreen(),
  VisualRoutes.cadastrosPendentes: (_) => const CadastrosPendentesScreen(),
  VisualRoutes.meuMinisterio: (_) => const MeuMinisterioScreen(),
  VisualRoutes.devocionais: (_) => const DevocionaisScreen(),
  VisualRoutes.escolaLouvor: (_) => const EscolaLouvorScreen(),
};
