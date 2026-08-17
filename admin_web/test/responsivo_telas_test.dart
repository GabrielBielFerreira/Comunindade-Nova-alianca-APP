import 'package:admin_web/dados/acessos.dart';
import 'package:admin_web/dados/conteudo_repository.dart';
import 'package:admin_web/dados/membros_repository.dart';
import 'package:admin_web/estado/providers.dart';
import 'package:admin_web/telas/conteudo_telas.dart';
import 'package:admin_web/telas/financas_tela.dart';
import 'package:admin_web/telas/membros_tela.dart';
import 'package:admin_web/ui/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import 'responsivo.dart';
import 'responsivo_painel_test.dart' show acessoCompleto;

final _igrejaId = IgrejaId('olinda');

MembroPainel _membro(
  String uid,
  String nome,
  StatusVinculo status,
  PerfilComunitario perfil,
) =>
    MembroPainel(
      vinculo: VinculoIgreja(
        uid: uid,
        igrejaId: _igrejaId,
        status: status,
        perfil: perfil,
      ),
      nome: nome,
      email: '$uid@exemplo.com',
    );

// Nomes longos de propósito: é o caso que quebra linha e estoura cartão.
final _membros = <MembroPainel>[
  _membro('m1', 'Maria das Graças Albuquerque de Vasconcelos',
      StatusVinculo.pendente, PerfilComunitario.membro),
  _membro('m2', 'João Pedro', StatusVinculo.aprovado, PerfilComunitario.pastor),
  _membro('m3', 'Ana', StatusVinculo.inativo, PerfilComunitario.membro),
];

final _transacoes = <Transacao>[
  Transacao(
    id: 't1',
    usuarioId: 'm2',
    igrejaId: _igrejaId,
    valorCentavos: 1250000,
    tipo: TipoContribuicao.dizimo,
    metodo: MetodoPagamento.pix,
    status: StatusTransacao.aprovado,
    criadoEm: DateTime(2026, 8, 1),
  ),
  Transacao(
    id: 't2',
    usuarioId: 'm1',
    igrejaId: _igrejaId,
    valorCentavos: 5000,
    tipo: TipoContribuicao.oferta,
    metodo: MetodoPagamento.pix,
    status: StatusTransacao.pendente,
    criadoEm: DateTime(2026, 8, 12),
  ),
];

final _eventos = <Evento>[
  Evento(
    id: 'e1',
    titulo: 'Culto de celebração e santa ceia da Comunidade Nova Aliança',
    descricao: 'Culto mensal com participação de todos os ministérios.',
    data: DateTime(2026, 9, 6, 19),
    local: 'Templo sede — Av. Presidente Kennedy, 1200, Olinda/PE',
  ),
];

Widget _tela(Widget corpo, {required AcessoIgreja acesso, bool comRota = false}) {
  final overrides = [
    authStateProvider.overrideWith((ref) => Stream.value(null)),
    meusAcessosProvider.overrideWith(
      (ref) async =>
          MeusAcessos(uid: 'uid', isSuperAdmin: false, acessos: [acesso]),
    ),
    acessoAtualProvider.overrideWithValue(acesso),
    membrosProvider.overrideWith(
      (ref) => Stream.value(Pagina(itens: _membros, truncada: true)),
    ),
    transacoesProvider.overrideWith(
      (ref) => Stream.value(Pagina(itens: _transacoes, truncada: false)),
    ),
    eventosProvider.overrideWith(
      (ref) => Stream.value(Pagina(itens: _eventos, truncada: false)),
    ),
  ];

  // A tela de Programação lê a query string via GoRouter (`?novo=1`), então
  // precisa de um router de verdade.
  if (comRota) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: TemaPainel.claro(),
        routerConfig: GoRouter(
          initialLocation: '/programacao',
          routes: [
            GoRoute(path: '/programacao', builder: (_, _) => corpo),
          ],
        ),
      ),
    );
  }

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(theme: TemaPainel.claro(), home: Scaffold(body: corpo)),
  );
}

void main() {
  group('Membros', () {
    paraCadaTamanho('não estoura', (tester, tamanho, escala) async {
      await esperarSemOverflow(
        tester,
        _tela(const MembrosTela(), acesso: acessoCompleto()),
        tamanho: tamanho,
        escalaTexto: escala,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('avisa quando a lista foi truncada', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _tela(const MembrosTela(), acesso: acessoCompleto()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Exibindo os primeiros'), findsOneWidget);
    });
  });

  group('Finanças', () {
    paraCadaTamanho('não estoura', (tester, tamanho, escala) async {
      await esperarSemOverflow(
        tester,
        _tela(const FinancasTela(), acesso: acessoCompleto()),
        tamanho: tamanho,
        escalaTexto: escala,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('bloqueia quem não tem leitura financeira', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1024, 768);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _tela(
          const FinancasTela(),
          acesso: acessoCompleto(lerFinancas: false),
        ),
      );
      await tester.pumpAndSettle();

      // Nenhum valor vaza para perfil sem permissão.
      expect(find.textContaining('12.500,00'), findsNothing);
    });
  });

  group('Programação', () {
    paraCadaTamanho('não estoura', (tester, tamanho, escala) async {
      await esperarSemOverflow(
        tester,
        _tela(const ProgramacaoTela(), acesso: acessoCompleto(), comRota: true),
        tamanho: tamanho,
        escalaTexto: escala,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
