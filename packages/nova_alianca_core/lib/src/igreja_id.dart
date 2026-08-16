import 'normalizacao.dart';

/// Identificador estável de uma unidade da rede (o `{igrejaId}` do caminho
/// `/igrejas/{igrejaId}` no Firestore).
///
/// É um value object para impedir que uma `String` qualquer — vinda de um
/// campo de formulário, de um parâmetro de rota ou de um payload de cliente —
/// seja usada como escopo de dados por engano.
class IgrejaId {
  const IgrejaId._(this.valor);

  /// Cria um id a partir de um texto livre, normalizando-o.
  /// Lança [ArgumentError] quando o resultado não é um id utilizável.
  factory IgrejaId(String bruto) {
    final normalizado = normalizarChave(bruto);
    if (!_padrao.hasMatch(normalizado)) {
      throw ArgumentError.value(
        bruto,
        'bruto',
        'IgrejaId inválido: use apenas letras, números e "_" (2 a 40 caracteres).',
      );
    }
    return IgrejaId._(normalizado);
  }

  /// Retorna `null` em vez de lançar, para entradas não confiáveis.
  static IgrejaId? tentar(String? bruto) {
    if (bruto == null) return null;
    try {
      return IgrejaId(bruto);
    } on ArgumentError {
      return null;
    }
  }

  static final RegExp _padrao = RegExp(r'^[a-z0-9_]{2,40}$');

  final String valor;

  /// Sede e primeira unidade operacional.
  static final IgrejaId olinda = IgrejaId('olinda');

  /// Segunda unidade.
  static final IgrejaId petrolina = IgrejaId('petrolina');

  @override
  bool operator ==(Object other) => other is IgrejaId && other.valor == valor;

  @override
  int get hashCode => valor.hashCode;

  @override
  String toString() => valor;
}
