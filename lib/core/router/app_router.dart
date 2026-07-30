import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/data/usuario_model.dart';
import '../../shared/widgets/placeholder_tela.dart';

// ── Rotas ──────────────────────────────────────────────────────────────────

abstract class Rotas {
  static const landing = '/';
  static const login = '/login';
  static const registro = '/registro';
  static const esqueciSenha = '/esqueci-senha';
  static const aguardandoAprovacao = '/aguardando-aprovacao';
  static const painel = '/painel';
  static const avisos = '/avisos';
  static const eventos = '/eventos';
  static const oracao = '/oracao';
  static const biblia = '/biblia';
  static const celula = '/celula';
  static const contribuir = '/contribuir';
  static const campanhas = '/campanhas';
  static const perfil = '/perfil';
  static const editarPerfil = '/perfil/editar';
  static const sobre = '/sobre';
  static const pixQr = '/contribuir/pix';
  static const cartaoWebview = '/contribuir/cartao';
}

// ── Provider ───────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final usuarioAsync = ref.watch(usuarioAtualProvider);

  return GoRouter(
    initialLocation: Rotas.landing,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final usuario = usuarioAsync.valueOrNull;
      final estaAutenticado = usuario != null;
      final rotaAtual = state.matchedLocation;

      final rotasPublicas = {
        Rotas.landing,
        Rotas.login,
        Rotas.registro,
        Rotas.esqueciSenha,
        Rotas.sobre,
      };

      // Não autenticado tentando acessar rota protegida
      if (!estaAutenticado && !rotasPublicas.contains(rotaAtual)) {
        return Rotas.landing;
      }

      // Autenticado mas com cadastro pendente
      if (estaAutenticado &&
          usuario.status == StatusUsuario.pendente &&
          rotaAtual != Rotas.aguardandoAprovacao) {
        return Rotas.aguardandoAprovacao;
      }

      // Autenticado e aprovado tentando acessar telas de auth
      if (estaAutenticado &&
          usuario.isAprovado &&
          (rotaAtual == Rotas.login ||
              rotaAtual == Rotas.registro ||
              rotaAtual == Rotas.landing)) {
        return Rotas.painel;
      }

      return null;
    },
    routes: [
      // ── Área pública ──────────────────────────────────────────────────
      GoRoute(
        path: Rotas.landing,
        builder: (context, _) => const PlaceholderTela(titulo: 'Landing Page', icone: Icons.church_rounded),
      ),
      GoRoute(
        path: Rotas.sobre,
        builder: (context, _) => const PlaceholderTela(titulo: 'Sobre a Igreja', icone: Icons.info_rounded),
      ),

      // ── Auth ──────────────────────────────────────────────────────────
      GoRoute(
        path: Rotas.login,
        builder: (context, _) => const PlaceholderTela(titulo: 'Login', icone: Icons.login_rounded),
      ),
      GoRoute(
        path: Rotas.registro,
        builder: (context, _) => const PlaceholderTela(titulo: 'Cadastro', icone: Icons.person_add_rounded),
      ),
      GoRoute(
        path: Rotas.esqueciSenha,
        builder: (context, _) => const PlaceholderTela(titulo: 'Recuperar Senha', icone: Icons.lock_reset_rounded),
      ),
      GoRoute(
        path: Rotas.aguardandoAprovacao,
        builder: (context, _) => const PlaceholderTela(titulo: 'Aguardando Aprovação', icone: Icons.hourglass_empty_rounded),
      ),

      // ── App (membros aprovados) ───────────────────────────────────────
      GoRoute(
        path: Rotas.painel,
        builder: (context, _) => const PlaceholderTela(titulo: 'Painel', icone: Icons.home_rounded),
      ),
      GoRoute(
        path: Rotas.avisos,
        builder: (context, _) => const PlaceholderTela(titulo: 'Avisos', icone: Icons.notifications_rounded),
      ),
      GoRoute(
        path: Rotas.eventos,
        builder: (context, _) => const PlaceholderTela(titulo: 'Eventos', icone: Icons.calendar_today_rounded),
      ),
      GoRoute(
        path: Rotas.oracao,
        builder: (context, _) => const PlaceholderTela(titulo: 'Oração', icone: Icons.favorite_rounded),
      ),
      GoRoute(
        path: Rotas.biblia,
        builder: (context, _) => const PlaceholderTela(titulo: 'Bíblia', icone: Icons.menu_book_rounded),
      ),
      GoRoute(
        path: Rotas.celula,
        builder: (context, _) => const PlaceholderTela(titulo: 'Minha Célula', icone: Icons.groups_rounded),
      ),
      GoRoute(
        path: Rotas.contribuir,
        builder: (context, _) => const PlaceholderTela(titulo: 'Contribuir', icone: Icons.volunteer_activism_rounded),
      ),
      GoRoute(
        path: Rotas.pixQr,
        builder: (context, _) => const PlaceholderTela(titulo: 'PIX', icone: Icons.qr_code_rounded),
      ),
      GoRoute(
        path: Rotas.cartaoWebview,
        builder: (context, _) => const PlaceholderTela(titulo: 'Cartão', icone: Icons.credit_card_rounded),
      ),
      GoRoute(
        path: Rotas.campanhas,
        builder: (context, _) => const PlaceholderTela(titulo: 'Campanhas', icone: Icons.campaign_rounded),
      ),
      GoRoute(
        path: Rotas.perfil,
        builder: (context, _) => const PlaceholderTela(titulo: 'Perfil', icone: Icons.person_rounded),
      ),
      GoRoute(
        path: Rotas.editarPerfil,
        builder: (context, _) => const PlaceholderTela(titulo: 'Editar Perfil', icone: Icons.edit_rounded),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Página não encontrada: ${state.matchedLocation}'),
      ),
    ),
  );
});
