import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/features/oracao/data/pedido_oracao_model.dart';

void main() {
  PedidoOracaoModel base({bool anonimo = false, List<String> oramPor = const []}) =>
      PedidoOracaoModel(
        id: 'p1',
        autorId: 'u1',
        autorNome: 'Maria Silva',
        texto: 'Peço oração pela família.',
        privado: false,
        anonimo: anonimo,
        status: StatusPedidoOracao.recebido,
        criadoEm: DateTime(2026, 1, 1),
        oramPor: oramPor,
      );

  test('nomeExibicao respeita anonimato', () {
    expect(base().nomeExibicao, 'Maria Silva');
    expect(base(anonimo: true).nomeExibicao, 'Anônimo');
  });

  test('orouUsuario detecta quem já orou', () {
    final p = base(oramPor: ['a', 'b']);
    expect(p.orouUsuario('a'), isTrue);
    expect(p.orouUsuario('z'), isFalse);
  });

  test('toMap usa as chaves alinhadas às regras (oram_count/oram_por)', () {
    final map = base().toMap();
    expect(map.containsKey('oram_count'), isTrue);
    expect(map.containsKey('oram_por'), isTrue);
    expect(map['autor_id'], 'u1');
    expect(map['privado'], isFalse);
  });
}
