import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

/// Escopo de dados de UMA unidade: tudo abaixo de `igrejas/{igrejaId}`.
///
/// Existe para que nenhum repositório monte caminho de coleção "à mão". Antes
/// da arquitetura multi-igreja os repositórios liam coleções globais
/// (`avisos`, `eventos`, ...), que as Rules atuais negam — este tipo é o ponto
/// único onde o `igrejaId` entra no caminho.
class IgrejaScope {
  IgrejaScope({required this.igrejaId, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final IgrejaId igrejaId;
  final FirebaseFirestore _db;

  FirebaseFirestore get db => _db;

  /// Documento da própria unidade.
  DocumentReference<Map<String, dynamic>> get doc =>
      _db.collection('igrejas').doc(igrejaId.valor);

  /// Subcoleção da unidade.
  CollectionReference<Map<String, dynamic>> colecao(String nome) =>
      doc.collection(nome);

  CollectionReference<Map<String, dynamic>> get avisos => colecao('avisos');
  CollectionReference<Map<String, dynamic>> get eventos => colecao('eventos');
  CollectionReference<Map<String, dynamic>> get campanhas => colecao('campanhas');
  CollectionReference<Map<String, dynamic>> get ministerios => colecao('ministerios');
  CollectionReference<Map<String, dynamic>> get devocionais => colecao('devocionais');
  CollectionReference<Map<String, dynamic>> get pedidosOracao => colecao('pedidos_oracao');
  CollectionReference<Map<String, dynamic>> get membros => colecao('membros');
  CollectionReference<Map<String, dynamic>> get transacoes => colecao('transacoes');
  CollectionReference<Map<String, dynamic>> get auditoria => colecao('auditoria');
  CollectionReference<Map<String, dynamic>> get interessesMinisterio =>
      colecao('interesses_ministerio');
  CollectionReference<Map<String, dynamic>> get configuracoes => colecao('configuracoes');

  @override
  bool operator ==(Object other) =>
      other is IgrejaScope && other.igrejaId == igrejaId;

  @override
  int get hashCode => igrejaId.hashCode;
}

/// Lançada quando um repositório de unidade é usado sem igreja em foco.
///
/// Na prática não deve acontecer: as telas que mutam dados só são alcançáveis
/// com uma unidade selecionada. Falhar alto aqui é melhor que gravar no lugar
/// errado ou espalhar `?.` por todas as chamadas.
class IgrejaNaoSelecionada implements Exception {
  const IgrejaNaoSelecionada();

  @override
  String toString() =>
      'Nenhuma igreja selecionada. Escolha uma unidade antes de continuar.';
}

/// Converte um valor cru do Firestore em `DateTime`.
DateTime? lerDataFirestore(dynamic valor) {
  if (valor is Timestamp) return valor.toDate();
  if (valor is DateTime) return valor;
  return null;
}
