import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/features/biblia/data/bible_models.dart';
import 'package:nova_alianca_app/features/biblia/data/bible_repository.dart';
import 'package:nova_alianca_app/features/biblia/providers/bible_providers.dart';
import 'package:nova_alianca_app/features/palavra_dia/palavra_dia_calendario.dart';
import 'package:nova_alianca_app/features/palavra_dia/palavra_do_dia.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provedor bíblico falso: conta as buscas e devolve um texto determinístico,
/// sem rede. Permite testar cache/seleção diária sem Firebase nem internet.
class _FakeBibleRepo implements BibleRepository {
  _FakeBibleRepo({this.falhar = false});

  /// Simula ausência de internet (a busca do versículo lança exceção).
  final bool falhar;
  int chamadas = 0;

  @override
  String get traducao => 'Almeida (domínio público)';

  @override
  bool get suportaBuscaTextual => false;

  @override
  Future<BibleVerse> carregarVersiculo(BibleVerseRef ref) async {
    chamadas++;
    if (falhar) {
      throw const BibleException('Sem conexão.', semConexao: true);
    }
    return BibleVerse(
      numero: ref.versiculo,
      texto: 'Texto de ${ref.livroNome} ${ref.capitulo}:${ref.versiculo}',
    );
  }

  @override
  Future<BibleChapter> carregarCapitulo(String livroApiName, int capitulo,
          {String? livroNome}) =>
      throw UnimplementedError();

  @override
  Future<List<BibleVerseRef>> buscarTexto(String termo) =>
      throw UnsupportedError('n/a');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer criarContainer(_FakeBibleRepo fake) {
    final c = ProviderContainer(
      overrides: [bibleRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('busca o texto uma vez e grava cache com chave da data', () async {
    final fake = _FakeBibleRepo();
    final c = criarContainer(fake);
    c.read(dataHojeProvider.notifier).state = DateTime(2026, 5, 10);

    final p = await c.read(palavraDoDiaProvider.future);

    expect(p.temTexto, isTrue);
    expect(fake.chamadas, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('palavra_do_dia_2026-05-10'), isNotNull);
  });

  test('segunda leitura no mesmo dia usa o cache (sem nova busca)', () async {
    final fake = _FakeBibleRepo();
    final c = criarContainer(fake);
    c.read(dataHojeProvider.notifier).state = DateTime(2026, 5, 10);

    final p1 = await c.read(palavraDoDiaProvider.future);
    c.invalidate(palavraDoDiaProvider);
    final p2 = await c.read(palavraDoDiaProvider.future);

    expect(p2.referencia, p1.referencia);
    expect(fake.chamadas, 1); // cache hit
  });

  test('mudar o dia troca o conteúdo e limpa o cache anterior', () async {
    final fake = _FakeBibleRepo();
    final c = criarContainer(fake);

    c.read(dataHojeProvider.notifier).state = DateTime(2026, 5, 10);
    final p1 = await c.read(palavraDoDiaProvider.future);

    c.read(dataHojeProvider.notifier).state = DateTime(2026, 5, 11);
    final p2 = await c.read(palavraDoDiaProvider.future);

    expect(p2.referencia, isNot(p1.referencia)); // troca diária
    expect(fake.chamadas, 2);

    final prefs = await SharedPreferences.getInstance();
    // O cache de ontem é removido — não pode reaparecer como o de hoje.
    expect(prefs.getString('palavra_do_dia_2026-05-10'), isNull);
    expect(prefs.getString('palavra_do_dia_2026-05-11'), isNotNull);
  });

  test('offline sem cache → referência correta do dia (nunca de outro dia)',
      () async {
    final fake = _FakeBibleRepo(falhar: true);
    final c = criarContainer(fake);
    final dia = DateTime(2026, 7, 4);
    c.read(dataHojeProvider.notifier).state = dia;

    final p = await c.read(palavraDoDiaProvider.future);
    final esperado = PalavraDiaCalendario.paraData(dia);

    expect(p.temTexto, isFalse); // sem inventar texto
    expect(p.referencia, esperado.referencia); // a referência é a do dia
  });
}
