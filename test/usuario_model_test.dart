import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/features/auth/data/usuario_model.dart';

void main() {
  group('UsuarioModel', () {
    final base = UsuarioModel(
      uid: 'u1',
      nome: 'Ana Maria',
      email: 'ana@cna.app',
      telefone: '81999998888',
      dataCadastro: DateTime(2026, 1, 10),
      perfil: PerfilUsuario.membro,
      status: StatusUsuario.pendente,
      ministerioId: 'louvor',
    );

    test('toMap/fromMap faz round-trip dos campos principais', () {
      final map = base.toMap();
      // Simula leitura do Firestore (Timestamps já presentes no map).
      final restaurado = UsuarioModel.fromMap('u1', map);

      expect(restaurado.uid, 'u1');
      expect(restaurado.nome, 'Ana Maria');
      expect(restaurado.email, 'ana@cna.app');
      expect(restaurado.perfil, PerfilUsuario.membro);
      expect(restaurado.status, StatusUsuario.pendente);
      expect(restaurado.ministerioId, 'louvor');
      expect(restaurado.dataCadastro, DateTime(2026, 1, 10));
    });

    test('toMap NÃO contém referências a célula', () {
      final map = base.toMap();
      expect(map.containsKey('celula_id'), isFalse);
    });

    test('primeiroNome retorna o primeiro token', () {
      expect(base.primeiroNome, 'Ana');
    });

    group('flags de perfil', () {
      test('membro não é líder', () {
        expect(base.isLider, isFalse);
      });
      test('lider é líder', () {
        expect(base.copyWith(perfil: PerfilUsuario.lider).isLider, isTrue);
      });
      test('pastor é diácono e líder', () {
        final pastor = base.copyWith(perfil: PerfilUsuario.pastor);
        expect(pastor.isDiacono, isTrue);
        expect(pastor.isLider, isTrue);
      });
    });

    test('status aprovado', () {
      final aprovado = base.copyWith(status: StatusUsuario.aprovado);
      expect(aprovado.isAprovado, isTrue);
      expect(aprovado.isPendente, isFalse);
    });

    test('fromMap tolera valores ausentes com defaults seguros', () {
      final restaurado = UsuarioModel.fromMap('u2', <String, dynamic>{
        'nome': 'Fulano',
        'data_cadastro': Timestamp.fromDate(DateTime(2026, 2, 1)),
      });
      expect(restaurado.perfil, PerfilUsuario.membro);
      expect(restaurado.status, StatusUsuario.pendente);
      expect(restaurado.email, '');
    });

    test('perfil tolera acento e maiúsculas ("líder"/"Líder" => lider)', () {
      expect(PerfilUsuarioExt.fromString('líder'), PerfilUsuario.lider);
      expect(PerfilUsuarioExt.fromString('Líder'), PerfilUsuario.lider);
      expect(PerfilUsuarioExt.fromString('lider'), PerfilUsuario.lider);
      expect(PerfilUsuarioExt.fromString('diácono'), PerfilUsuario.diacono);
      expect(StatusUsuarioExt.fromString('Aprovado'), StatusUsuario.aprovado);
    });
  });
}
