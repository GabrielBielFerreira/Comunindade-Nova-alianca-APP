import 'package:admin_web/dados/financas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

Transacao tx({
  int centavos = 1000,
  StatusTransacao status = StatusTransacao.aprovado,
  TipoContribuicao tipo = TipoContribuicao.dizimo,
  DateTime? criadoEm,
}) {
  return Transacao(
    id: 't',
    usuarioId: 'u1',
    igrejaId: IgrejaId.olinda,
    valorCentavos: centavos,
    tipo: tipo,
    metodo: MetodoPagamento.pix,
    status: status,
    criadoEm: criadoEm,
  );
}

void main() {
  group('FiltroFinancas', () {
    test('filtro vazio aceita tudo', () {
      const filtro = FiltroFinancas();
      expect(filtro.vazio, isTrue);
      expect(filtro.aceita(tx()), isTrue);
    });

    test('filtra por status', () {
      const filtro = FiltroFinancas(status: StatusTransacao.aprovado);
      expect(filtro.aceita(tx(status: StatusTransacao.aprovado)), isTrue);
      expect(filtro.aceita(tx(status: StatusTransacao.pendente)), isFalse);
    });

    test('filtra por tipo', () {
      const filtro = FiltroFinancas(tipo: TipoContribuicao.campanha);
      expect(filtro.aceita(tx(tipo: TipoContribuicao.campanha)), isTrue);
      expect(filtro.aceita(tx(tipo: TipoContribuicao.dizimo)), isFalse);
    });

    test('filtra por período', () {
      final filtro = FiltroFinancas(
        inicio: DateTime(2026, 8, 1),
        fim: DateTime(2026, 8, 31, 23, 59, 59),
      );
      expect(filtro.aceita(tx(criadoEm: DateTime(2026, 8, 15))), isTrue);
      expect(filtro.aceita(tx(criadoEm: DateTime(2026, 7, 31))), isFalse);
      expect(filtro.aceita(tx(criadoEm: DateTime(2026, 9, 1))), isFalse);
    });

    test('transação sem data é excluída quando há filtro de período', () {
      final filtro = FiltroFinancas(inicio: DateTime(2026, 1, 1));
      expect(filtro.aceita(tx(criadoEm: null)), isFalse);
    });

    test('copiarCom limpa campos explicitamente', () {
      const filtro = FiltroFinancas(status: StatusTransacao.aprovado);
      expect(filtro.copiarCom(limparStatus: true).status, isNull);
      expect(filtro.copiarCom(limparStatus: true).vazio, isTrue);
    });
  });

  group('exibição de valores em centavos', () {
    test('totais e formatação usam valor_centavos', () {
      final totais = TotaisFinanceiros.de([
        tx(centavos: 2550, status: StatusTransacao.aprovado),
        tx(centavos: 100000, status: StatusTransacao.aprovado),
        tx(centavos: 500, status: StatusTransacao.pendente),
      ]);

      expect(totais.aprovadoCentavos, 102550);
      expect(formatarCentavos(totais.aprovadoCentavos), r'R$ 1.025,50');
      expect(formatarCentavos(totais.pendenteCentavos), r'R$ 5,00');
    });
  });
}
