import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../biblia/data/bible_book.dart';
import '../biblia/data/bible_models.dart';
import '../biblia/providers/bible_providers.dart';
import 'palavra_dia_calendario.dart';
import 'recife_time.dart';

/// Conteúdo da Palavra do Dia exibido na Home e em Oração.
///
/// O texto bíblico vem sempre da integração já existente (Almeida, domínio
/// público) — nunca é digitado à mão. A reflexão é conteúdo autoral opcional.
class PalavraDoDia {
  const PalavraDoDia({
    required this.id,
    required this.texto,
    required this.referencia,
    required this.traducao,
    required this.data,
    this.reflexao,
    this.especial = false,
  });

  /// Identificador único do conteúdo (posição no calendário ou "especial-...").
  final String id;

  /// Texto bíblico (pode vir vazio quando offline e sem cache: nesse caso a
  /// referência do dia — correta — ainda é exibida, sem inventar texto).
  final String texto;
  final String referencia;
  final String traducao;

  /// Data (fuso de Recife) a que este conteúdo se refere.
  final DateTime data;

  /// Pequena mensagem de reflexão (autoral), quando aplicável.
  final String? reflexao;

  /// Verdadeiro quando veio de uma publicação especial da liderança (Firebase).
  final bool especial;

  bool get temTexto => texto.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'texto': texto,
        'referencia': referencia,
        'traducao': traducao,
        'data': RecifeTime.chaveData(data),
        'reflexao': reflexao,
        'especial': especial,
      };

  factory PalavraDoDia.fromJson(Map<String, dynamic> j) {
    final dataStr = j['data'] as String?;
    DateTime data;
    try {
      final p = (dataStr ?? '').split('-');
      data = p.length == 3
          ? DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]))
          : RecifeTime.hoje();
    } catch (_) {
      data = RecifeTime.hoje();
    }
    return PalavraDoDia(
      id: j['id'] as String? ?? '',
      texto: j['texto'] as String? ?? '',
      referencia: j['referencia'] as String? ?? '',
      traducao: j['traducao'] as String? ?? 'Almeida (domínio público)',
      data: data,
      reflexao: j['reflexao'] as String?,
      especial: j['especial'] as bool? ?? false,
    );
  }
}

/// Data de hoje (fuso de Recife) que dispara a troca do conteúdo diário.
///
/// É atualizado ao abrir o app, ao retornar a ele e na virada da meia-noite de
/// Recife (ver o observador de ciclo de vida no root do app). Ao mudar, o
/// [palavraDoDiaProvider] recalcula automaticamente.
final dataHojeProvider = StateProvider<DateTime>((ref) => RecifeTime.hoje());

const _kPrefixoCache = 'palavra_do_dia_';
const _kCacheLegado = 'palavra_do_dia_cache';

/// Palavra do Dia. Ordem de resolução:
/// 1) publicação ESPECIAL da liderança (Firebase), dentro da validade;
/// 2) cache do DIA (offline correto — nunca o versículo de outro dia);
/// 3) calendário anual (referência local) + texto pela integração bíblica;
/// 4) offline sem cache: referência correta do dia (sem texto inventado).
final palavraDoDiaProvider =
    FutureProvider.autoDispose<PalavraDoDia>((ref) async {
  final hoje = ref.watch(dataHojeProvider);
  final prefs = await SharedPreferences.getInstance();
  final repo = ref.read(bibleRepositoryProvider);
  final traducao = repo.traducao;

  final chaveHoje = '$_kPrefixoCache${RecifeTime.chaveData(hoje)}';
  _limparCachesAntigos(prefs, chaveHoje);

  final refDia = PalavraDiaCalendario.paraData(hoje);
  final indice = PalavraDiaCalendario.indiceDoDia(hoje);

  // 1) Conteúdo especial da liderança (só quando online e dentro da validade).
  try {
    final doc = await FirebaseFirestore.instance
        .collection('configuracoes')
        .doc('palavra_do_dia')
        .get();
    final especial = lerPalavraEspecial(doc.data(), hoje, traducao);
    if (especial != null) return especial; // não cacheia especial (tem validade)
  } catch (_) {/* segue para o calendário */}

  // 2) Cache do dia (offline correto).
  final raw = prefs.getString(chaveHoje);
  if (raw != null) {
    try {
      final cached = PalavraDoDia.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
      if (cached.temTexto && !cached.especial) return cached;
    } catch (_) {/* ignora cache corrompido */}
  }

  // 3) Calendário anual + texto pela integração bíblica.
  final livro = livroPorNome(refDia.livro);
  if (livro != null) {
    try {
      final v = await repo.carregarVersiculo(
        BibleVerseRef(
          livroNome: livro.nome,
          livroApiName: livro.apiName,
          capitulo: refDia.capitulo,
          versiculo: refDia.versiculo,
        ),
      );
      final p = PalavraDoDia(
        id: refDia.idPara(indice),
        texto: v.texto,
        referencia: refDia.referencia,
        traducao: traducao,
        data: hoje,
        reflexao: refDia.reflexao,
      );
      await prefs.setString(chaveHoje, jsonEncode(p.toJson()));
      return p;
    } catch (_) {/* offline: cai para referência-somente */}
  }

  // 4) Offline sem cache: referência correta do dia (sem texto de outro dia).
  return PalavraDoDia(
    id: refDia.idPara(indice),
    texto: '',
    referencia: refDia.referencia,
    traducao: traducao,
    data: hoje,
    reflexao: refDia.reflexao,
  );
});

/// Interpreta a publicação especial (`configuracoes/palavra_do_dia`). Público
/// para permitir testes unitários das regras de validade.
///
/// Regras: precisa estar `ativo`, ter TEXTO, e a data/hora atual deve estar
/// dentro de [inicio, fim]. `fim` é OBRIGATÓRIO — assim uma publicação manual
/// nunca fica ativa indefinidamente; ao expirar, retorna null (o app volta
/// automaticamente ao calendário anual).
PalavraDoDia? lerPalavraEspecial(
    Map<String, dynamic>? d, DateTime hoje, String traducaoPadrao) {
  if (d == null) return null;
  final ativo = d['ativo'] as bool? ?? false;
  final texto = (d['texto'] as String? ?? '').trim();
  if (!ativo || texto.isEmpty) return null;

  final inicioTs = d['inicio'] as Timestamp?;
  final fimTs = d['fim'] as Timestamp?;
  if (fimTs == null) return null; // sem término definido: ignora (não indefinido)

  final agora = RecifeTime.agora();
  final inicio = inicioTs?.toDate();
  final fim = fimTs.toDate();
  if (inicio != null && agora.isBefore(inicio)) return null; // ainda não começou
  if (agora.isAfter(fim)) return null; // expirou → volta ao calendário

  final prioridade = (d['prioridade'] as num?)?.toInt() ?? 0;
  return PalavraDoDia(
    id: 'especial-$prioridade-${RecifeTime.chaveData(hoje)}',
    texto: texto,
    referencia: d['referencia'] as String? ?? '',
    traducao: (d['traducao'] as String?)?.trim().isNotEmpty == true
        ? d['traducao'] as String
        : traducaoPadrao,
    data: hoje,
    reflexao: (d['reflexao'] as String?)?.trim().isEmpty ?? true
        ? null
        : d['reflexao'] as String,
    especial: true,
  );
}

/// Remove caches de outras datas (e o cache legado), impedindo que o versículo
/// de ontem seja exibido como o de hoje.
void _limparCachesAntigos(SharedPreferences prefs, String chaveHoje) {
  for (final k in prefs.getKeys()) {
    if (k == _kCacheLegado ||
        (k.startsWith(_kPrefixoCache) && k != chaveHoje)) {
      prefs.remove(k);
    }
  }
}
