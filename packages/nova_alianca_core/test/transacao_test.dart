import 'package:nova_alianca_core/nova_alianca_core.dart';
import 'package:test/test.dart';

Transacao tx({
  int centavos = 1000,
  StatusTransacao status = StatusTransacao.aprovado,
  IgrejaId? igreja,
}) {
  return Transacao(
    id: 't',
    usuarioId: 'u1',
    igrejaId: igreja ?? IgrejaId.olinda,
    valorCentavos: centavos,
    tipo: TipoContribuicao.dizimo,
    metodo: MetodoPagamento.pix,
    status: status,
  );
}

void main() {
  group('contrato canônico', () {
    test('paraMapa usa valor_centavos e nunca campos legados', () {
      final mapa = tx(centavos: 2550).paraMapa();
      expect(mapa['valor_centavos'], 2550);
      expect(mapa['usuario_id'], 'u1');
      expect(mapa['igreja_id'], 'olinda');
      expect(mapa['metodo'], 'pix');
      expect(mapa.containsKey('valor'), isFalse);
      expect(mapa.containsKey('perfil_id'), isFalse);
      expect(mapa.containsKey('meio_pagamento'), isFalse);
    });

    test('checkout_pro serializa em snake_case', () {
      expect(MetodoPagamento.checkoutPro.valor, 'checkout_pro');
      expect(MetodoPagamento.deTexto('checkout_pro'), MetodoPagamento.checkoutPro);
    });

    test('status do contrato canônico são reconhecidos', () {
      expect(StatusTransacao.deTexto('criando'), StatusTransacao.criando);
      expect(StatusTransacao.deTexto('rejeitado'), StatusTransacao.rejeitado);
      expect(StatusTransacao.deTexto('estornado'), StatusTransacao.estornado);
      expect(StatusTransacao.deTexto('cancelado'), StatusTransacao.cancelado);
    });

    test('status desconhecido nunca vira aprovado', () {
      expect(StatusTransacao.deTexto('sei_la'), StatusTransacao.pendente);
      expect(StatusTransacao.deTexto(null), StatusTransacao.pendente);
    });

    test('valor decimal não é inflado silenciosamente', () {
      final t = Transacao.doMapa(
        id: 't',
        dados: const {
          'usuario_id': 'u1',
          'igreja_id': 'olinda',
          'valor_centavos': 25.4,
        },
      );
      expect(t.valorCentavos, 25);
    });

    test('valor ausente vira zero, não nulo', () {
      final t = Transacao.doMapa(id: 't', dados: const {'usuario_id': 'u1'});
      expect(t.valorCentavos, 0);
    });

    test('centavos convertem para reais corretamente', () {
      expect(tx(centavos: 2550).valorReais, 25.5);
      expect(tx(centavos: 1).valorReais, 0.01);
    });
  });

  group('TotaisFinanceiros', () {
    test('só aprovado conta como recebido', () {
      final totais = TotaisFinanceiros.de([
        tx(centavos: 1000, status: StatusTransacao.aprovado),
        tx(centavos: 2000, status: StatusTransacao.aprovado),
        tx(centavos: 500, status: StatusTransacao.pendente),
        tx(centavos: 700, status: StatusTransacao.rejeitado),
        tx(centavos: 300, status: StatusTransacao.estornado),
      ]);
      expect(totais.aprovadoCentavos, 3000);
      expect(totais.pendenteCentavos, 500);
      expect(totais.recusadoCentavos, 1000);
      expect(totais.quantidade, 5);
      expect(totais.aprovadoReais, 30.0);
    });

    test('conjunto vazio produz zeros', () {
      final totais = TotaisFinanceiros.de(const []);
      expect(totais.aprovadoCentavos, 0);
      expect(totais.quantidade, 0);
    });

    test('criando conta como pendente', () {
      final totais = TotaisFinanceiros.de([
        tx(centavos: 900, status: StatusTransacao.criando),
      ]);
      expect(totais.pendenteCentavos, 900);
      expect(totais.aprovadoCentavos, 0);
    });
  });

  group('formatarCentavos', () {
    test('formata moeda brasileira', () {
      expect(formatarCentavos(0), r'R$ 0,00');
      expect(formatarCentavos(5), r'R$ 0,05');
      expect(formatarCentavos(2550), r'R$ 25,50');
      expect(formatarCentavos(100000), r'R$ 1.000,00');
      expect(formatarCentavos(123456789), r'R$ 1.234.567,89');
    });

    test('formata negativo', () {
      expect(formatarCentavos(-2550), r'-R$ 25,50');
    });
  });
}
