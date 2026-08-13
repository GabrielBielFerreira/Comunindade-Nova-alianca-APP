import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/data/usuario_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../avisos/data/ministerio_model.dart';
import '../../ministerios/providers/ministerios_providers.dart';
import '../widgets/admin_form_widgets.dart';
import 'selecionar_membro_screen.dart';

/// Formulário para criar/editar um ministério. Passe [ministerio] para editar;
/// nulo para criar. Escrita restrita à liderança pelas regras do Firestore.
///
/// `membros_count` e `lider_id` são preservados na edição (contagem é cache;
/// a atribuição de líder por membro fica para uma etapa com seletor dedicado).
class MinisterioFormScreen extends ConsumerStatefulWidget {
  const MinisterioFormScreen({super.key, this.ministerio});

  final MinisterioModel? ministerio;

  @override
  ConsumerState<MinisterioFormScreen> createState() =>
      _MinisterioFormScreenState();
}

class _MinisterioFormScreenState extends ConsumerState<MinisterioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;

  late bool _ativo;
  late String _liderId;
  late String _liderNome;
  bool _salvando = false;

  bool get _editando => widget.ministerio != null;

  @override
  void initState() {
    super.initState();
    final m = widget.ministerio;
    _nomeController = TextEditingController(text: m?.nome ?? '');
    _descricaoController = TextEditingController(text: m?.descricao ?? '');
    _ativo = m?.ativo ?? true;
    _liderId = m?.liderId ?? '';
    _liderNome = m?.liderNome ?? '';
  }

  Future<void> _escolherLider() async {
    final membro = await Navigator.of(context).push<UsuarioModel>(
      MaterialPageRoute(
        builder: (_) => SelecionarMembroScreen(
          selecionadoUid: _liderId.isEmpty ? null : _liderId,
        ),
      ),
    );
    if (membro != null) {
      setState(() {
        _liderId = membro.uid;
        _liderNome = membro.nome;
      });
    }
  }

  void _removerLider() {
    setState(() {
      _liderId = '';
      _liderNome = '';
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _mostrar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final autor = ref.read(usuarioProvider);
    if (autor == null || !autor.isLider) {
      _mostrar('Ação restrita à liderança.');
      return;
    }

    setState(() => _salvando = true);
    final anterior = widget.ministerio;
    final ministerio = MinisterioModel(
      id: anterior?.id ?? '',
      nome: _nomeController.text.trim(),
      descricao: _descricaoController.text.trim(),
      liderId: _liderId,
      liderNome: _liderNome,
      membrosCount: anterior?.membrosCount ?? 0,
      ativo: _ativo,
      criadoEm: anterior?.criadoEm ?? DateTime.now(),
    );

    String mensagem;
    bool ok = false;
    try {
      final repo = ref.read(ministeriosRepositoryProvider);
      if (_editando) {
        await repo.atualizar(ministerio);
        mensagem = 'Ministério atualizado.';
      } else {
        await repo.criar(ministerio);
        mensagem = 'Ministério criado.';
      }
      ok = true;
    } on FirebaseException catch (e) {
      mensagem = e.code == 'permission-denied'
          ? 'Sem permissão. Confirme seu perfil de liderança no servidor.'
          : 'Falha no servidor (${e.code}). Tente novamente.';
    } catch (_) {
      mensagem = 'Sem conexão ou falha temporária. Tente novamente.';
    }

    if (!mounted) return;
    setState(() => _salvando = false);
    _mostrar(mensagem);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          _editando ? 'Editar ministério' : 'Novo ministério',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminFormField(
              label: 'Nome',
              child: TextFormField(
                controller: _nomeController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration:
                    adminInputDecoration('Ex.: Ministério de Louvor'),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Informe um nome (mín. 3 letras).'
                    : null,
              ),
            ),
            AdminFormField(
              label: 'Descrição',
              child: TextFormField(
                controller: _descricaoController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 8,
                decoration: adminInputDecoration(
                    'O que este ministério faz na comunidade…'),
                validator: (v) => (v == null || v.trim().length < 5)
                    ? 'Descreva o ministério.'
                    : null,
              ),
            ),
            AdminFormField(
              label: 'Líder do ministério',
              child: _liderNome.isEmpty
                  ? OutlinedButton.icon(
                      onPressed: _escolherLider,
                      icon: const Icon(Icons.person_add_alt_1_outlined,
                          size: 18),
                      label: const Text('Escolher membro'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _liderNome,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.foreground,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: _escolherLider,
                            child: const Text('Trocar'),
                          ),
                          IconButton(
                            onPressed: _removerLider,
                            icon: const Icon(Icons.close, size: 18),
                            color: AppColors.mutedForeground,
                            tooltip: 'Remover líder',
                          ),
                        ],
                      ),
                    ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              title: const Text('Ativo'),
              subtitle: Text(
                _ativo
                    ? 'Aparece para os membros demonstrarem interesse.'
                    : 'Oculto dos membros.',
                style: const TextStyle(
                    color: AppColors.mutedForeground, fontSize: 13),
              ),
              value: _ativo,
              onChanged: (v) => setState(() => _ativo = v),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label:
                  Text(_editando ? 'Salvar alterações' : 'Criar ministério'),
            ),
          ],
        ),
      ),
    );
  }
}
