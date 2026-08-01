import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/features/palavra_dia/palavra_dia_share_service.dart';
import 'package:nova_alianca_app/features/palavra_dia/palavra_do_dia.dart';
import 'package:nova_alianca_app/features/palavra_dia/recife_time.dart';

void main() {
  group('PalavraDoDia (modelo)', () {
    test('toJson/fromJson preserva os campos', () {
      final p = PalavraDoDia(
        id: 'anual-100',
        texto: 'O Senhor é o meu pastor.',
        referencia: 'Salmos 23:1',
        traducao: 'Almeida (domínio público)',
        data: DateTime(2026, 3, 15),
        reflexao: 'Descanse no cuidado d\'Ele.',
      );
      final r = PalavraDoDia.fromJson(p.toJson());
      expect(r.id, p.id);
      expect(r.texto, p.texto);
      expect(r.referencia, p.referencia);
      expect(r.traducao, p.traducao);
      expect(r.reflexao, p.reflexao);
      expect(RecifeTime.chaveData(r.data), RecifeTime.chaveData(p.data));
    });

    test('temTexto reflete conteúdo offline sem texto', () {
      final semTexto = PalavraDoDia(
        id: 'anual-1',
        texto: '',
        referencia: 'João 3:16',
        traducao: 'Almeida (domínio público)',
        data: DateTime(2026, 1, 2),
      );
      expect(semTexto.temTexto, isFalse);
    });
  });

  group('lerPalavraEspecial (validade do conteúdo especial)', () {
    final hoje = RecifeTime.hoje();
    final agora = RecifeTime.agora();

    Map<String, dynamic> base({
      bool ativo = true,
      String texto = 'Texto especial da liderança.',
      DateTime? inicio,
      DateTime? fim,
    }) =>
        {
          'ativo': ativo,
          'texto': texto,
          'referencia': 'Isaías 40:31',
          if (inicio != null) 'inicio': Timestamp.fromDate(inicio),
          if (fim != null) 'fim': Timestamp.fromDate(fim),
          'prioridade': 5,
        };

    test('ativo e dentro da janela → retorna o especial', () {
      final r = lerPalavraEspecial(
        base(
          inicio: agora.subtract(const Duration(hours: 1)),
          fim: agora.add(const Duration(hours: 1)),
        ),
        hoje,
        'Almeida (domínio público)',
      );
      expect(r, isNotNull);
      expect(r!.especial, isTrue);
      expect(r.texto, 'Texto especial da liderança.');
    });

    test('expirado (agora > fim) → null (volta ao calendário)', () {
      final r = lerPalavraEspecial(
        base(
          inicio: agora.subtract(const Duration(days: 2)),
          fim: agora.subtract(const Duration(hours: 1)),
        ),
        hoje,
        'Almeida (domínio público)',
      );
      expect(r, isNull);
    });

    test('ainda não começou (agora < início) → null', () {
      final r = lerPalavraEspecial(
        base(
          inicio: agora.add(const Duration(hours: 1)),
          fim: agora.add(const Duration(hours: 2)),
        ),
        hoje,
        'Almeida (domínio público)',
      );
      expect(r, isNull);
    });

    test('sem fim definido → null (não fica ativo indefinidamente)', () {
      final r = lerPalavraEspecial(
        base(inicio: agora.subtract(const Duration(hours: 1))),
        hoje,
        'Almeida (domínio público)',
      );
      expect(r, isNull);
    });

    test('inativo → null mesmo dentro da janela', () {
      final r = lerPalavraEspecial(
        base(
          ativo: false,
          inicio: agora.subtract(const Duration(hours: 1)),
          fim: agora.add(const Duration(hours: 1)),
        ),
        hoje,
        'Almeida (domínio público)',
      );
      expect(r, isNull);
    });

    test('sem texto → null', () {
      final r = lerPalavraEspecial(
        base(
          texto: '   ',
          inicio: agora.subtract(const Duration(hours: 1)),
          fim: agora.add(const Duration(hours: 1)),
        ),
        hoje,
        'Almeida (domínio público)',
      );
      expect(r, isNull);
    });
  });

  group('PalavraDiaShareService.montarLegenda', () {
    final p = PalavraDoDia(
      id: 'anual-1',
      texto: 'Tudo posso naquele que me fortalece.',
      referencia: 'Filipenses 4:13',
      traducao: 'Almeida (domínio público)',
      data: DateTime(2026, 2, 20),
      reflexao: 'A tua força vem de Cristo.',
    );

    test('inclui referência e o nome do app', () {
      final legenda =
          PalavraDiaShareService.montarLegenda(p, 'https://app.exemplo.com');
      expect(legenda, contains('Palavra do Dia — Filipenses 4:13'));
      expect(legenda, contains('Nova Aliança App'));
      expect(legenda, contains('https://app.exemplo.com'));
    });

    test('sem link não insere linha de link (nunca link falso)', () {
      final legenda = PalavraDiaShareService.montarLegenda(p, '');
      expect(legenda, contains('Filipenses 4:13'));
      expect(legenda, isNot(contains('http')));
    });
  });
}
