import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../../devocionais/data/devocional_model.dart';
import '../../devocionais/providers/devocionais_providers.dart';
import '../widgets/admin_form_widgets.dart';

/// Formulário para criar/editar um devocional. Passe [devocional] para editar;
/// nulo para criar. Escrita restrita à liderança pelas regras do Firestore.
class DevocionalFormScreen extends ConsumerStatefulWidget {
  const DevocionalFormScreen({super.key, this.devocional});

  final DevocionalModel? devocional;

  @override
  ConsumerState<DevocionalFormScreen> createState() =>
      _DevocionalFormScreenState();
}

class _DevocionalFormScreenState extends ConsumerState<DevocionalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _corpoController;
  late final TextEditingController _autorController;
  late final TextEditingController _referenciaController;

  late DateTime _data;
  late bool _destaque;
  bool _salvando = false;

  bool get _editando => widget.devocional != null;

  @override
  void initState() {
    super.initState();
    final d = widget.devocional;
    _tituloController = TextEditingController(text: d?.titulo ?? '');
    _corpoController = TextEditingController(text: d?.corpo ?? '');
    _autorController = TextEditingController(text: d?.autor ?? '');
    _referenciaController = TextEditingController(text: d?.referencia ?? '');
    _data = d?.data ?? DateTime.now();
    _destaque = d?.destaque ?? false;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _corpoController.dispose();
    _autorController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  void _mostrar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (escolhida != null) setState(() => _data = escolhida);
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
    final anterior = widget.devocional;
    final ref_ = _referenciaController.text.trim();
    final devocional = DevocionalModel(
      id: anterior?.id ?? '',
      titulo: _tituloController.text.trim(),
      corpo: _corpoController.text.trim(),
      autor: _autorController.text.trim(),
      data: _data,
      referencia: ref_.isEmpty ? null : ref_,
      destaque: _destaque,
    );

    String mensagem;
    bool ok = false;
    try {
      final repo = ref.read(devocionaisRepositoryProvider);
      if (_editando) {
        await repo.atualizar(devocional);
        mensagem = 'Devocional atualizado.';
      } else {
        await repo.criar(devocional);
        mensagem = 'Devocional publicado.';
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
          _editando ? 'Editar devocional' : 'Novo devocional',
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
              label: 'Título',
              child: TextFormField(
                controller: _tituloController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: adminInputDecoration('Ex.: Descanse no Pastor'),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Informe um título (mín. 3 letras).'
                    : null,
              ),
            ),
            AdminFormField(
              label: 'Texto',
              child: TextFormField(
                controller: _corpoController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 5,
                maxLines: 14,
                decoration:
                    adminInputDecoration('Escreva a mensagem do devocional…'),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Escreva o texto do devocional.'
                    : null,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AdminFormField(
                    label: 'Autor',
                    child: TextFormField(
                      controller: _autorController,
                      textCapitalization: TextCapitalization.words,
                      decoration: adminInputDecoration('Ex.: Pr. José Victor'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o autor.'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminFormField(
                    label: 'Referência (opcional)',
                    child: TextFormField(
                      controller: _referenciaController,
                      decoration: adminInputDecoration('Ex.: Salmos 23:1'),
                    ),
                  ),
                ),
              ],
            ),
            AdminFormField(
              label: 'Data',
              child: InkWell(
                onTap: _escolherData,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: adminInputDecoration(''),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        Formatters.data(_data),
                        style: const TextStyle(
                            fontSize: 16, color: AppColors.foreground),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              title: const Text('Destaque'),
              subtitle: const Text(
                'Aparece como o devocional principal na Home.',
                style: TextStyle(
                    color: AppColors.mutedForeground, fontSize: 13),
              ),
              value: _destaque,
              onChanged: (v) => setState(() => _destaque = v),
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
              label: Text(
                  _editando ? 'Salvar alterações' : 'Publicar devocional'),
            ),
          ],
        ),
      ),
    );
  }
}
