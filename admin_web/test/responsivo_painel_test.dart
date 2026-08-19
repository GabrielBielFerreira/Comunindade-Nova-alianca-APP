import 'package:admin_web/dados/acessos.dart';
import 'package:admin_web/dados/auditoria_repository.dart';
import 'package:admin_web/dados/conteudo_repository.dart';
import 'package:admin_web/dados/financas_repository.dart';
import 'package:admin_web/dados/membros_repository.dart';
import 'package:admin_web/estado/providers.dart';
import 'package:admin_web/telas/dashboard_tela.dart';
import 'package:admin_web/telas/login_tela.dart';
import 'package:admin_web/ui/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import 'responsivo.dart';

// ══════════════════════════════════════════════════════════════════════
// Dados de teste
//
// Textos longos de propósito: nome de unidade comprido, aviso com título
// extenso e motivo de auditoria grande são exatamente o que estoura layout.
// ══════════════════════════════════════════════════════════════════════

AcessoIgreja acessoCompleto({bool lerFinancas = true}) => AcessoIgreja(
      igrejaId: IgrejaId('olinda'),
      nome: 'Comunidade Nova Aliança — Olinda (Sede)',
      ativa: true,
      perfil: PerfilComunitario.pastor,
      status: 'aprovado',
      funcoesAdmin: {FuncaoAdmin.tesoureiro, FuncaoAdmin.editor},
      acessarPainel: true,
      lerFinancas: lerFinancas,
      gerenciarConteudo: true,
      moderarOracao: true,
      aprovarMembro: true,
      gerenciarLideranca: true,
    );

final _avisos = <Aviso>[
  Aviso(
    id: 'a1',
    titulo: 'Reunião extraordinária de liderança neste sábado às 19h',
    conteudo: 'Todos os líderes de ministério devem comparecer.',
    prioridade: 'urgente',
    publicadoEm: DateTime(2026, 8, 10),
  ),
  Aviso(
    id: 'a2',
    titulo: 'Escala de limpeza',
    conteudo: 'Confira a escala do mês.',
    publicadoEm: DateTime(2026, 8, 5),
  ),
];

final _eventos = <Evento>[
  Evento(
    id: 'e1',
    titulo: 'Culto de celebração e santa ceia da Comunidade Nova Aliança',
    descricao: 'Culto mensal.',
    data: DateTime(2026, 9, 6, 19),
    local: 'Templo sede — Av. Presidente Kennedy, 1200',
  ),
];

final _oracoes = <PedidoOracao>[
  const PedidoOracao(
    id: 'p1',
    texto: 'Peço oração pela saúde da minha mãe, que está internada.',
    autorNome: 'Maria',
    urgente: true,
  ),
];

final _auditoria = <RegistroAuditoria>[
  RegistroAuditoria(
    id: 'r1',
    acao: 'remover_da_lideranca',
    autorId: 'uid-pastor',
    autorSuperAdmin: true,
    motivo: 'Mudança de ministério solicitada pela própria pessoa',
    em: DateTime(2026, 8, 12, 14, 30),
  ),
];

final _igreja = IgrejaModel(
  id: IgrejaId('olinda'),
  nome: 'Comunidade Nova Aliança — Olinda (Sede)',
  ativa: true,
  configurada: false,
);

/// Painel montado com dados reais de teste — nenhum acesso a Firebase.
Widget painelComDados({required AcessoIgreja acesso}) {
  return ProviderScope(
    overrides: [
      // Sem sessão resolvida no teste: a saudação usa o texto neutro em vez
      // de inventar um nome.
      authStateProvider.overrideWith((ref) => Stream.value(null)),
      meusAcessosProvider.overrideWith(
        (ref) async => MeusAcessos(
          uid: 'uid-pastor',
          isSuperAdmin: false,
          acessos: [acesso],
        ),
      ),
      acessoAtualProvider.overrideWithValue(acesso),
      contagemMembrosProvider.overrideWith(
        (ref) async => const ContagemMembros(
          pendentes: 12,
          aprovados: 1284,
          inativos: 37,
          lideranca: 19,
        ),
      ),
      resumoFinanceiroProvider.overrideWith(
        (ref) async => const ResumoFinanceiroUnidade(
          aprovadoCentavos: 1854390,
          pendenteCentavos: 32000,
          quantidade: 214,
        ),
      ),
      avisosRecentesProvider.overrideWith((ref) => Stream.value(_avisos)),
      proximosEventosProvider.overrideWith((ref) => Stream.value(_eventos)),
      oracoesPendentesProvider.overrideWith(
        (ref) => Stream.value(Pagina(itens: _oracoes, truncada: false)),
      ),
      igrejaAtualProvider.overrideWith((ref) => Stream.value(_igreja)),
      auditoriaRecenteProvider.overrideWith((ref) => Stream.value(_auditoria)),
      // Fontes da busca — só consultadas quando há termo digitado.
      membrosProvider.overrideWith(
        (ref) => Stream.value(const Pagina(itens: [], truncada: false)),
      ),
      ministeriosProvider.overrideWith(
        (ref) => Stream.value(const Pagina(itens: [], truncada: false)),
      ),
      avisosProvider.overrideWith(
        (ref) => Stream.value(Pagina(itens: _avisos, truncada: true)),
      ),
      eventosProvider.overrideWith(
        (ref) => Stream.value(Pagina(itens: _eventos, truncada: false)),
      ),
    ],
    child: MaterialApp(
      theme: TemaPainel.claro(),
      home: const Scaffold(body: DashboardTela()),
    ),
  );
}

void main() {
  // Sem esta verificação, os testes de responsividade poderiam passar por não
  // detectarem nada — e não por não haver overflow.
  group('O detector de overflow funciona', () {
    testWidgets('uma Row propositalmente larga demais é reprovada',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(children: [SizedBox(width: 900, height: 20)]),
          ),
        ),
      );
      await tester.pump();

      final erro = tester.takeException();
      expect(erro, isNotNull);
      expect('$erro', contains('overflowed'));
    });
  });

  group('Login do painel', () {
    paraCadaTamanho('não estoura', (tester, tamanho, escala) async {
      await esperarSemOverflow(
        tester,
        const ProviderScope(
          child: MaterialApp(home: LoginTela()),
        ),
        tamanho: tamanho,
        escalaTexto: escala,
      );
    });

    testWidgets('identifica o painel e oferece recuperação de senha',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginTela())),
      );
      await tester.pump();

      expect(find.text('Painel de Gestão'), findsOneWidget);
      expect(find.text('Nova Aliança'), findsOneWidget);
      expect(find.text('Esqueci minha senha'), findsOneWidget);
      // Sem faixa de emulador: o teste roda com APP_ENV padrão (produção).
      expect(find.textContaining('EMULADOR'), findsNothing);
    });
  });

  group('Dashboard do painel', () {
    paraCadaTamanho('não estoura com dados reais', (tester, tamanho, escala) async {
      await esperarSemOverflow(
        tester,
        painelComDados(acesso: acessoCompleto()),
        tamanho: tamanho,
        escalaTexto: escala,
      );
      // Deixa os providers assíncronos resolverem e repinta.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('mostra contagens reais e o resumo financeiro', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(painelComDados(acesso: acessoCompleto()));
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget); // pendentes
      expect(find.text('1284'), findsOneWidget); // aprovados
      expect(find.text('19'), findsOneWidget); // liderança
      expect(find.text('Finanças'), findsWidgets);
      expect(find.textContaining('Configuração da unidade'), findsOneWidget);
      // Status informativo do Mercado Pago, sem ação.
      expect(find.text('Mercado Pago'), findsOneWidget);
      expect(
        find.textContaining('Pagamentos online estão desativados'),
        findsOneWidget,
      );
    });

    testWidgets('sem ler_financas o painel não mostra valores', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        painelComDados(acesso: acessoCompleto(lerFinancas: false)),
      );
      await tester.pumpAndSettle();

      // Nenhum total financeiro aparece, e a ação rápida some.
      expect(find.text('Recebido (aprovado)'), findsNothing);
      expect(find.text('Ver finanças'), findsNothing);
    });

    testWidgets('unidade não configurada é dita com honestidade',
        (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(painelComDados(acesso: acessoCompleto()));
      await tester.pumpAndSettle();

      expect(find.text('não configurada'), findsOneWidget);
      expect(
        find.textContaining('Dados oficiais ainda não informados'),
        findsOneWidget,
      );
    });
  });

  group('Saudação', () {
    test('usa o primeiro nome quando há displayName', () {
      expect(
        SaudacaoDashboard.primeiroNome('Gabriel Ferreira', 'g@exemplo.com'),
        'Gabriel',
      );
    });

    test('sem displayName, usa a parte local do e-mail', () {
      expect(SaudacaoDashboard.primeiroNome(null, 'pastor@exemplo.com'),
          'pastor');
    });

    test('sem nenhum dado, não inventa nome', () {
      expect(SaudacaoDashboard.primeiroNome(null, null), 'Bem-vindo');
    });

    test('cumprimento acompanha o horário', () {
      expect(SaudacaoDashboard.cumprimento(DateTime(2026, 8, 17, 9)), 'Bom dia');
      expect(
          SaudacaoDashboard.cumprimento(DateTime(2026, 8, 17, 15)), 'Boa tarde');
      expect(
          SaudacaoDashboard.cumprimento(DateTime(2026, 8, 17, 21)), 'Boa noite');
    });
  });
}
