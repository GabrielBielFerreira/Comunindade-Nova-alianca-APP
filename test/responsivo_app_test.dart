import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nova_alianca_app/features/auth/data/usuario_model.dart';
import 'package:nova_alianca_app/features/auth/providers/auth_provider.dart';
import 'package:nova_alianca_app/features/eventos/data/evento_model.dart';
import 'package:nova_alianca_app/features/eventos/providers/eventos_providers.dart';
import 'package:nova_alianca_app/features/ministerios/providers/ministerios_providers.dart';
import 'package:nova_alianca_app/features/notificacoes/providers/notificacoes_providers.dart';
import 'package:nova_alianca_app/features/palavra_dia/palavra_do_dia.dart';
import 'package:nova_alianca_app/visual/escala_tela.dart';
import 'package:nova_alianca_app/visual/screens/home_screen.dart';
import 'package:nova_alianca_app/visual/screens/programacao_screen.dart';

import 'responsivo.dart';

final _usuario = UsuarioModel(
  uid: 'uid-teste',
  // Nome longo de propósito: é o que estoura cabeçalho estreito.
  nome: 'Maria das Graças Albuquerque de Vasconcelos',
  email: 'maria@exemplo.com',
  telefone: '(81) 99999-0000',
  dataCadastro: DateTime(2026, 1, 10),
  perfil: PerfilUsuario.membro,
  status: StatusUsuario.aprovado,
  igrejaPrincipalId: 'olinda',
);

final _eventos = <EventoModel>[
  EventoModel(
    id: 'e1',
    titulo: 'Culto de celebração e santa ceia da Comunidade Nova Aliança',
    descricao: 'Culto mensal com participação de todos os ministérios.',
    data: DateTime(2026, 9, 6, 19),
    horario: '19:00',
    local: 'Templo sede — Av. Presidente Kennedy, 1200, Olinda/PE',
    tipo: TipoEvento.culto,
    publico: true,
    criadoPor: 'uid-pastor',
    confirmadosCount: 42,
  ),
];

final _palavra = PalavraDoDia(
  id: '250',
  texto: 'O Senhor é o meu pastor; nada me faltará.',
  referencia: 'Salmos 23:1',
  traducao: 'NVI',
  data: DateTime(2026, 8, 17),
);

Widget _app(Widget tela) {
  return ProviderScope(
    overrides: [
      usuarioProvider.overrideWithValue(_usuario),
      naoLidasCountProvider.overrideWith((ref) => 3),
      eventosStreamProvider.overrideWith((ref) => Stream.value(_eventos)),
      meuMinisterioProvider.overrideWith((ref) async => null),
      palavraDoDiaProvider.overrideWith((ref) async => _palavra),
    ],
    child: MaterialApp(home: tela),
  );
}

void main() {
  // As telas formatam datas em pt_BR; sem isto o `intl` lança antes mesmo de
  // haver layout para avaliar.
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('Escala de layout', () {
    test('o piso da escala cobre a menor tela suportada', () {
      // Antes o piso era 0.86, que desenhava 394 × 0.86 ≈ 339 px dentro de
      // uma tela de 320 px. Agora a largura desenhada nunca passa da tela.
      expect(escalaPara(320) * larguraDeReferencia, lessThanOrEqualTo(320.0));
      expect(escalaPara(360) * larguraDeReferencia, lessThanOrEqualTo(360.0));
      expect(escalaPara(390) * larguraDeReferencia, lessThanOrEqualTo(390.0));
    });

    test('não amplia além do desenho original em telas largas', () {
      expect(escalaPara(1440), 1.0);
      expect(escalaPara(768), 1.0);
    });

    test('o piso protege larguras absurdamente pequenas', () {
      expect(escalaPara(100), escalaMinima);
    });
  });

  group('Home do aplicativo', () {
    paraCadaTamanho('não estoura', (tester, tamanho, escala) async {
      await esperarSemOverflow(
        tester,
        _app(const HomeScreen()),
        tamanho: tamanho,
        escalaTexto: escala,
      );
    });

    testWidgets('saúda com o primeiro nome real do usuário', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(const HomeScreen()));
      await tester.pump();

      expect(find.textContaining('MARIA'), findsWidgets);
    });
  });

  group('Programação do aplicativo', () {
    paraCadaTamanho('não estoura', (tester, tamanho, escala) async {
      await esperarSemOverflow(
        tester,
        _app(const ProgramacaoScreen(isLeader: false)),
        tamanho: tamanho,
        escalaTexto: escala,
      );
    });
  });
}
