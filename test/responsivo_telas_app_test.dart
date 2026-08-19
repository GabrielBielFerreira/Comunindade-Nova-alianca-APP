import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nova_alianca_app/features/auth/data/usuario_model.dart';
import 'package:nova_alianca_app/features/auth/providers/auth_provider.dart';
import 'package:nova_alianca_app/visual/screens/ajuda_screen.dart';
import 'package:nova_alianca_app/visual/screens/conhecer_visitante_screen.dart';
import 'package:nova_alianca_app/visual/screens/email_enviado_screen.dart';
import 'package:nova_alianca_app/visual/screens/entraconta_screen.dart';
import 'package:nova_alianca_app/visual/screens/gestao_entry_screen.dart';
import 'package:nova_alianca_app/visual/screens/recuperar_senha_screen.dart';
import 'package:nova_alianca_app/visual/screens/sobre_comunidade_screen.dart';
import 'package:nova_alianca_app/visual/screens/welcome_access_screen.dart';

import 'responsivo.dart';

/// Varredura de overflow nas telas do aplicativo.
///
/// `responsivo_app_test.dart` cobria duas telas (Home e Programação). O
/// aplicativo tem trinta e seis. Este arquivo estende a medição às telas que
/// não dependem de consulta ao Firestore para desenhar — as demais precisam de
/// fixtures próprias e entram depois.
///
/// O teste não julga aparência: ele falha quando algo foi CORTADO da tela.
final _usuario = UsuarioModel(
  uid: 'uid-teste',
  // Nome longo de propósito: é o que estoura cabeçalho estreito.
  nome: 'Maria das Graças Albuquerque de Vasconcelos',
  email: 'maria.das.gracas.albuquerque@exemplo.com.br',
  telefone: '(81) 99999-0000',
  dataCadastro: DateTime(2026, 1, 10),
  perfil: PerfilUsuario.membro,
  status: StatusUsuario.aprovado,
  igrejaPrincipalId: 'olinda',
);

Widget _app(Widget tela) {
  return ProviderScope(
    overrides: [usuarioProvider.overrideWithValue(_usuario)],
    child: MaterialApp(home: tela),
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  // Sem esta prova, a tolerancia sub-pixel do detector poderia crescer sem
  // ninguem perceber e a varredura inteira passaria a aprovar tudo.
  group('O detector continua reprovando corte de verdade', () {
    testWidgets('uma Row larga demais e reprovada', (tester) async {
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
      expect(erro.toString(), contains('overflowed'));
    });

    testWidgets('um estouro de 2 px tambem e reprovado', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(children: [SizedBox(width: 322, height: 20)]),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNotNull);
    });
  });

  final telas = <String, Widget Function()>{
    'Bem-vindo': () => const WelcomeAccessScreen(),
    'Entrar': () => const EntracontaScreen(),
    'Recuperar senha': () => const RecuperarSenhaScreen(),
    'E-mail enviado': () => const EmailEnviadoScreen(),
    'Ajuda': () => const AjudaScreen(),
    'Sobre a comunidade': () => const SobreComunidadeScreen(),
    'Conhecer (visitante)': () => const ConhecerVisitanteScreen(),
    'Entrada da gestão': () => const GestaoEntryScreen(),
  };

  for (final entrada in telas.entries) {
    group(entrada.key, () {
      paraCadaTamanho('não estoura', (tester, tamanho, escala) async {
        await esperarSemOverflow(
          tester,
          _app(entrada.value()),
          tamanho: tamanho,
          escalaTexto: escala,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    });
  }
}
