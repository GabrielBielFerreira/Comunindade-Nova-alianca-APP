import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Igreja escolhida durante o ONBOARDING, antes de existir conta.
///
/// Diferente de `igrejaVisualizadaProvider`: aquele é contexto de leitura de
/// quem já tem vínculo; este é o destino do cadastro que ainda vai nascer.
///
/// Persiste porque o fluxo pode sair do aplicativo e voltar (login Google abre
/// o navegador/aba de contas); perder a escolha no meio faria o cadastro
/// terminar sem vínculo.
class EscolhaIgrejaNotifier extends StateNotifier<IgrejaId?> {
  EscolhaIgrejaNotifier() : super(null) {
    _carregar();
  }

  static const _chave = 'igreja_escolhida_cadastro_id';

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    state = IgrejaId.tentar(prefs.getString(_chave));
  }

  Future<void> definir(IgrejaId id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, id.valor);
  }

  /// Chamada após o cadastro concluir — a escolha já virou vínculo.
  Future<void> limpar() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }
}

final igrejaEscolhidaCadastroProvider =
    StateNotifierProvider<EscolhaIgrejaNotifier, IgrejaId?>(
  (ref) => EscolhaIgrejaNotifier(),
);
