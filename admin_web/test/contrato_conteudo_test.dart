import 'package:admin_web/dados/conteudo_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapas gravados pelo painel', () {
    test('evento grava Timestamp, horário e cancelamento coerentes', () {
      final mapa = Evento(
        id: '',
        titulo: 'Culto',
        descricao: '',
        data: DateTime(2026, 9, 6, 19, 5),
        cancelado: true,
      ).paraMapa();

      expect(mapa['horario'], '19:05');
      expect(mapa['cancelado'], isTrue);
      expect(mapa['publico'], isTrue);
    });

    test('campanha grava somente meta_centavos', () {
      final mapa = Campanha(
        id: '',
        titulo: 'Reforma',
        descricao: '',
        dataInicio: DateTime(2026, 8, 18),
        metaCentavos: 250000,
      ).paraMapa();

      expect(mapa['meta_centavos'], 250000);
      expect(mapa, isNot(contains('meta_valor')));
    });

    test('ministério e devocional sempre gravam decisão de visibilidade', () {
      final ministerio = Ministerio(
        id: '',
        nome: 'Louvor',
        descricao: '',
        publico: false,
      ).paraMapa();
      final devocional = Devocional(
        id: '',
        titulo: 'Esperança',
        corpo: 'Texto',
        autor: 'Autor',
        data: DateTime(2026, 8, 18),
        publico: false,
      ).paraMapa();

      expect(ministerio['publico'], isFalse);
      expect(devocional['publico'], isFalse);
    });
  });
}
