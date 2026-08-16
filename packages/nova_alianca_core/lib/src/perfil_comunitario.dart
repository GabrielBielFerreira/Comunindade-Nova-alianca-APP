import 'normalizacao.dart';

/// Perfil comunitário da pessoa **dentro de uma unidade**.
///
/// Não confundir com [FuncaoAdmin]: o perfil descreve o papel ministerial;
/// as funções administrativas são atribuições operacionais adicionais.
enum PerfilComunitario {
  pastor,
  diacono,
  evangelista,
  lider,
  membro;

  /// Valor persistido no Firestore.
  String get valor => name;

  /// Aceita grafias com acento/maiúscula (`Líder`, `Diácono`). Desconhecido
  /// vira [PerfilComunitario.membro] — o perfil de menor privilégio.
  static PerfilComunitario deTexto(String? bruto) {
    if (bruto == null) return PerfilComunitario.membro;
    final chave = normalizarChave(bruto);
    for (final perfil in PerfilComunitario.values) {
      if (perfil.name == chave) return perfil;
    }
    return PerfilComunitario.membro;
  }

  /// Liderança ministerial: pastor, diácono, evangelista e líder.
  ///
  /// Grupo DERIVADO do perfil validado no servidor — nunca uma permissão
  /// gravável pelo cliente.
  bool get isLiderancaMinisterial =>
      this == PerfilComunitario.pastor ||
      this == PerfilComunitario.diacono ||
      this == PerfilComunitario.evangelista ||
      this == PerfilComunitario.lider;

  bool get isPastor => this == PerfilComunitario.pastor;

  /// Rótulo para interface.
  String get rotulo => switch (this) {
        PerfilComunitario.pastor => 'Pastor',
        PerfilComunitario.diacono => 'Diácono',
        PerfilComunitario.evangelista => 'Evangelista',
        PerfilComunitario.lider => 'Líder',
        PerfilComunitario.membro => 'Membro',
      };
}
