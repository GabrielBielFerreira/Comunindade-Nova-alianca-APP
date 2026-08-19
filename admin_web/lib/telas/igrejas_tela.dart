import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../estado/providers.dart';
import '../ui/componentes.dart';
import '../ui/tema.dart';

/// Gestão de unidades — exclusiva do superadministrador.
///
/// Uma unidade nova nasce INATIVA e NÃO CONFIGURADA. Nada é preenchido por
/// suposição: enquanto os dados oficiais não chegarem, a interface mostra
/// "Não configurado".
class IgrejasTela extends ConsumerWidget {
  const IgrejasTela({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acessos = ref.watch(meusAcessosProvider).valueOrNull;

    if (acessos == null) return const CarregandoCentralizado();
    if (!acessos.isSuperAdmin) {
      return const EstadoVazio(
        titulo: 'Área restrita',
        detalhe: 'Somente o superadministrador gerencia as unidades da rede.',
        icone: Icons.lock_outline,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final titulo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Igrejas',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Unidades da rede Nova Aliança.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              );
              final botao = FilledButton.icon(
                onPressed: () => _criarIgreja(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nova unidade'),
              );

              // Em aparelho estreito o botao desce para baixo do titulo em
              // vez de disputar a mesma linha e estourar a largura.
              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [titulo, const SizedBox(height: 12), botao],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: titulo), botao],
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ref.watch(igrejasProvider).when(
                loading: () => const CarregandoCentralizado(),
                error: (e, _) => EstadoErro(
                  erro: e,
                  onTentarNovamente: () => ref.invalidate(igrejasProvider),
                ),
                data: (lista) {
                  if (lista.isEmpty) {
                    return const EstadoVazio(
                      titulo: 'Nenhuma unidade cadastrada',
                      icone: Icons.church_outlined,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: lista.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _CartaoIgreja(igreja: lista[i]),
                  );
                },
              ),
        ),
      ],
    );
  }

  Future<void> _criarIgreja(BuildContext context, WidgetRef ref) async {
    final id = TextEditingController();
    final nome = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Nova unidade'),
        content: SizedBox(
          width: 460,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: id,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Identificador',
                helperText: 'Letras minúsculas, números e _ (ex.: recife)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nome,
              decoration: const InputDecoration(
                labelText: 'Nome oficial',
                helperText: 'Ex.: Nova Aliança Recife',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'A unidade será criada INATIVA e sem dados institucionais. '
              'Preencha-os depois, com as informações oficiais.',
              style: TextStyle(fontSize: 12, color: Cores.muted),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: const Text('Criar')),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    try {
      await ref.read(igrejasRepositoryProvider).criar(
            igrejaId: id.text.trim(),
            nome: nome.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unidade criada (inativa).')),
        );
      }
    } catch (erro) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falhou: $erro'), backgroundColor: Cores.erro),
        );
      }
    }
  }
}

class _CartaoIgreja extends ConsumerWidget {
  const _CartaoIgreja({required this.igreja});

  final IgrejaModel igreja;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Um unico Wrap em vez de Row + Wrap: numa Row o Wrap recebe
            // largura infinita e nunca quebra, entao as etiquetas vazavam o
            // cartao num aparelho estreito.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(igreja.nome,
                    style: Theme.of(context).textTheme.titleMedium),
                Etiqueta(
                  texto: igreja.ativa ? 'Ativa' : 'Inativa',
                  cor: igreja.ativa ? Cores.sucesso : Cores.muted,
                ),
                Etiqueta(
                  texto: igreja.configurada ? 'Configurada' : 'Não configurada',
                  cor: igreja.configurada ? Cores.info : Cores.alerta,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Linha('Identificador', igreja.id.valor),
            _Linha('Pastor', igreja.pastorExibicao),
            _Linha('Endereço', igreja.enderecoExibicao),
            _Linha('Mercado Pago', igreja.mercadoPagoStatus.rotulo),
            const SizedBox(height: 12),
            // Wrap, e nao Row: os dois botoes mais o aviso passam de 248 px,
            // que e o que sobra do cartao num aparelho de 320 px.
            Wrap(spacing: 10, runSpacing: 10, children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar dados'),
                onPressed: () => _editar(context, ref),
              ),
              OutlinedButton.icon(
                icon: Icon(
                  igreja.ativa
                      ? Icons.toggle_on_outlined
                      : Icons.toggle_off_outlined,
                  size: 16,
                ),
                label: Text(igreja.ativa ? 'Desativar' : 'Ativar'),
                // Ativar sem dados oficiais exibiria uma unidade vazia no
                // aplicativo; por isso o botão só libera quando configurada.
                onPressed: (!igreja.ativa && !igreja.configurada)
                    ? null
                    : () => _alternarAtiva(context, ref),
              ),
              if (!igreja.ativa && !igreja.configurada)
                const Text(
                  'Preencha os dados institucionais para poder ativar.',
                  style: TextStyle(fontSize: 12, color: Cores.alerta),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _alternarAtiva(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(igrejasRepositoryProvider)
          .atualizar(igrejaId: igreja.id, ativa: !igreja.ativa);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(igreja.ativa ? 'Unidade desativada.' : 'Unidade ativada.'),
          ),
        );
      }
    } catch (erro) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falhou: $erro'), backgroundColor: Cores.erro),
        );
      }
    }
  }

  Future<void> _editar(BuildContext context, WidgetRef ref) async {
    final nome = TextEditingController(text: igreja.nome);
    final pastor = TextEditingController(text: igreja.pastorResponsavel ?? '');
    final endereco = TextEditingController(text: igreja.endereco ?? '');
    final cidade = TextEditingController(text: igreja.cidadeEstado ?? '');
    final telefone = TextEditingController(text: igreja.telefone ?? '');
    final instagram = TextEditingController(text: igreja.instagram ?? '');
    final pix = TextEditingController(text: igreja.pixChave ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Editar ${igreja.nome}'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: nome,
                  decoration: const InputDecoration(labelText: 'Nome oficial')),
              const SizedBox(height: 12),
              TextField(
                  controller: pastor,
                  decoration:
                      const InputDecoration(labelText: 'Pastor responsável')),
              const SizedBox(height: 12),
              TextField(
                  controller: endereco,
                  decoration: const InputDecoration(labelText: 'Endereço')),
              const SizedBox(height: 12),
              TextField(
                  controller: cidade,
                  decoration:
                      const InputDecoration(labelText: 'Cidade / Estado')),
              const SizedBox(height: 12),
              TextField(
                  controller: telefone,
                  decoration: const InputDecoration(labelText: 'Telefone')),
              const SizedBox(height: 12),
              TextField(
                  controller: instagram,
                  decoration: const InputDecoration(labelText: 'Instagram')),
              const SizedBox(height: 12),
              TextField(
                  controller: pix,
                  decoration: const InputDecoration(
                    labelText: 'Chave PIX manual',
                    helperText: 'Deixe vazio se ainda não houver chave própria.',
                  )),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: const Text('Salvar')),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    String? vazioParaNulo(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    try {
      await ref.read(igrejasRepositoryProvider).atualizar(
        igrejaId: igreja.id,
        nome: nome.text.trim(),
        dadosInstitucionais: {
          'pastor_responsavel': vazioParaNulo(pastor),
          'endereco': vazioParaNulo(endereco),
          'cidade_estado': vazioParaNulo(cidade),
          'telefone': vazioParaNulo(telefone),
          'instagram': vazioParaNulo(instagram),
          'pix_chave': vazioParaNulo(pix),
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados da unidade atualizados.')),
        );
      }
    } catch (erro) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falhou: $erro'), backgroundColor: Cores.erro),
        );
      }
    }
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final naoConfigurado = valor == IgrejaModel.naoConfigurado;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(rotulo,
                style: const TextStyle(fontSize: 13, color: Cores.muted)),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 13,
                color: naoConfigurado ? Cores.alerta : Cores.titulo,
                fontStyle: naoConfigurado ? FontStyle.italic : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
