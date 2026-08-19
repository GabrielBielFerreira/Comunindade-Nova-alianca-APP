import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nova_alianca_app/features/auth/data/usuario_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';
import 'package:nova_alianca_app/features/auth/providers/auth_provider.dart';
import 'package:nova_alianca_app/features/igrejas/data/igrejas_repository.dart';
import 'package:nova_alianca_app/features/igrejas/providers/igreja_providers.dart';

/// Testes do contrato multi-igreja que travava a publicação.
void main() {
  // Necessario para o SharedPreferences mockado fora de `testWidgets`.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cadastro compatível com as Rules', () {
    test('o mapa de criação só usa chaves que as Rules aceitam', () {
      final mapa = mapaDeCriacaoUsuario(
        nome: 'Maria',
        email: 'maria@exemplo.com',
        telefone: '(81) 99999-0000',
        igrejaPrincipalId: 'olinda',
        fotoUrl: 'https://exemplo.com/foto.jpg',
      );

      // Era exatamente isto que quebrava: UsuarioModel.toMap() escreve
      // 'perfil', 'status' e 'uid', que o hasOnly das Rules recusa.
      expect(
        mapa.keys.toSet().difference(chavesPermitidasCriacaoUsuario),
        isEmpty,
        reason: 'Chave fora do hasOnly faz o Firestore recusar o cadastro.',
      );
    });

    test('autorização não vai para o documento global do usuário', () {
      final mapa = mapaDeCriacaoUsuario(
        nome: 'Maria',
        email: 'maria@exemplo.com',
        telefone: '',
        igrejaPrincipalId: 'petrolina',
      );

      expect(mapa.containsKey('perfil'), isFalse);
      expect(mapa.containsKey('status'), isFalse);
      expect(mapa.containsKey('funcoes_admin'), isFalse);
    });

    test('a igreja escolhida vira a igreja principal', () {
      final mapa = mapaDeCriacaoUsuario(
        nome: 'João',
        email: 'joao@exemplo.com',
        telefone: '',
        igrejaPrincipalId: 'petrolina',
      );

      expect(mapa['igreja_principal_id'], 'petrolina');
    });

    test('campos opcionais ausentes não viram null gravado', () {
      final mapa = mapaDeCriacaoUsuario(
        nome: 'João',
        email: 'joao@exemplo.com',
        telefone: '',
        igrejaPrincipalId: 'olinda',
      );

      expect(mapa.containsKey('foto_url'), isFalse);
      expect(mapa.containsKey('dados_pessoais'), isFalse);
    });
  });

  group('Visualizar outra igreja não transfere permissão', () {
    final olinda = IgrejaId('olinda');
    final petrolina = IgrejaId('petrolina');

    final pastorDeOlinda = VinculoIgreja(
      uid: 'uid-pastor',
      igrejaId: olinda,
      status: StatusVinculo.aprovado,
      perfil: PerfilComunitario.pastor,
    );

    test('pastor de Olinda administra Olinda', () {
      final a = Autorizacao(
        uid: 'uid-pastor',
        igrejaId: olinda,
        vinculo: pastorDeOlinda,
      );
      expect(a.podeAcessarPainel, isTrue);
      expect(a.temVinculoAtivo, isTrue);
    });

    test('o mesmo vínculo NÃO vale em Petrolina', () {
      // É o caso perigoso: levar o vínculo de uma unidade para outra.
      final a = Autorizacao(
        uid: 'uid-pastor',
        igrejaId: petrolina,
        vinculo: pastorDeOlinda,
      );
      expect(a.temVinculoAtivo, isFalse);
      expect(a.podeAcessarPainel, isFalse);
      expect(a.perfilEfetivo, PerfilComunitario.membro);
    });

    test('visitante sem vínculo não acessa o painel', () {
      final a = Autorizacao.semVinculo(
        uid: 'uid-visitante',
        igrejaId: petrolina,
      );
      expect(a.podeAcessarPainel, isFalse);
      expect(a.podeLerFinancas, isFalse);
    });

    test('membro comum não vê o botão do painel', () {
      final a = Autorizacao(
        uid: 'uid-membro',
        igrejaId: olinda,
        vinculo: VinculoIgreja(
          uid: 'uid-membro',
          igrejaId: olinda,
          status: StatusVinculo.aprovado,
          perfil: PerfilComunitario.membro,
        ),
      );
      expect(a.podeAcessarPainel, isFalse);
    });

    test('vínculo pendente não concede acesso', () {
      final a = Autorizacao(
        uid: 'uid-novo',
        igrejaId: olinda,
        vinculo: VinculoIgreja(
          uid: 'uid-novo',
          igrejaId: olinda,
          status: StatusVinculo.pendente,
          perfil: PerfilComunitario.pastor,
        ),
      );
      expect(a.temVinculoAtivo, isFalse);
      expect(a.podeAcessarPainel, isFalse);
    });

    test(
      'tesoureiro e editor acessam o painel; só o tesoureiro vê finanças',
      () {
        Autorizacao com(FuncaoAdmin f) => Autorizacao(
          uid: 'uid',
          igrejaId: olinda,
          vinculo: VinculoIgreja(
            uid: 'uid',
            igrejaId: olinda,
            status: StatusVinculo.aprovado,
            perfil: PerfilComunitario.membro,
            funcoesAdmin: {f},
          ),
        );

        expect(com(FuncaoAdmin.tesoureiro).podeAcessarPainel, isTrue);
        expect(com(FuncaoAdmin.tesoureiro).podeLerFinancas, isTrue);
        expect(com(FuncaoAdmin.editor).podeAcessarPainel, isTrue);
        expect(com(FuncaoAdmin.editor).podeLerFinancas, isFalse);
        expect(com(FuncaoAdmin.moderadorOracao).podeLerFinancas, isFalse);
      },
    );
  });

  group('Dados institucionais por unidade', () {
    IgrejaModel igreja({
      String? pix,
      String? endereco,
      String? pastor,
      List<String> pastores = const [],
    }) => IgrejaModel(
      id: IgrejaId('petrolina'),
      nome: 'Comunidade Nova Aliança Petrolina',
      endereco: endereco,
      cidadeEstado: 'Petrolina — PE',
      pixChave: pix,
      pastorResponsavel: pastor,
      pastoresPublicos: pastores,
    );

    test('unidade sem PIX não aceita contribuição', () {
      expect(igreja().aceitaContribuicao, isFalse);
      expect(igreja(pix: '  ').aceitaContribuicao, isFalse);
    });

    test('unidade com PIX aceita contribuição', () {
      expect(igreja(pix: 'chave@exemplo.com').aceitaContribuicao, isTrue);
    });

    test('sem endereço não há link de mapa', () {
      expect(igreja().mapaUrl, isNull);
    });

    test('com endereço, o mapa usa o endereço da própria unidade', () {
      final url = igreja(endereco: 'Rua 47, número 180').mapaUrl;
      expect(url, isNotNull);
      expect(url, contains('Petrolina'));
      // Nunca o endereço de Olinda.
      expect(url, isNot(contains('Leopoldino')));
    });

    test('liderança divergente não elege um pastor', () {
      // Enquanto a divergência de Petrolina não for resolvida, a tela precisa
      // dizer "não informado" em vez de escolher um nome.
      expect(igreja().pastoresExibicao, isEmpty);
    });

    test('vários pastores públicos são preservados', () {
      final lista = igreja(pastores: ['Pr. A', 'Pra. B']).pastoresExibicao;
      expect(lista, ['Pr. A', 'Pra. B']);
    });

    test('um pastor confirmado aparece sozinho', () {
      expect(igreja(pastor: 'Pr. Victor').pastoresExibicao, ['Pr. Victor']);
    });
  });

  group('IgrejaId é o escopo, não o nome', () {
    test('nomes parecidos produzem ids distintos', () {
      expect(IgrejaId('olinda'), isNot(IgrejaId('petrolina')));
    });

    test('texto inválido não vira escopo silenciosamente', () {
      expect(IgrejaId.tentar(null), isNull);
      expect(IgrejaId.tentar(''), isNull);
    });
  });

  group('Igreja vinculada na ficha cadastral', () {
    // A ficha cadastral AFIRMA vinculo. Usar o nome da unidade em foco fazia
    // quem e de Olinda aparecer como membro de Petrolina so por estar
    // visitando.

    final olinda = IgrejaId('olinda');
    final petrolina = IgrejaId('petrolina');

    final unidades = <String, IgrejaModel>{
      'olinda': IgrejaModel(
        id: olinda,
        nome: 'Comunidade Nova Alianca Olinda',
        ativa: true,
      ),
      'petrolina': IgrejaModel(
        id: petrolina,
        nome: 'Comunidade Nova Alianca Petrolina',
        ativa: true,
      ),
    };

    Future<IgrejaModel?> esperarDados(
      ProviderContainer container, {
      required bool principal,
      bool Function(IgrejaModel?) aceitar = _qualquerIgreja,
    }) async {
      final completer = Completer<IgrejaModel?>();
      final provider = principal
          ? igrejaPrincipalDadosProvider
          : igrejaAtualDadosProvider;
      final assinatura = container.listen<AsyncValue<IgrejaModel?>>(provider, (
        _,
        proximo,
      ) {
        proximo.when(
          data: (valor) {
            if (!completer.isCompleted && aceitar(valor)) {
              completer.complete(valor);
            }
          },
          error: (erro, stack) {
            if (!completer.isCompleted) {
              completer.completeError(erro, stack);
            }
          },
          loading: () {},
        );
      }, fireImmediately: true);
      try {
        return await completer.future.timeout(const Duration(seconds: 5));
      } finally {
        assinatura.close();
      }
    }

    /// Container com o catalogo em memoria e a preferencia local ja gravada.
    /// O notifier de unidade visualizada e o REAL: e ele que le o disco.
    Future<ProviderContainer> containerCom({
      required String? principal,
      required IgrejaId? visualizada,
    }) async {
      SharedPreferences.setMockInitialValues({
        if (visualizada != null) 'igreja_visualizada_id': visualizada.valor,
      });

      final c = ProviderContainer(
        overrides: [
          igrejasRepositoryProvider.overrideWithValue(
            _RepositorioIgrejasFalso(unidades, vinculosAprovados: {?principal}),
          ),
          usuarioAtualProvider.overrideWith(
            (ref) => Stream.value(
              principal == null
                  ? null
                  : UsuarioModel(
                      uid: 'uid-ana',
                      nome: 'Ana',
                      email: 'ana@exemplo.test',
                      telefone: '',
                      dataCadastro: DateTime(2026, 8, 1),
                      perfil: PerfilUsuario.membro,
                      status: StatusUsuario.aprovado,
                      igrejaPrincipalId: principal,
                    ),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);

      // Espera a leitura do disco terminar, senao o escopo ainda e nulo.
      while (!c.read(igrejaVisualizadaProvider).carregado) {
        await Future<void>.delayed(Duration.zero);
      }
      await c.read(usuarioAtualProvider.future);
      return c;
    }

    test('visitando Petrolina, o vinculo continua sendo Olinda', () async {
      final c = await containerCom(principal: 'olinda', visualizada: petrolina);

      expect(c.read(igrejaPrincipalProvider), olinda);
      expect(c.read(igrejaAtualProvider), petrolina);

      await esperarDados(c, principal: true);
      await esperarDados(c, principal: false);

      // O campo da ficha cadastral segue o VINCULO.
      expect(
        c.read(nomeIgrejaPrincipalProvider),
        'Comunidade Nova Alianca Olinda',
      );
      // O cabecalho de conteudo segue a unidade VISITADA.
      expect(
        c.read(nomeIgrejaEmFocoProvider),
        'Comunidade Nova Alianca Petrolina',
      );
      // A própria igreja usa o documento operacional autorizado; a unidade
      // apenas visitada permanece no catálogo público mínimo.
      expect(
        c.read(igrejaPrincipalDadosProvider).valueOrNull?.pixChave,
        'pix-operacional-olinda',
      );
      expect(c.read(igrejaAtualDadosProvider).valueOrNull?.pixChave, isNull);
    });

    test('sem visitar ninguem, os dois coincidem', () async {
      final c = await containerCom(principal: 'olinda', visualizada: null);

      await esperarDados(c, principal: true);
      await esperarDados(c, principal: false);

      expect(
        c.read(nomeIgrejaPrincipalProvider),
        c.read(nomeIgrejaEmFocoProvider),
      );
    });

    test('sem vinculo, o campo fica nulo em vez de inventar unidade', () async {
      final c = await containerCom(principal: null, visualizada: petrolina);

      await esperarDados(c, principal: true);

      expect(c.read(igrejaPrincipalProvider), isNull);
      expect(c.read(nomeIgrejaPrincipalProvider), isNull);
    });

    for (final principal in [false, true]) {
      test(
        'vínculo não fechado troca fontes em '
        '${principal ? 'igrejaPrincipalDadosProvider' : 'igrejaAtualDadosProvider'}',
        () async {
          SharedPreferences.setMockInitialValues(const {});
          final repositorio = _RepositorioIgrejasDinamico(olinda);
          addTearDown(repositorio.dispose);

          final c = ProviderContainer(
            overrides: [
              igrejasRepositoryProvider.overrideWithValue(repositorio),
              usuarioAtualProvider.overrideWith(
                (ref) => Stream.value(
                  UsuarioModel(
                    uid: 'uid-ana',
                    nome: 'Ana',
                    email: 'ana@exemplo.test',
                    telefone: '',
                    dataCadastro: DateTime(2026, 8, 1),
                    perfil: PerfilUsuario.membro,
                    status: StatusUsuario.aprovado,
                    igrejaPrincipalId: olinda.valor,
                  ),
                ),
              ),
            ],
          );
          addTearDown(c.dispose);

          while (!c.read(igrejaVisualizadaProvider).carregado) {
            await Future<void>.delayed(Duration.zero);
          }
          await c.read(usuarioAtualProvider.future);

          final publicoInicial = esperarDados(
            c,
            principal: principal,
            aceitar: (igreja) => igreja?.nome == 'Catálogo inicial',
          );
          await repositorio.esperarVinculo();
          repositorio.vinculos.add(
            VinculoIgreja(
              uid: 'uid-ana',
              igrejaId: olinda,
              status: StatusVinculo.pendente,
              perfil: PerfilComunitario.membro,
            ),
          );
          await repositorio.esperarCatalogo();
          repositorio.catalogo.add(
            IgrejaModel(id: olinda, nome: 'Catálogo inicial', ativa: true),
          );
          expect((await publicoInicial)?.pixChave, isNull);

          final privado = esperarDados(
            c,
            principal: principal,
            aceitar: (igreja) => igreja?.pixChave == 'pix-privado',
          );
          repositorio.vinculos.add(
            VinculoIgreja(
              uid: 'uid-ana',
              igrejaId: olinda,
              status: StatusVinculo.aprovado,
              perfil: PerfilComunitario.membro,
            ),
          );
          await repositorio.esperarPrivada();
          repositorio.privada.add(
            IgrejaModel(
              id: olinda,
              nome: 'Documento privado',
              ativa: true,
              pixChave: 'pix-privado',
            ),
          );
          expect((await privado)?.pixChave, 'pix-privado');
          expect(repositorio.cancelamentosCatalogo, greaterThanOrEqualTo(1));

          final publicoFinal = esperarDados(
            c,
            principal: principal,
            aceitar: (igreja) => igreja?.nome == 'Catálogo final',
          );
          repositorio.vinculos.add(
            VinculoIgreja(
              uid: 'uid-ana',
              igrejaId: olinda,
              status: StatusVinculo.inativo,
              perfil: PerfilComunitario.membro,
            ),
          );
          await repositorio.esperarCatalogo();
          repositorio.catalogo.add(
            IgrejaModel(id: olinda, nome: 'Catálogo final', ativa: true),
          );
          expect((await publicoFinal)?.pixChave, isNull);
          expect(repositorio.cancelamentosPrivada, greaterThanOrEqualTo(1));
        },
      );
    }

    test(
      'vínculo aprovado de outra unidade nunca abre a fonte privada',
      () async {
        SharedPreferences.setMockInitialValues({
          'igreja_visualizada_id': petrolina.valor,
        });
        final repositorio = _RepositorioIgrejasDinamico(petrolina);
        addTearDown(repositorio.dispose);

        final c = ProviderContainer(
          overrides: [
            igrejasRepositoryProvider.overrideWithValue(repositorio),
            usuarioAtualProvider.overrideWith(
              (ref) => Stream.value(
                UsuarioModel(
                  uid: 'uid-ana',
                  nome: 'Ana',
                  email: 'ana@exemplo.test',
                  telefone: '',
                  dataCadastro: DateTime(2026, 8, 1),
                  perfil: PerfilUsuario.membro,
                  status: StatusUsuario.aprovado,
                  igrejaPrincipalId: olinda.valor,
                ),
              ),
            ),
          ],
        );
        addTearDown(c.dispose);

        while (!c.read(igrejaVisualizadaProvider).carregado) {
          await Future<void>.delayed(Duration.zero);
        }
        await c.read(usuarioAtualProvider.future);
        expect(c.read(igrejaAtualProvider), petrolina);

        final dadosPublicos = esperarDados(
          c,
          principal: false,
          aceitar: (igreja) => igreja?.nome == 'Catálogo Petrolina',
        );
        await repositorio.esperarVinculo();
        repositorio.vinculos.add(
          VinculoIgreja(
            uid: 'uid-ana',
            igrejaId: olinda,
            status: StatusVinculo.aprovado,
            perfil: PerfilComunitario.membro,
            ministerioIds: const ['louvor-olinda'],
          ),
        );
        await repositorio.esperarCatalogo();
        repositorio.catalogo.add(
          IgrejaModel(id: petrolina, nome: 'Catálogo Petrolina', ativa: true),
        );

        expect((await dadosPublicos)?.nome, 'Catálogo Petrolina');
        expect(c.read(isMembroAprovadoAtualProvider), isFalse);
        expect(repositorio.privadaTemAssinatura, isFalse);
      },
    );
  });
}

bool _qualquerIgreja(IgrejaModel? _) => true;

/// Catalogo de unidades em memoria.
class _RepositorioIgrejasFalso implements IgrejasRepository {
  _RepositorioIgrejasFalso(
    this.unidades, {
    this.vinculosAprovados = const <String>{},
  });

  final Map<String, IgrejaModel> unidades;
  final Set<String> vinculosAprovados;

  @override
  Stream<IgrejaModel?> streamIgreja(IgrejaId id) =>
      Stream.value(unidades[id.valor]);

  @override
  Stream<IgrejaModel?> streamIgrejaPrivada(IgrejaId id) {
    final publica = unidades[id.valor];
    if (publica == null) return Stream.value(null);
    return Stream.value(
      IgrejaModel(
        id: publica.id,
        nome: publica.nome,
        ativa: publica.ativa,
        pixChave: 'pix-operacional-${id.valor}',
      ),
    );
  }

  @override
  Stream<VinculoIgreja?> streamVinculo(IgrejaId igrejaId, String uid) {
    if (!vinculosAprovados.contains(igrejaId.valor)) {
      return Stream.value(null);
    }
    return Stream.value(
      VinculoIgreja(
        uid: uid,
        igrejaId: igrejaId,
        status: StatusVinculo.aprovado,
        perfil: PerfilComunitario.membro,
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RepositorioIgrejasDinamico implements IgrejasRepository {
  _RepositorioIgrejasDinamico(this.id) {
    catalogo = StreamController<IgrejaModel?>.broadcast(
      sync: true,
      onCancel: () => cancelamentosCatalogo++,
    );
    privada = StreamController<IgrejaModel?>.broadcast(
      sync: true,
      onCancel: () => cancelamentosPrivada++,
    );
  }

  final IgrejaId id;
  final vinculos = StreamController<VinculoIgreja?>.broadcast(sync: true);
  late final StreamController<IgrejaModel?> catalogo;
  late final StreamController<IgrejaModel?> privada;
  int cancelamentosCatalogo = 0;
  int cancelamentosPrivada = 0;
  bool get privadaTemAssinatura => privada.hasListener;

  Future<void> esperarVinculo() => _esperarAssinatura(vinculos, 'vínculo');

  Future<void> esperarCatalogo() => _esperarAssinatura(catalogo, 'catálogo');

  Future<void> esperarPrivada() => _esperarAssinatura(privada, 'privada');

  Future<void> _esperarAssinatura(
    StreamController<Object?> controller,
    String nome,
  ) async {
    for (var tentativa = 0; tentativa < 100; tentativa++) {
      if (controller.hasListener) return;
      await Future<void>.delayed(Duration.zero);
    }
    throw StateError('O stream de $nome não recebeu assinatura.');
  }

  @override
  Stream<IgrejaModel?> streamIgreja(IgrejaId id) => catalogo.stream;

  @override
  Stream<IgrejaModel?> streamIgrejaPrivada(IgrejaId id) => privada.stream;

  @override
  Stream<VinculoIgreja?> streamVinculo(IgrejaId igrejaId, String uid) =>
      vinculos.stream;

  Future<void> dispose() async {
    await vinculos.close();
    await catalogo.close();
    await privada.close();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
