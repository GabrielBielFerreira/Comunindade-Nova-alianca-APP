import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/core/data/igreja_scope.dart';
import 'package:nova_alianca_app/features/biblia/data/bible_models.dart';
import 'package:nova_alianca_app/features/biblia/data/bible_repository.dart';
import 'package:nova_alianca_app/features/biblia/providers/bible_providers.dart';
import 'package:nova_alianca_app/features/escola_louvor/screens/escola_louvor_screen.dart';
import 'package:nova_alianca_app/features/igrejas/providers/igreja_providers.dart';
import 'package:nova_alianca_app/features/palavra_dia/palavra_do_dia.dart';
import 'package:nova_alianca_app/features/palavra_dia/recife_time.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _igrejaEmTesteProvider = StateProvider<IgrejaId?>((ref) => null);

class _BibleRepositoryFake implements BibleRepository {
  @override
  String get traducao => 'Almeida (domínio público)';

  @override
  bool get suportaBuscaTextual => false;

  @override
  Future<BibleVerse> carregarVersiculo(BibleVerseRef ref) async {
    return BibleVerse(numero: ref.versiculo, texto: 'Texto bíblico local');
  }

  @override
  Future<BibleChapter> carregarCapitulo(
    String livroApiName,
    int capitulo, {
    String? livroNome,
  }) => throw UnimplementedError();

  @override
  Future<List<BibleVerseRef>> buscarTexto(String termo) =>
      throw UnsupportedError('Busca não usada neste teste.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer criarContainer({
    required CarregarPalavraEspecial carregarPalavra,
    required CarregarEscolaLouvor carregarEscola,
  }) {
    final container = ProviderContainer(
      overrides: [
        igrejaScopeProvider.overrideWith((ref) {
          final id = ref.watch(_igrejaEmTesteProvider);
          return id == null ? null : IgrejaScope(igrejaId: id);
        }),
        carregarPalavraEspecialProvider.overrideWithValue(carregarPalavra),
        carregarEscolaLouvorProvider.overrideWithValue(carregarEscola),
        bibleRepositoryProvider.overrideWithValue(_BibleRepositoryFake()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Map<String, dynamic> palavraEspecial(String igrejaId) {
    final agora = RecifeTime.agora();
    return {
      'ativo': true,
      'texto': 'Palavra de $igrejaId',
      'referencia': 'Salmos 133:1',
      'inicio': Timestamp.fromDate(agora.subtract(const Duration(minutes: 1))),
      'fim': Timestamp.fromDate(agora.add(const Duration(minutes: 10))),
    };
  }

  test('Palavra do Dia acompanha o IgrejaId visualizado', () async {
    final idsLidos = <String>[];
    final container = criarContainer(
      carregarPalavra: (scope) async {
        idsLidos.add(scope.igrejaId.valor);
        return palavraEspecial(scope.igrejaId.valor);
      },
      carregarEscola: (_) async => null,
    );

    container.read(_igrejaEmTesteProvider.notifier).state = IgrejaId('olinda');
    final olinda = await container.read(palavraDoDiaProvider.future);

    container.read(_igrejaEmTesteProvider.notifier).state = IgrejaId(
      'petrolina',
    );
    final petrolina = await container.read(palavraDoDiaProvider.future);

    expect(olinda.texto, 'Palavra de olinda');
    expect(petrolina.texto, 'Palavra de petrolina');
    expect(idsLidos, ['olinda', 'petrolina']);
  });

  test('Escola de Louvor acompanha o IgrejaId visualizado', () async {
    final idsLidos = <String>[];
    final container = criarContainer(
      carregarPalavra: (_) async => null,
      carregarEscola: (scope) async {
        idsLidos.add(scope.igrejaId.valor);
        return {'descricao': 'Escola de ${scope.igrejaId.valor}'};
      },
    );

    container.read(_igrejaEmTesteProvider.notifier).state = IgrejaId('olinda');
    final olinda = await container.read(escolaLouvorProvider.future);

    container.read(_igrejaEmTesteProvider.notifier).state = IgrejaId(
      'petrolina',
    );
    final petrolina = await container.read(escolaLouvorProvider.future);

    expect(olinda?['descricao'], 'Escola de olinda');
    expect(petrolina?['descricao'], 'Escola de petrolina');
    expect(idsLidos, ['olinda', 'petrolina']);
  });

  test('sem igreja, não consulta configuração de nenhuma unidade', () async {
    var leiturasPalavra = 0;
    var leiturasEscola = 0;
    final container = criarContainer(
      carregarPalavra: (_) async {
        leiturasPalavra++;
        return palavraEspecial('indevida');
      },
      carregarEscola: (_) async {
        leiturasEscola++;
        return {'descricao': 'Conteúdo indevido'};
      },
    );

    final palavra = await container.read(palavraDoDiaProvider.future);
    final escola = await container.read(escolaLouvorProvider.future);

    expect(palavra.especial, isFalse);
    expect(escola, isNull);
    expect(leiturasEscola, 0);
    expect(leiturasPalavra, 0);
  });
}
