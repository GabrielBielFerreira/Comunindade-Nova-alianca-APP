import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_alianca_app/features/perfil/data/foto_perfil_repository.dart';
import 'package:nova_alianca_app/features/perfil/providers/foto_perfil_provider.dart';

/// Repositório falso: registra o que foi enviado e permite forçar falha.
class _RepositorioFalso implements FotoPerfilRepository {
  _RepositorioFalso({this.erro});

  /// Quando presente, `enviar` lança isto.
  final Object? erro;

  final enviados = <String>[];

  /// Segura o envio até `concluir` ser chamado, para observar o estado
  /// intermediário.
  final espera = Completer<void>();
  bool usarEspera = false;

  @override
  Future<String> enviar({required String uid, required File arquivo}) async {
    if (usarEspera) await espera.future;
    if (erro != null) throw erro!;
    enviados.add('$uid:${arquivo.path}');
    return 'https://storage.exemplo/perfil/$uid/avatar';
  }
}

void main() {
  group('Caminho e validação', () {
    test('o caminho é fixo por uid — a foto nova sobrescreve a anterior', () {
      expect(
        FotoPerfilRepository.caminhoDe('uid-ana'),
        'perfil/uid-ana/avatar',
      );
      expect(
        FotoPerfilRepository.caminhoDe('uid-bruno'),
        'perfil/uid-bruno/avatar',
      );
    });

    test('deduz o contentType pela extensão', () {
      expect(FotoPerfilRepository.contentTypeDe('foto.jpg'), 'image/jpeg');
      expect(FotoPerfilRepository.contentTypeDe('FOTO.JPEG'), 'image/jpeg');
      expect(FotoPerfilRepository.contentTypeDe('a/b/c.png'), 'image/png');
      expect(FotoPerfilRepository.contentTypeDe('x.webp'), 'image/webp');
    });

    test('formato não suportado não vira upload', () {
      expect(FotoPerfilRepository.contentTypeDe('doc.pdf'), isNull);
      expect(FotoPerfilRepository.contentTypeDe('sem_extensao'), isNull);

      expect(
        () => FotoPerfilRepository.validar(caminho: 'doc.pdf', bytes: 100),
        throwsA(
          isA<FotoPerfilInvalida>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('JPG'),
          ),
        ),
      );
    });

    test('aceita exatamente 2 MB e recusa acima disso', () {
      const limite = FotoPerfilRepository.limiteBytes;
      expect(limite, 2 * 1024 * 1024);

      // No limite: passa.
      FotoPerfilRepository.validar(caminho: 'foto.jpg', bytes: limite);

      expect(
        () => FotoPerfilRepository.validar(
          caminho: 'foto.jpg',
          bytes: limite + 1,
        ),
        throwsA(
          isA<FotoPerfilInvalida>().having(
            (e) => e.mensagem,
            'mensagem',
            allOf(contains('2 MB'), contains('2.0 MB')),
          ),
        ),
      );
    });

    test('recusa arquivo vazio', () {
      expect(
        () => FotoPerfilRepository.validar(caminho: 'foto.jpg', bytes: 0),
        throwsA(isA<FotoPerfilInvalida>()),
      );
    });

    test('pede ao seletor uma imagem já reduzida', () {
      // Sem isto, uma foto de câmera de 8 MB subiria inteira para exibir um
      // avatar de 104 px.
      expect(FotoPerfilRepository.ladoMaximo, 512);
      expect(FotoPerfilRepository.qualidade, lessThan(100));
    });
  });

  group('Estado do envio', () {
    ProviderContainer containerCom(_RepositorioFalso repo) {
      final c = ProviderContainer(
        overrides: [fotoPerfilRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('mostra preview local enquanto envia e limpa ao concluir', () async {
      final repo = _RepositorioFalso()..usarEspera = true;
      final c = containerCom(repo);
      final arquivo = File('foto.jpg');

      final envio = c
          .read(fotoPerfilProvider.notifier)
          .enviar(uid: 'uid-ana', arquivo: arquivo);

      // Durante o upload a tela já mostra a foto escolhida.
      expect(c.read(fotoPerfilProvider).enviando, isTrue);
      expect(c.read(fotoPerfilProvider).previewLocal, arquivo);

      repo.espera.complete();
      expect(await envio, isTrue);

      // Concluído: quem manda passa a ser a URL persistida.
      expect(c.read(fotoPerfilProvider).enviando, isFalse);
      expect(c.read(fotoPerfilProvider).previewLocal, isNull);
      expect(c.read(fotoPerfilProvider).erro, isNull);
      expect(repo.enviados, ['uid-ana:foto.jpg']);
    });

    test('falha descarta o preview e a foto anterior volta', () async {
      final repo = _RepositorioFalso(erro: Exception('sem rede'));
      final c = containerCom(repo);

      final ok = await c
          .read(fotoPerfilProvider.notifier)
          .enviar(uid: 'uid-ana', arquivo: File('foto.jpg'));

      expect(ok, isFalse);
      // Manter o preview daria a impressão de que a troca deu certo.
      expect(c.read(fotoPerfilProvider).previewLocal, isNull);
      expect(c.read(fotoPerfilProvider).enviando, isFalse);
      expect(c.read(fotoPerfilProvider).erro, contains('conexão'));
    });

    test('erro de validação chega à tela com o motivo real', () async {
      final repo = _RepositorioFalso(
        erro: const FotoPerfilInvalida(
          'A imagem tem 5.0 MB e o limite é 2 MB.',
        ),
      );
      final c = containerCom(repo);

      final ok = await c
          .read(fotoPerfilProvider.notifier)
          .enviar(uid: 'uid-ana', arquivo: File('grande.jpg'));

      expect(ok, isFalse);
      expect(c.read(fotoPerfilProvider).erro, contains('5.0 MB'));
    });

    test('limparErro não apaga mais nada do estado', () async {
      final repo = _RepositorioFalso(erro: Exception('x'));
      final c = containerCom(repo);

      await c
          .read(fotoPerfilProvider.notifier)
          .enviar(uid: 'uid-ana', arquivo: File('foto.jpg'));
      expect(c.read(fotoPerfilProvider).erro, isNotNull);

      c.read(fotoPerfilProvider.notifier).limparErro();
      expect(c.read(fotoPerfilProvider).erro, isNull);
    });
  });
}
