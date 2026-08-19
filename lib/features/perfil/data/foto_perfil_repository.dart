import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Erro de validação da foto, com mensagem já pronta para a tela.
///
/// Existe para a interface não precisar interpretar exceção do Storage: o que
/// a pessoa vê é o motivo real (arquivo grande demais, formato não suportado).
class FotoPerfilInvalida implements Exception {
  const FotoPerfilInvalida(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Envio e persistência da foto de perfil.
///
/// ## Caminho estável
///
/// A foto vai sempre para `perfil/{uid}/avatar`, sobrescrevendo a anterior.
/// Um caminho com timestamp acumularia um arquivo por troca de foto, e ninguém
/// apagaria os antigos — armazenamento pago crescendo para sempre.
///
/// ## O que é gravado
///
/// Depois do upload, a URL vai para `usuarios/{uid}.foto_url` (é dali que o
/// aplicativo lê ao abrir) e também para `photoURL` do Firebase Auth, que é o
/// que aparece em ferramentas administrativas.
abstract class FotoPerfilRepository {
  /// Envia [arquivo] e devolve a URL pública de download.
  Future<String> enviar({required String uid, required File arquivo});

  /// Caminho no Storage. Público para as regras e os testes usarem a mesma
  /// definição, em vez de repetir a string.
  static String caminhoDe(String uid) => 'perfil/$uid/avatar';

  /// Teto de tamanho, igual ao das Storage Rules.
  static const limiteBytes = 2 * 1024 * 1024;

  /// Lado máximo pedido ao seletor de imagem.
  static const ladoMaximo = 512;

  /// Qualidade de recompressão pedida ao seletor.
  static const qualidade = 85;

  static const _tiposPorExtensao = <String, String>{
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.webp': 'image/webp',
    '.heic': 'image/heic',
  };

  /// `contentType` a partir do nome do arquivo.
  ///
  /// As Storage Rules exigem `image/*`; enviar sem tipo faria o Storage
  /// assumir `application/octet-stream` e a própria regra recusaria.
  static String? contentTypeDe(String caminho) {
    final ponto = caminho.lastIndexOf('.');
    if (ponto < 0) return null;
    return _tiposPorExtensao[caminho.substring(ponto).toLowerCase()];
  }

  /// Valida antes de gastar rede. Lança [FotoPerfilInvalida] com o motivo.
  static void validar({required String caminho, required int bytes}) {
    final tipo = contentTypeDe(caminho);
    if (tipo == null) {
      throw const FotoPerfilInvalida(
        'Formato de imagem não suportado. Use JPG, PNG ou WEBP.',
      );
    }
    if (bytes <= 0) {
      throw const FotoPerfilInvalida('A imagem selecionada está vazia.');
    }
    if (bytes > limiteBytes) {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      throw FotoPerfilInvalida(
        'A imagem tem $mb MB e o limite é 2 MB. Escolha uma foto menor.',
      );
    }
  }
}

class FotoPerfilRepositoryFirebase implements FotoPerfilRepository {
  FotoPerfilRepositoryFirebase({
    FirebaseStorage? storage,
    FirebaseFirestore? db,
    FirebaseAuth? auth,
  }) : _storageInjetado = storage,
       _dbInjetado = db,
       _authInjetado = auth;

  final FirebaseStorage? _storageInjetado;
  final FirebaseFirestore? _dbInjetado;
  final FirebaseAuth? _authInjetado;

  // Resolvidos sob demanda: construir o repositório não exige Firebase
  // inicializado, o que permite montar as telas em teste de widget.
  late final FirebaseStorage _storage =
      _storageInjetado ?? FirebaseStorage.instance;
  late final FirebaseFirestore _db = _dbInjetado ?? FirebaseFirestore.instance;
  late final FirebaseAuth _auth = _authInjetado ?? FirebaseAuth.instance;

  @override
  Future<String> enviar({required String uid, required File arquivo}) async {
    final bytes = await arquivo.length();
    FotoPerfilRepository.validar(caminho: arquivo.path, bytes: bytes);

    final referencia = _storage.ref(FotoPerfilRepository.caminhoDe(uid));

    await referencia.putFile(
      arquivo,
      SettableMetadata(
        contentType: FotoPerfilRepository.contentTypeDe(arquivo.path),
        // O caminho é fixo, então a URL não muda quando a foto troca. Sem um
        // cache curto, o aparelho continuaria mostrando a foto antiga.
        cacheControl: 'public, max-age=300',
      ),
    );

    final url = await referencia.getDownloadURL();

    // É daqui que o aplicativo lê a foto ao abrir. As Rules permitem que o
    // dono escreva o próprio documento, desde que não toque em campos de
    // autorização.
    await _db.collection('usuarios').doc(uid).set({
      'foto_url': url,
      'atualizado_em': Timestamp.now(),
    }, SetOptions(merge: true));

    // Espelha no Auth para as ferramentas administrativas. Uma falha aqui não
    // invalida o upload: a fonte da verdade do aplicativo é o Firestore.
    try {
      final usuario = _auth.currentUser;
      if (usuario != null && usuario.uid == uid) {
        await usuario.updatePhotoURL(url);
      }
    } catch (_) {
      // Silencioso de propósito — ver comentário acima.
    }

    return url;
  }
}
