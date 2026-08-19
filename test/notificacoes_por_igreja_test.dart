import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/core/services/notification_preferences.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notificações por igreja.
///
/// Antes as inscrições eram globais (`transmissoes`, `eventos`,
/// `comunicacoes`): um aviso de Olinda chegava no aparelho de quem é membro de
/// Petrolina. Estes testes fixam o formato do tópico e o comportamento na
/// troca de unidade.
class _TopicosEspiao implements TopicosFcm {
  final inscritos = <String>[];
  final cancelados = <String>[];

  /// Tópicos que devem falhar, para simular queda de rede.
  final Set<String> falham = {};

  @override
  Future<void> inscrever(String topico) async {
    if (falham.contains(topico)) throw Exception('sem rede');
    inscritos.add(topico);
  }

  @override
  Future<void> cancelar(String topico) async {
    if (falham.contains(topico)) throw Exception('sem rede');
    cancelados.add(topico);
  }

  void limpar() {
    inscritos.clear();
    cancelados.clear();
  }
}

void main() {
  final olinda = IgrejaId('olinda');
  final petrolina = IgrejaId('petrolina');

  late _TopicosEspiao espiao;

  setUp(() {
    espiao = _TopicosEspiao();
    NotificationPreferences.topicos = espiao;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    NotificationPreferences.topicos = const TopicosFcmFirebase();
  });

  group('Formato do tópico', () {
    test('carrega o IgrejaId, nunca o nome da igreja', () {
      expect(
        NotificationPreferences.topicoDe(
          olinda,
          NotificationPreferences.chaveEventos,
        ),
        'igreja_olinda_eventos',
      );
      expect(
        NotificationPreferences.topicoDe(
          petrolina,
          NotificationPreferences.chaveComunicacoes,
        ),
        'igreja_petrolina_comunicacoes',
      );
      expect(
        NotificationPreferences.topicoDe(
          olinda,
          NotificationPreferences.chaveTransmissoes,
        ),
        'igreja_olinda_transmissoes',
      );
    });

    test('preferência desconhecida não vira tópico silenciosamente', () {
      expect(
        () => NotificationPreferences.topicoDe(olinda, 'notif_inexistente'),
        throwsArgumentError,
      );
    });
  });

  group('Sincronização', () {
    test('assina só os tópicos da própria igreja', () async {
      await NotificationPreferences.sincronizar(olinda);

      expect(espiao.inscritos, [
        'igreja_olinda_transmissoes',
        'igreja_olinda_eventos',
        'igreja_olinda_comunicacoes',
      ]);
      // Nada de Petrolina.
      expect(espiao.inscritos.where((t) => t.contains('petrolina')), isEmpty);
    });

    test('sai dos tópicos globais antigos na primeira sincronização', () async {
      await NotificationPreferences.sincronizar(olinda);

      for (final antigo in NotificationPreferences.topicosGlobaisAntigos) {
        expect(
          espiao.cancelados,
          contains(antigo),
          reason: 'sem sair de "$antigo" o aparelho recebe de todas as igrejas',
        );
      }
    });

    test('a saída dos tópicos globais acontece uma única vez', () async {
      await NotificationPreferences.sincronizar(olinda);
      espiao.limpar();

      await NotificationPreferences.sincronizar(olinda);

      for (final antigo in NotificationPreferences.topicosGlobaisAntigos) {
        expect(espiao.cancelados, isNot(contains(antigo)));
      }
    });

    test('falha de rede não marca a migração como concluída', () async {
      espiao.falham.add('eventos');
      await NotificationPreferences.sincronizar(olinda);
      espiao.falham.clear();
      espiao.limpar();

      // Segunda tentativa: precisa tentar de novo, senão o aparelho fica
      // preso no tópico global para sempre.
      await NotificationPreferences.sincronizar(olinda);
      expect(espiao.cancelados, contains('eventos'));
    });

    test('respeita uma preferência desligada', () async {
      SharedPreferences.setMockInitialValues({
        NotificationPreferences.chaveEventos: false,
      });

      await NotificationPreferences.sincronizar(olinda);

      expect(espiao.inscritos, isNot(contains('igreja_olinda_eventos')));
      expect(espiao.cancelados, contains('igreja_olinda_eventos'));
      expect(espiao.inscritos, contains('igreja_olinda_transmissoes'));
    });

    test('visitante sem vínculo não assina nada', () async {
      await NotificationPreferences.sincronizar(null);
      expect(espiao.inscritos, isEmpty);
    });
  });

  group('Troca de igreja principal', () {
    test('cancela a unidade anterior antes de assinar a nova', () async {
      await NotificationPreferences.sincronizar(olinda);
      espiao.limpar();

      // É o estado que uma transferência oficial deixa.
      await NotificationPreferences.sincronizar(petrolina);

      expect(espiao.cancelados, [
        'igreja_olinda_transmissoes',
        'igreja_olinda_eventos',
        'igreja_olinda_comunicacoes',
      ]);
      expect(espiao.inscritos, [
        'igreja_petrolina_transmissoes',
        'igreja_petrolina_eventos',
        'igreja_petrolina_comunicacoes',
      ]);
    });

    test('sincronizar duas vezes na mesma igreja não cancela nada', () async {
      await NotificationPreferences.sincronizar(olinda);
      espiao.limpar();

      await NotificationPreferences.sincronizar(olinda);

      expect(espiao.cancelados, isEmpty);
      expect(espiao.inscritos, [
        'igreja_olinda_transmissoes',
        'igreja_olinda_eventos',
        'igreja_olinda_comunicacoes',
      ]);
    });
  });

  group('Preferência individual', () {
    test('desligar cancela só aquele tópico da própria igreja', () async {
      await NotificationPreferences.sincronizar(olinda);
      espiao.limpar();

      await NotificationPreferences.definir(
        NotificationPreferences.chaveEventos,
        false,
        igrejaId: olinda,
      );

      expect(espiao.cancelados, ['igreja_olinda_eventos']);
      expect(espiao.inscritos, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(NotificationPreferences.chaveEventos), isFalse);
    });

    test('sem igreja principal, guarda a escolha e não assina', () async {
      await NotificationPreferences.definir(
        NotificationPreferences.chaveEventos,
        false,
        igrejaId: null,
      );

      expect(espiao.cancelados, isEmpty);
      expect(espiao.inscritos, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(NotificationPreferences.chaveEventos), isFalse);
    });
  });

  group('Logout', () {
    test('cancela os tópicos da unidade da sessão', () async {
      await NotificationPreferences.sincronizar(olinda);
      espiao.limpar();

      await NotificationPreferences.cancelarTudo();

      expect(espiao.cancelados, [
        'igreja_olinda_transmissoes',
        'igreja_olinda_eventos',
        'igreja_olinda_comunicacoes',
      ]);
    });

    test(
      'depois do logout, sincronizar de novo não tenta cancelar duas vezes',
      () async {
        await NotificationPreferences.sincronizar(olinda);
        await NotificationPreferences.cancelarTudo();
        espiao.limpar();

        await NotificationPreferences.sincronizar(petrolina);

        expect(espiao.cancelados.where((t) => t.contains('olinda')), isEmpty);
        expect(espiao.inscritos, [
          'igreja_petrolina_transmissoes',
          'igreja_petrolina_eventos',
          'igreja_petrolina_comunicacoes',
        ]);
      },
    );
  });
}
