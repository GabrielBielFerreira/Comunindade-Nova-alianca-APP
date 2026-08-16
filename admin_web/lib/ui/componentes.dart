import 'package:flutter/material.dart';

/// Estado vazio honesto: diz o que não existe, sem inventar conteúdo.
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({super.key, required this.titulo, this.detalhe, this.icone});

  final String titulo;
  final String? detalhe;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone ?? Icons.inbox_outlined, size: 48, color: cores.outline),
            const SizedBox(height: 12),
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            if (detalhe != null) ...[
              const SizedBox(height: 6),
              Text(
                detalhe!,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cores.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EstadoErro extends StatelessWidget {
  const EstadoErro({super.key, required this.erro, this.onTentarNovamente});

  final Object erro;
  final VoidCallback? onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cores.error),
            const SizedBox(height: 12),
            Text('Não foi possível carregar',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            SelectableText(
              '$erro',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cores.outline),
            ),
            if (onTentarNovamente != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onTentarNovamente,
                child: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CarregandoCentralizado extends StatelessWidget {
  const CarregandoCentralizado({super.key, this.mensagem});

  final String? mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (mensagem != null) ...[
            const SizedBox(height: 12),
            Text(mensagem!),
          ],
        ],
      ),
    );
  }
}

/// Cartão de métrica. `valor` sempre vem de contagem real.
class CartaoMetrica extends StatelessWidget {
  const CartaoMetrica({
    super.key,
    required this.rotulo,
    required this.valor,
    this.detalhe,
    this.icone,
    this.destaque = false,
  });

  final String rotulo;
  final String valor;
  final String? detalhe;
  final IconData? icone;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      color: destaque ? cores.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icone != null) ...[
                  Icon(icone, size: 18, color: cores.outline),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(rotulo,
                      style: Theme.of(context).textTheme.labelLarge),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(valor, style: Theme.of(context).textTheme.headlineSmall),
            if (detalhe != null) ...[
              const SizedBox(height: 4),
              Text(detalhe!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cores.outline)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Diálogo que exige um motivo. Usado em rebaixamento, inativação e recusa —
/// o backend rejeita a operação sem motivo, então o botão só habilita quando
/// o texto atinge o mínimo aceito.
class DialogoMotivo extends StatefulWidget {
  const DialogoMotivo({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.rotuloConfirmar,
    this.perigoso = true,
  });

  final String titulo;
  final String descricao;
  final String rotuloConfirmar;
  final bool perigoso;

  static Future<String?> mostrar(
    BuildContext context, {
    required String titulo,
    required String descricao,
    required String rotuloConfirmar,
    bool perigoso = true,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => DialogoMotivo(
        titulo: titulo,
        descricao: descricao,
        rotuloConfirmar: rotuloConfirmar,
        perigoso: perigoso,
      ),
    );
  }

  @override
  State<DialogoMotivo> createState() => _DialogoMotivoState();
}

class _DialogoMotivoState extends State<DialogoMotivo> {
  final _controller = TextEditingController();
  static const _minimo = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valido = _controller.text.trim().length >= _minimo;
    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.descricao),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Motivo (obrigatório)',
                helperText: 'Fica registrado na auditoria, com autor e data.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: widget.perigoso
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          onPressed:
              valido ? () => Navigator.of(context).pop(_controller.text.trim()) : null,
          child: Text(widget.rotuloConfirmar),
        ),
      ],
    );
  }
}

/// Etiqueta de status.
class Etiqueta extends StatelessWidget {
  const Etiqueta({super.key, required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cor.withValues(alpha: 0.5)),
      ),
      child: Text(
        texto,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: cor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
