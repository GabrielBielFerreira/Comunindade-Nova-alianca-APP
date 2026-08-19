import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Camada fina sobre o FCM, para os testes observarem as inscrições sem
/// precisar do Firebase de verdade.
abstract class TopicosFcm {
  Future<void> inscrever(String topico);
  Future<void> cancelar(String topico);
}

class TopicosFcmFirebase implements TopicosFcm {
  const TopicosFcmFirebase();

  @override
  Future<void> inscrever(String topico) =>
      FirebaseMessaging.instance.subscribeToTopic(topico);

  @override
  Future<void> cancelar(String topico) =>
      FirebaseMessaging.instance.unsubscribeFromTopic(topico);
}

/// Preferências de notificação, com tópicos POR IGREJA.
///
/// ## Por que o tópico carrega o `igrejaId`
///
/// Antes as inscrições eram globais (`transmissoes`, `eventos`,
/// `comunicacoes`): um aviso de Olinda chegava no aparelho de quem é membro de
/// Petrolina, porque todo mundo estava no mesmo tópico. O nome do tópico passa
/// a ser derivado do [IgrejaId] — nunca do nome da igreja, que muda e repete.
///
/// Formato oficial, para uso no Firebase Console e nas Functions futuras:
///
/// ```text
/// igreja_<igrejaId>_transmissoes
/// igreja_<igrejaId>_eventos
/// igreja_<igrejaId>_comunicacoes
/// ```
///
/// Exemplo: `igreja_olinda_eventos`, `igreja_petrolina_comunicacoes`.
///
/// ## Qual igreja manda
///
/// Sempre a igreja PRINCIPAL (o vínculo oficial), nunca a visualizada.
/// Espiar Petrolina por alguns minutos não pode reconfigurar de forma
/// permanente as notificações de quem é membro de Olinda. Quando a igreja
/// principal muda de verdade — transferência oficial —, a inscrição anterior
/// é cancelada antes da nova.
class NotificationPreferences {
  NotificationPreferences._();

  /// Substituível nos testes.
  static TopicosFcm topicos = const TopicosFcmFirebase();

  static const chaveTransmissoes = 'notif_transmissoes';
  static const chaveEventos = 'notif_eventos';
  static const chaveComunicacoes = 'notif_comunicacoes';

  /// Sufixo do tópico por preferência.
  static const _sufixos = <String, String>{
    chaveTransmissoes: 'transmissoes',
    chaveEventos: 'eventos',
    chaveComunicacoes: 'comunicacoes',
  };

  /// Tópicos globais da versão anterior. O aparelho precisa SAIR deles, senão
  /// continua recebendo notificação de outra unidade para sempre.
  static const topicosGlobaisAntigos = <String>[
    'transmissoes',
    'eventos',
    'comunicacoes',
  ];

  /// Última unidade cujos tópicos este aparelho assinou.
  static const _chaveIgrejaInscrita = 'notif_igreja_inscrita';

  /// Marca de que a saída dos tópicos globais antigos já foi feita.
  static const _chaveMigrouGlobais = 'notif_migrou_topicos_globais';

  /// Nome oficial do tópico. Público para o painel e a documentação usarem a
  /// mesma regra, em vez de montar a string à mão.
  static String topicoDe(IgrejaId igrejaId, String chave) {
    final sufixo = _sufixos[chave];
    if (sufixo == null) {
      throw ArgumentError.value(chave, 'chave', 'Preferência desconhecida.');
    }
    return 'igreja_${igrejaId.valor}_$sufixo';
  }

  /// Lê todas as preferências (padrão: ligado).
  static Future<Map<String, bool>> lerTodas() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final chave in _sufixos.keys) chave: prefs.getBool(chave) ?? true,
    };
  }

  /// Salva a preferência e aplica imediatamente na unidade informada.
  ///
  /// Com [igrejaId] nulo a escolha é guardada, mas nada é assinado: sem
  /// vínculo oficial não há unidade de onde receber.
  static Future<void> definir(
    String chave,
    bool ativo, {
    required IgrejaId? igrejaId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(chave, ativo);
    if (igrejaId == null) return;
    await _aplicar(igrejaId, chave, ativo);
  }

  /// Põe as inscrições em dia para a igreja principal [igrejaId].
  ///
  /// Idempotente: chamar de novo com a mesma unidade não muda nada. Chamar com
  /// outra unidade cancela a anterior antes de assinar a nova.
  static Future<void> sincronizar(IgrejaId? igrejaId) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Sair dos tópicos globais da versão anterior, uma única vez.
    if (!(prefs.getBool(_chaveMigrouGlobais) ?? false)) {
      var saiuDeTodos = true;
      for (final antigo in topicosGlobaisAntigos) {
        try {
          await topicos.cancelar(antigo);
        } catch (_) {
          // Sem rede agora; tenta de novo na próxima sincronização.
          saiuDeTodos = false;
        }
      }
      if (saiuDeTodos) await prefs.setBool(_chaveMigrouGlobais, true);
    }

    // 2. Trocou de unidade? Cancela a anterior por inteiro.
    final anterior = IgrejaId.tentar(prefs.getString(_chaveIgrejaInscrita));
    if (anterior != null && anterior != igrejaId) {
      for (final chave in _sufixos.keys) {
        try {
          await topicos.cancelar(topicoDe(anterior, chave));
        } catch (_) {
          // Idem: reaplicado na próxima sincronização.
        }
      }
      await prefs.remove(_chaveIgrejaInscrita);
    }

    // Visitante ou perfil ainda carregando: não assina nada.
    if (igrejaId == null) return;

    // 3. Aplica as preferências na unidade atual.
    final valores = await lerTodas();
    for (final entry in valores.entries) {
      await _aplicar(igrejaId, entry.key, entry.value);
    }
    await prefs.setString(_chaveIgrejaInscrita, igrejaId.valor);
  }

  /// Cancela tudo — usado no logout, para o aparelho não continuar recebendo
  /// notificação de uma unidade cuja sessão já terminou.
  static Future<void> cancelarTudo() async {
    final prefs = await SharedPreferences.getInstance();
    final inscrita = IgrejaId.tentar(prefs.getString(_chaveIgrejaInscrita));
    if (inscrita == null) return;

    for (final chave in _sufixos.keys) {
      try {
        await topicos.cancelar(topicoDe(inscrita, chave));
      } catch (_) {
        // Falha de rede não pode travar o logout.
      }
    }
    await prefs.remove(_chaveIgrejaInscrita);
  }

  static Future<void> _aplicar(
    IgrejaId igrejaId,
    String chave,
    bool ativo,
  ) async {
    final topico = topicoDe(igrejaId, chave);
    try {
      if (ativo) {
        await topicos.inscrever(topico);
      } else {
        await topicos.cancelar(topico);
      }
    } catch (_) {
      // Falha de rede não deve quebrar a UI; é reaplicado no próximo start.
    }
  }
}
