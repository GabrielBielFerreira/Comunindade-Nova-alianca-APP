import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/foto_perfil_repository.dart';

/// Estado do envio da foto de perfil.
///
/// A foto PERSISTIDA não mora aqui: ela vem de `usuarios/{uid}.foto_url`,
/// pelo `usuarioAtualProvider`. Este estado guarda só o que é transitório —
/// o arquivo local mostrado enquanto o upload acontece e o erro da última
/// tentativa.
class EstadoFotoPerfil {
  const EstadoFotoPerfil({this.previewLocal, this.enviando = false, this.erro});

  /// Arquivo escolhido, exibido imediatamente para a tela não ficar parada
  /// esperando a rede.
  final File? previewLocal;

  final bool enviando;

  /// Mensagem da última falha. A foto anterior continua valendo.
  final String? erro;

  EstadoFotoPerfil copiarCom({
    File? previewLocal,
    bool? enviando,
    String? erro,
    bool limparErro = false,
    bool limparPreview = false,
  }) {
    return EstadoFotoPerfil(
      previewLocal: limparPreview ? null : (previewLocal ?? this.previewLocal),
      enviando: enviando ?? this.enviando,
      erro: limparErro ? null : (erro ?? this.erro),
    );
  }
}

class FotoPerfilNotifier extends StateNotifier<EstadoFotoPerfil> {
  FotoPerfilNotifier(this._repositorio) : super(const EstadoFotoPerfil());

  final FotoPerfilRepository _repositorio;

  /// Envia a foto e devolve `true` quando ela foi persistida.
  ///
  /// Em caso de falha, o preview é DESCARTADO e a foto anterior volta a
  /// aparecer: manter o preview daria a impressão de que a troca deu certo.
  Future<bool> enviar({required String uid, required File arquivo}) async {
    state = EstadoFotoPerfil(previewLocal: arquivo, enviando: true);

    try {
      await _repositorio.enviar(uid: uid, arquivo: arquivo);
      // O preview sai de cena porque a URL persistida já assumiu.
      state = const EstadoFotoPerfil();
      return true;
    } on FotoPerfilInvalida catch (erro) {
      state = EstadoFotoPerfil(erro: erro.mensagem);
      return false;
    } catch (_) {
      state = const EstadoFotoPerfil(
        erro:
            'Não foi possível enviar a foto. Verifique sua conexão e '
            'tente novamente.',
      );
      return false;
    }
  }

  void limparErro() => state = state.copiarCom(limparErro: true);
}

final fotoPerfilRepositoryProvider = Provider<FotoPerfilRepository>(
  (ref) => FotoPerfilRepositoryFirebase(),
);

final fotoPerfilProvider =
    StateNotifierProvider<FotoPerfilNotifier, EstadoFotoPerfil>(
      (ref) => FotoPerfilNotifier(ref.watch(fotoPerfilRepositoryProvider)),
    );

/// URL da foto persistida, ou `null` quando ainda não há uma.
///
/// Fonte única para todas as telas com avatar: enquanto o upload não terminar,
/// quem manda é o `previewLocal`; depois, é este valor.
final fotoPerfilUrlProvider = Provider<String?>((ref) {
  final url = ref.watch(usuarioAtualProvider).valueOrNull?.fotoUrl?.trim();
  return (url == null || url.isEmpty) ? null : url;
});
