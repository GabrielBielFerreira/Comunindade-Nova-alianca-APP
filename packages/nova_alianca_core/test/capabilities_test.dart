import 'package:nova_alianca_core/nova_alianca_core.dart';
import 'package:test/test.dart';

VinculoIgreja vinculo({
  String uid = 'u1',
  IgrejaId? igreja,
  PerfilComunitario perfil = PerfilComunitario.membro,
  StatusVinculo status = StatusVinculo.aprovado,
  Set<FuncaoAdmin> funcoes = const {},
}) {
  return VinculoIgreja(
    uid: uid,
    igrejaId: igreja ?? IgrejaId.olinda,
    status: status,
    perfil: perfil,
    funcoesAdmin: funcoes,
  );
}

Autorizacao auth(
  VinculoIgreja v, {
  IgrejaId? sobre,
  bool superAdmin = false,
}) {
  return Autorizacao(
    uid: v.uid,
    igrejaId: sobre ?? IgrejaId.olinda,
    vinculo: v,
    isSuperAdmin: superAdmin,
  );
}

void main() {
  group('acesso financeiro — liderança ministerial da própria unidade', () {
    for (final perfil in [
      PerfilComunitario.pastor,
      PerfilComunitario.diacono,
      PerfilComunitario.evangelista,
      PerfilComunitario.lider,
    ]) {
      test('${perfil.name} lê finanças da própria igreja', () {
        expect(auth(vinculo(perfil: perfil)).podeLerFinancas, isTrue);
      });

      test('${perfil.name} de Olinda NÃO lê finanças de Petrolina', () {
        final a = auth(vinculo(perfil: perfil), sobre: IgrejaId.petrolina);
        expect(a.podeLerFinancas, isFalse);
        expect(a.temVinculoAtivo, isFalse);
      });
    }

    test('tesoureiro com perfil membro lê finanças', () {
      final a = auth(vinculo(
        perfil: PerfilComunitario.membro,
        funcoes: {FuncaoAdmin.tesoureiro},
      ));
      expect(a.podeLerFinancas, isTrue);
    });

    test('tesoureiro de Olinda NÃO lê finanças de Petrolina', () {
      final a = auth(
        vinculo(perfil: PerfilComunitario.membro, funcoes: {FuncaoAdmin.tesoureiro}),
        sobre: IgrejaId.petrolina,
      );
      expect(a.podeLerFinancas, isFalse);
    });
  });

  group('acesso financeiro — negativas', () {
    test('editor NÃO lê finanças só por ser editor', () {
      final a = auth(vinculo(
        perfil: PerfilComunitario.membro,
        funcoes: {FuncaoAdmin.editor},
      ));
      expect(a.podeLerFinancas, isFalse);
      expect(a.podeGerenciarConteudo, isTrue);
    });

    test('moderador de oração NÃO lê finanças só por ser moderador', () {
      final a = auth(vinculo(
        perfil: PerfilComunitario.membro,
        funcoes: {FuncaoAdmin.moderadorOracao},
      ));
      expect(a.podeLerFinancas, isFalse);
      expect(a.podeModerarOracao, isTrue);
    });

    test('membro comum NÃO lê finanças', () {
      expect(auth(vinculo()).podeLerFinancas, isFalse);
    });

    test('líder com vínculo INATIVO NÃO lê finanças', () {
      final a = auth(vinculo(
        perfil: PerfilComunitario.lider,
        status: StatusVinculo.inativo,
      ));
      expect(a.podeLerFinancas, isFalse);
      expect(a.podeAcessarPainel, isFalse);
    });

    test('pastor com vínculo PENDENTE NÃO lê finanças', () {
      final a = auth(vinculo(
        perfil: PerfilComunitario.pastor,
        status: StatusVinculo.pendente,
      ));
      expect(a.podeLerFinancas, isFalse);
    });

    test('tesoureiro INATIVO NÃO lê finanças', () {
      final a = auth(vinculo(
        status: StatusVinculo.inativo,
        funcoes: {FuncaoAdmin.tesoureiro},
      ));
      expect(a.podeLerFinancas, isFalse);
    });

    test('ninguém escreve finanças pelo cliente — nem super_admin', () {
      expect(auth(vinculo(perfil: PerfilComunitario.pastor)).podeEscreverFinancas, isFalse);
      final sa = Autorizacao.semVinculo(
        uid: 'sa',
        igrejaId: IgrejaId.olinda,
        isSuperAdmin: true,
      );
      expect(sa.podeEscreverFinancas, isFalse);
    });
  });

  group('gestão da liderança', () {
    final alvoLider = vinculo(uid: 'lider2', perfil: PerfilComunitario.lider);
    final alvoPastor = vinculo(uid: 'pastor2', perfil: PerfilComunitario.pastor);

    test('pastor da unidade pode rebaixar um líder', () {
      final a = auth(vinculo(uid: 'p1', perfil: PerfilComunitario.pastor));
      expect(a.podeGerenciarLideranca, isTrue);
      expect(a.podeGerenciarCicloDeVidaDe(alvoLider), isTrue);
      expect(a.motivoNegativaCicloDeVida(alvoLider), isNull);
    });

    test('líder NÃO remove outro líder', () {
      final a = auth(vinculo(uid: 'l1', perfil: PerfilComunitario.lider));
      expect(a.podeGerenciarLideranca, isFalse);
      expect(a.podeGerenciarCicloDeVidaDe(alvoLider), isFalse);
    });

    test('diácono NÃO remove líder', () {
      final a = auth(vinculo(uid: 'd1', perfil: PerfilComunitario.diacono));
      expect(a.podeGerenciarCicloDeVidaDe(alvoLider), isFalse);
    });

    test('evangelista NÃO remove líder', () {
      final a = auth(vinculo(uid: 'e1', perfil: PerfilComunitario.evangelista));
      expect(a.podeGerenciarCicloDeVidaDe(alvoLider), isFalse);
    });

    test('tesoureiro NÃO remove líder', () {
      final a = auth(vinculo(
        uid: 't1',
        perfil: PerfilComunitario.membro,
        funcoes: {FuncaoAdmin.tesoureiro},
      ));
      expect(a.podeGerenciarCicloDeVidaDe(alvoLider), isFalse);
    });

    test('pastor NÃO remove a si mesmo', () {
      final eu = vinculo(uid: 'p1', perfil: PerfilComunitario.pastor);
      final a = auth(eu);
      expect(a.podeGerenciarCicloDeVidaDe(eu), isFalse);
      expect(a.motivoNegativaCicloDeVida(eu), contains('próprio vínculo'));
    });

    test('pastor NÃO remove outro pastor', () {
      final a = auth(vinculo(uid: 'p1', perfil: PerfilComunitario.pastor));
      expect(a.podeGerenciarCicloDeVidaDe(alvoPastor), isFalse);
      expect(a.motivoNegativaCicloDeVida(alvoPastor), contains('superadministrador'));
    });

    test('super_admin gerencia liderança de qualquer unidade, inclusive pastor', () {
      final sa = Autorizacao.semVinculo(
        uid: 'sa',
        igrejaId: IgrejaId.olinda,
        isSuperAdmin: true,
      );
      expect(sa.podeGerenciarLideranca, isTrue);
      expect(sa.podeGerenciarCicloDeVidaDe(alvoPastor), isTrue);
    });

    test('pastor de Olinda NÃO gerencia alguém de Petrolina', () {
      final a = auth(vinculo(uid: 'p1', perfil: PerfilComunitario.pastor));
      final alvoOutraIgreja =
          vinculo(uid: 'x', igreja: IgrejaId.petrolina, perfil: PerfilComunitario.lider);
      expect(a.podeGerenciarCicloDeVidaDe(alvoOutraIgreja), isFalse);
      expect(a.motivoNegativaCicloDeVida(alvoOutraIgreja), contains('outra unidade'));
    });
  });

  group('isolamento — selecionar igreja nunca concede acesso', () {
    test('vínculo de Olinda não autoriza nada em Petrolina', () {
      final v = vinculo(perfil: PerfilComunitario.pastor, igreja: IgrejaId.olinda);
      final a = Autorizacao(
        uid: v.uid,
        igrejaId: IgrejaId.petrolina, // "trocou" a unidade no frontend
        vinculo: v,
      );
      expect(a.temVinculoAtivo, isFalse);
      expect(a.podeLerFinancas, isFalse);
      expect(a.podeGerenciarConteudo, isFalse);
      expect(a.podeAprovarMembro, isFalse);
      expect(a.podeGerenciarLideranca, isFalse);
      expect(a.podeAcessarPainel, isFalse);
      expect(a.perfilEfetivo, PerfilComunitario.membro);
    });

    test('sem vínculo não autoriza nada', () {
      final a = Autorizacao.semVinculo(uid: 'x', igrejaId: IgrejaId.olinda);
      expect(a.podeAcessarPainel, isFalse);
      expect(a.podeLerFinancas, isFalse);
      expect(a.podeLerAuditoria, isFalse);
    });
  });

  group('auditoria e conteúdo', () {
    test('nenhum cliente escreve auditoria', () {
      expect(auth(vinculo(perfil: PerfilComunitario.pastor)).podeEscreverAuditoria, isFalse);
    });

    test('liderança lê auditoria; editor não', () {
      expect(auth(vinculo(perfil: PerfilComunitario.lider)).podeLerAuditoria, isTrue);
      final editor = auth(vinculo(funcoes: {FuncaoAdmin.editor}));
      expect(editor.podeLerAuditoria, isFalse);
    });

    test('somente super_admin gerencia igrejas', () {
      expect(auth(vinculo(perfil: PerfilComunitario.pastor)).podeGerenciarIgrejas, isFalse);
      final sa = Autorizacao.semVinculo(
        uid: 'sa',
        igrejaId: IgrejaId.olinda,
        isSuperAdmin: true,
      );
      expect(sa.podeGerenciarIgrejas, isTrue);
    });

    test('pastor configura a unidade; líder apenas lê', () {
      expect(auth(vinculo(perfil: PerfilComunitario.pastor)).podeConfigurarIgreja, isTrue);
      expect(auth(vinculo(perfil: PerfilComunitario.lider)).podeConfigurarIgreja, isFalse);
    });

    test('editor e moderador acessam o painel, sem finanças', () {
      final editor = auth(vinculo(funcoes: {FuncaoAdmin.editor}));
      expect(editor.podeAcessarPainel, isTrue);
      expect(editor.podeLerFinancas, isFalse);
    });
  });
}
