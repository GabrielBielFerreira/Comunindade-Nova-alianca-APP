import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/config/app_config.dart';

/// Resultado de um PIX dinâmico criado no backend.
class ResultadoPix {
  const ResultadoPix({
    required this.transacaoId,
    this.copiaECola,
    this.qrCodeBase64,
  });

  final String transacaoId;
  final String? copiaECola;
  final String? qrCodeBase64;
}

/// Cliente das Cloud Functions de pagamento (Mercado Pago).
///
/// NUNCA processa dados de cartão no app nem guarda segredos — apenas chama as
/// funções server-side. O status definitivo vem do webhook (server-side).
/// Só deve ser usado quando [AppConfig.pagamentosOnlineHabilitado] for true e as
/// funções estiverem publicadas (ver functions/README.md).
class PagamentosService {
  PagamentosService({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  final FirebaseFunctions _fn;

  Future<ResultadoPix> criarPix({
    required String tipo,
    required double valor,
    required String igrejaId,
  }) async {
    final res = await _fn.httpsCallable('criarContribuicaoPix').call({
      'tipo': tipo,
      'valor': valor,
      'igrejaId': igrejaId,
    });
    final data = Map<String, dynamic>.from(res.data as Map);
    return ResultadoPix(
      transacaoId: data['transacaoId'] as String? ?? '',
      copiaECola: data['copiaECola'] as String?,
      qrCodeBase64: data['qrCodeBase64'] as String?,
    );
  }

  /// Retorna a URL do Checkout Pro (cartão/boleto) para abrir em WebView segura.
  Future<String> criarCheckout({
    required String tipo,
    required double valor,
    required String igrejaId,
  }) async {
    final res = await _fn.httpsCallable('criarContribuicaoCheckout').call({
      'tipo': tipo,
      'valor': valor,
      'igrejaId': igrejaId,
    });
    final data = Map<String, dynamic>.from(res.data as Map);
    return data['initPoint'] as String? ?? '';
  }
}
