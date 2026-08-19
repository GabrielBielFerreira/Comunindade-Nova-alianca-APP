import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/features/avisos/data/ministerio_model.dart';
import 'package:nova_alianca_app/features/campanhas/data/campanha_model.dart';
import 'package:nova_alianca_app/features/devocionais/data/devocional_model.dart';
import 'package:nova_alianca_app/features/eventos/data/evento_model.dart';
import 'package:nova_alianca_app/features/eventos/data/eventos_repository.dart';

void main() {
  group('contrato painel -> aplicativo', () {
    test('campanha lê meta_centavos e preserva fallback meta_valor', () {
      final canonica = CampanhaModel.fromMap('nova', {
        'titulo': 'Reforma',
        'meta_centavos': 125050,
        'meta_valor': 1,
        'valor_arrecadado': 5000,
        'status': 'ativa',
        'data_inicio': Timestamp.fromDate(DateTime(2026, 8, 18)),
        'publico': true,
      });
      final legada = CampanhaModel.fromMap('legada', {
        'meta_valor': 9900,
        'data_inicio': Timestamp.fromDate(DateTime(2026, 8, 18)),
      });

      expect(canonica.metaValor, 125050);
      expect(canonica.valorArrecadado, 5000);
      expect(canonica.publico, isTrue);
      expect(canonica.toMap()['meta_centavos'], 125050);
      expect(canonica.toMap(), isNot(contains('meta_valor')));
      expect(legada.metaValor, 9900);
    });

    test('evento deriva horário, lê cancelamento e grava ambos', () {
      final evento = EventoModel.fromMap('culto', {
        'titulo': 'Culto da família',
        'data': Timestamp.fromDate(DateTime(2026, 9, 6, 19, 30)),
        'cancelado': true,
        'publico': true,
      });

      expect(evento.horario, '19:30');
      expect(evento.cancelado, isTrue);
      expect(evento.toMap()['horario'], '19:30');
      expect(evento.toMap()['cancelado'], isTrue);
    });

    test('programação próxima remove cancelados e mantém ordem', () {
      EventoModel evento(String id, DateTime data, {bool cancelado = false}) =>
          EventoModel(
            id: id,
            titulo: id,
            descricao: '',
            data: data,
            horario: '19:00',
            local: '',
            tipo: TipoEvento.culto,
            publico: true,
            cancelado: cancelado,
            criadoPor: 'painel',
            confirmadosCount: 0,
          );

      final lista = filtrarEventosProximos([
        evento('depois', DateTime(2026, 8, 21)),
        evento('cancelado', DateTime(2026, 8, 20), cancelado: true),
        evento('antes', DateTime(2026, 8, 19)),
      ], agora: DateTime(2026, 8, 18));

      expect(lista.map((e) => e.id), ['antes', 'depois']);
    });

    test('ministério e devocional carregam e preservam publico', () {
      final ministerio = MinisterioModel.fromMap('louvor', {
        'nome': 'Louvor',
        'publico': false,
        'criado_em': Timestamp.fromDate(DateTime(2026, 8, 18)),
      });
      final devocional = DevocionalModel.fromMap('d1', {
        'titulo': 'Esperança',
        'data': Timestamp.fromDate(DateTime(2026, 8, 18)),
        'publico': false,
      });

      expect(ministerio.publico, isFalse);
      expect(ministerio.toMap()['publico'], isFalse);
      expect(devocional.publico, isFalse);
      expect(devocional.toMap()['publico'], isFalse);
    });
  });
}
