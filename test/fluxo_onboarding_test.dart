import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/features/igrejas/providers/igreja_providers.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fluxo de primeira entrada e troca de unidade.
///
/// Estes testes exercitam os PROVIDERS que decidem a primeira tela e o escopo
/// de dados. Eles substituem parte do teste manual no aparelho: o que não
/// cobrem é o toque na interface e a renderização de cada tela.
void main() {
  final olinda = IgrejaId('olinda');
  final petrolina = IgrejaId('petrolina');

  /// Espera a leitura assíncrona do SharedPreferences terminar.
  Future<void> aguardarPreferencias(ProviderContainer c) async {
    while (!c.read(igrejaVisualizadaProvider).carregado) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('Primeira abertura', () {
    test('sem preferência salva, não há unidade em foco', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);

      await aguardarPreferencias(c);

      // É este estado que faz o gate abrir "Selecione uma igreja".
      expect(c.read(igrejaVisualizadaProvider).id, isNull);
      expect(c.read(igrejaAtualProvider), isNull);
    });

    test('enquanto carrega, o gate não decide', () {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);

      // Sem o flag `carregado`, o gate mostraria a seleção por um instante
      // mesmo para quem já escolheu — a tela piscaria.
      expect(c.read(igrejaVisualizadaProvider).carregado, isFalse);
      expect(c.read(preferenciaIgrejaCarregandoProvider), isTrue);
    });

    test('escolher Petrolina define o foco e persiste', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await aguardarPreferencias(c);

      await c.read(igrejaVisualizadaProvider.notifier).definir(petrolina);

      expect(c.read(igrejaAtualProvider), petrolina);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('igreja_visualizada_id'), 'petrolina');
    });

    test('reiniciar o app mantém Petrolina', () async {
      // Simula a reabertura: novo container lendo o disco já gravado.
      SharedPreferences.setMockInitialValues({
        'igreja_visualizada_id': 'petrolina',
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await aguardarPreferencias(c);

      expect(c.read(igrejaAtualProvider), petrolina);
      // Com unidade definida o gate vai para "Bem-vindo", não para a seleção.
      expect(c.read(igrejaVisualizadaProvider).temEscolha, isTrue);
    });

    test('preferência corrompida não vira escopo', () async {
      SharedPreferences.setMockInitialValues({
        'igreja_visualizada_id': '',
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await aguardarPreferencias(c);

      expect(c.read(igrejaAtualProvider), isNull);
    });
  });

  group('Troca de unidade pelo visitante', () {
    test('trocar para Olinda muda o escopo', () async {
      SharedPreferences.setMockInitialValues({
        'igreja_visualizada_id': 'petrolina',
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await aguardarPreferencias(c);

      expect(c.read(igrejaAtualProvider), petrolina);

      await c.read(igrejaVisualizadaProvider.notifier).definir(olinda);

      expect(c.read(igrejaAtualProvider), olinda);
      // O escopo de dados acompanha: é isto que troca o conteúdo das telas.
      expect(c.read(igrejaScopeProvider)?.igrejaId, olinda);
    });

    test('limpar volta a não ter unidade escolhida', () async {
      SharedPreferences.setMockInitialValues({
        'igreja_visualizada_id': 'petrolina',
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await aguardarPreferencias(c);

      await c.read(igrejaVisualizadaProvider.notifier).limpar();

      expect(c.read(igrejaVisualizadaProvider).id, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('igreja_visualizada_id'), isNull);
    });
  });

  group('Escopo de dados segue a unidade em foco', () {
    test('sem unidade não há escopo — nenhuma consulta é montada', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await aguardarPreferencias(c);

      expect(c.read(igrejaScopeProvider), isNull);
    });

    test('o escopo aponta para a coleção da unidade correta', () async {
      SharedPreferences.setMockInitialValues({
        'igreja_visualizada_id': 'petrolina',
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await aguardarPreferencias(c);

      final escopo = c.read(igrejaScopeProvider);
      expect(escopo, isNotNull);
      expect(escopo!.igrejaId, petrolina);
      // Nunca o caminho de Olinda.
      expect(escopo.igrejaId, isNot(olinda));
    });
  });

  group('Visitante não recebe permissão', () {
    test('sem sessão não há autorização em nenhuma unidade', () async {
      SharedPreferences.setMockInitialValues({
        'igreja_visualizada_id': 'petrolina',
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await aguardarPreferencias(c);

      // `autorizacaoAtualProvider` exige usuário; visitante não tem.
      expect(c.read(autorizacaoAtualProvider), isNull);
      expect(c.read(isLiderancaNaUnidadeProvider), isFalse);
      expect(c.read(podeGerenciarConteudoProvider), isFalse);
      expect(c.read(isMembroAprovadoAtualProvider), isFalse);
    });
  });
}
