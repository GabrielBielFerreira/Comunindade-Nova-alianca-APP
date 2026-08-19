import 'package:flutter/material.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

/// O que o superadministrador confirmou no diálogo de transferência.
class PedidoTransferencia {
  const PedidoTransferencia({
    required this.destino,
    required this.motivo,
    required this.confirmarSaidaDePastor,
  });

  final IgrejaId destino;
  final String motivo;
  final bool confirmarSaidaDePastor;
}

/// Transferência OFICIAL de vínculo entre unidades.
///
/// É a única ação do painel que muda a igreja PRINCIPAL de alguém — por isso
/// pede destino, motivo e uma confirmação explícita, e diz em texto que cargos
/// e permissões não acompanham a pessoa. O servidor exige `super_admin` de
/// novo: esconder o botão é conveniência, não a segurança.
class DialogoTransferencia extends StatefulWidget {
  const DialogoTransferencia({
    super.key,
    required this.pessoa,
    required this.origem,
    required this.nomeOrigem,
    required this.unidades,
    required this.ehPastorNaOrigem,
  });

  final String pessoa;
  final IgrejaId origem;
  final String nomeOrigem;

  /// Unidades da rede. A origem é filtrada aqui dentro.
  final List<IgrejaModel> unidades;

  /// Quando `true`, o servidor exige confirmação extra da saída do pastor.
  final bool ehPastorNaOrigem;

  static Future<PedidoTransferencia?> mostrar(
    BuildContext context, {
    required String pessoa,
    required IgrejaId origem,
    required String nomeOrigem,
    required List<IgrejaModel> unidades,
    required bool ehPastorNaOrigem,
  }) {
    return showDialog<PedidoTransferencia>(
      context: context,
      builder: (_) => DialogoTransferencia(
        pessoa: pessoa,
        origem: origem,
        nomeOrigem: nomeOrigem,
        unidades: unidades,
        ehPastorNaOrigem: ehPastorNaOrigem,
      ),
    );
  }

  @override
  State<DialogoTransferencia> createState() => _DialogoTransferenciaState();
}

class _DialogoTransferenciaState extends State<DialogoTransferencia> {
  final _motivo = TextEditingController();
  IgrejaId? _destino;
  bool _confirmado = false;
  bool _confirmadoPastor = false;

  static const _minimoMotivo = 5;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  List<IgrejaModel> get _destinos =>
      widget.unidades.where((u) => u.id != widget.origem).toList();

  bool get _valido =>
      _destino != null &&
      _motivo.text.trim().length >= _minimoMotivo &&
      _confirmado &&
      (!widget.ehPastorNaOrigem || _confirmadoPastor);

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final destinos = _destinos;
    final larguraTela = MediaQuery.sizeOf(context).width;

    return AlertDialog(
      title: const Text('Transferir para outra igreja'),
      content: SizedBox(
        // Em tela estreita quem limita a largura e o proprio AlertDialog:
        // fixar 460 ali estouraria a horizontal do aparelho.
        width: larguraTela < 520 ? double.maxFinite : 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.pessoa,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                // "Unidade de origem", e não "igreja atual": esta é a unidade
                // em foco no painel, que o servidor exige ser também a igreja
                // PRINCIPAL da pessoa. Se ela for membro de outra, a operação
                // é recusada com essa explicação.
                'Unidade de origem: ${widget.nomeOrigem}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cores.outline),
              ),
              const SizedBox(height: 20),

              if (destinos.isEmpty)
                Text(
                  'Não há outra unidade cadastrada na rede para receber esta '
                  'pessoa.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                DropdownButtonFormField<IgrejaId>(
                  initialValue: _destino,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Igreja de destino',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final unidade in destinos)
                      DropdownMenuItem(
                        value: unidade.id,
                        child: Text(
                          unidade.ativa
                              ? unidade.nome
                              : '${unidade.nome} (inativa)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (valor) => setState(() => _destino = valor),
                ),

              const SizedBox(height: 16),
              _Aviso(
                icone: Icons.info_outline,
                cor: cores.outline,
                texto:
                    'Só é possível transferir a partir da igreja PRINCIPAL da '
                    'pessoa: um vínculo secundário não muda onde ela é membro. '
                    'Cargos e permissões NÃO são transportados. A pessoa chega '
                    'ao destino como membro comum, sem função administrativa e '
                    'sem ministérios. O vínculo em ${widget.nomeOrigem} fica '
                    'inativo, com todo o histórico preservado.',
              ),

              if (widget.ehPastorNaOrigem) ...[
                const SizedBox(height: 12),
                _Aviso(
                  icone: Icons.warning_amber_outlined,
                  cor: cores.error,
                  texto:
                      'Esta pessoa é pastor em ${widget.nomeOrigem}. A unidade '
                      'pode ficar sem pastor após a transferência.',
                ),
              ],

              const SizedBox(height: 16),
              TextField(
                controller: _motivo,
                maxLines: 3,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Motivo (obrigatório)',
                  helperText:
                      'Fica registrado na auditoria das duas unidades, com '
                      'autor e data.',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
              ),

              CheckboxListTile(
                value: _confirmado,
                onChanged: (v) => setState(() => _confirmado = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Confirmo a transferência do vínculo oficial.',
                ),
              ),
              if (widget.ehPastorNaOrigem)
                CheckboxListTile(
                  value: _confirmadoPastor,
                  onChanged: (v) =>
                      setState(() => _confirmadoPastor = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Confirmo a saída deste pastor de ${widget.nomeOrigem}.',
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _valido
              ? () => Navigator.of(context).pop(
                  PedidoTransferencia(
                    destino: _destino!,
                    motivo: _motivo.text.trim(),
                    confirmarSaidaDePastor: _confirmadoPastor,
                  ),
                )
              : null,
          child: const Text('Transferir'),
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icone, required this.cor, required this.texto});

  final IconData icone;
  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 18, color: cor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cor),
          ),
        ),
      ],
    );
  }
}
