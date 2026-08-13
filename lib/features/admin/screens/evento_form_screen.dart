import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/data/usuario_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../eventos/data/evento_model.dart';
import '../../eventos/providers/eventos_providers.dart';
import 'selecionar_membro_screen.dart';

/// Formulário para criar/editar um evento da programação. Passe [evento] para
/// editar; nulo para criar. Escrita restrita à liderança pelas regras.
class EventoFormScreen extends ConsumerStatefulWidget {
  const EventoFormScreen({super.key, this.evento});

  final EventoModel? evento;

  @override
  ConsumerState<EventoFormScreen> createState() => _EventoFormScreenState();
}

class _EventoFormScreenState extends ConsumerState<EventoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _horarioController;
  late final TextEditingController _localController;

  late DateTime _data;
  late TipoEvento _tipo;
  late bool _publico;
  late String _responsavelId;
  late String _responsavelNome;
  bool _salvando = false;

  bool get _editando => widget.evento != null;

  @override
  void initState() {
    super.initState();
    final e = widget.evento;
    _tituloController = TextEditingController(text: e?.titulo ?? '');
    _descricaoController = TextEditingController(text: e?.descricao ?? '');
    _horarioController = TextEditingController(text: e?.horario ?? '');
    _localController = TextEditingController(text: e?.local ?? '');
    _data = e?.data ?? DateTime.now().add(const Duration(days: 1));
    _tipo = e?.tipo ?? TipoEvento.culto;
    _publico = e?.publico ?? true;
    _responsavelId = e?.responsavelId ?? '';
    _responsavelNome = e?.responsavelNome ?? '';
  }

  Future<void> _escolherResponsavel() async {
    final membro = await Navigator.of(context).push<UsuarioModel>(
      MaterialPageRoute(
        builder: (_) => SelecionarMembroScreen(
          selecionadoUid: _responsavelId.isEmpty ? null : _responsavelId,
        ),
      ),
    );
    if (membro != null) {
      setState(() {
        _responsavelId = membro.uid;
        _responsavelNome = membro.nome;
      });
    }
  }

  void _removerResponsavel() {
    setState(() {
      _responsavelId = '';
      _responsavelNome = '';
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _horarioController.dispose();
    _localController.dispose();
    super.dispose();
  }

  String _rotuloTipo(TipoEvento t) {
    switch (t) {
      case TipoEvento.culto:
        return 'Culto';
      case TipoEvento.ministerio:
        return 'Ministério';
      case TipoEvento.eventoEspecial:
        return 'Especial';
    }
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
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (escolhida != null) {
      // Preserva a hora atual do modelo (o horário textual é separado).
      setState(() => _data =
          DateTime(escolhida.year, escolhida.month, escolhida.day, _data.hour));
    }
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
    final anterior = widget.evento;
    final evento = EventoModel(
      id: anterior?.id ?? '',
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim(),
      data: _data,
      horario: _horarioController.text.trim(),
      local: _localController.text.trim(),
      tipo: _tipo,
      imagemUrl: anterior?.imagemUrl,
      publico: _publico,
      criadoPor: anterior?.criadoPor ?? autor.uid,
      confirmadosCount: anterior?.confirmadosCount ?? 0,
      responsavelId: _responsavelId,
      responsavelNome: _responsavelNome,
    );

    String mensagem;
    bool ok = false;
    try {
      final repo = ref.read(eventosRepositoryProvider);
      if (_editando) {
        await repo.atualizar(evento);
        mensagem = 'Evento atualizado.';
      } else {
        await repo.criar(evento);
        mensagem = 'Evento adicionado à programação.';
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
          _editando ? 'Editar evento' : 'Novo evento',
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
            _Campo(
              label: 'Título',
              child: TextFormField(
                controller: _tituloController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: _dec('Ex.: Culto de Domingo'),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Informe um título (mín. 3 letras).'
                    : null,
              ),
            ),
            _Campo(
              label: 'Descrição',
              child: TextFormField(
                controller: _descricaoController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 8,
                decoration: _dec('Detalhes do evento…'),
              ),
            ),
            _Campo(
              label: 'Data',
              child: InkWell(
                onTap: _escolherData,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _dec(''),
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
            Row(
              children: [
                Expanded(
                  child: _Campo(
                    label: 'Horário',
                    child: TextFormField(
                      controller: _horarioController,
                      textInputAction: TextInputAction.next,
                      decoration: _dec('Ex.: 19h'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o horário.'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Campo(
                    label: 'Local',
                    child: TextFormField(
                      controller: _localController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _dec('Ex.: Templo Sede'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o local.'
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            _Campo(
              label: 'Tipo',
              child: Wrap(
                spacing: 8,
                children: TipoEvento.values.map((t) {
                  final sel = _tipo == t;
                  return ChoiceChip(
                    label: Text(_rotuloTipo(t)),
                    selected: sel,
                    onSelected: (_) => setState(() => _tipo = t),
                    selectedColor: AppColors.primarySoft,
                    labelStyle: TextStyle(
                      color: sel ? AppColors.primary : AppColors.foreground,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    ),
                  );
                }).toList(),
              ),
            ),
            _Campo(
              label: 'Responsável (opcional)',
              child: _responsavelNome.isEmpty
                  ? OutlinedButton.icon(
                      onPressed: _escolherResponsavel,
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
                              _responsavelNome,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.foreground,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton(
                            onPressed: _escolherResponsavel,
                            child: const Text('Trocar'),
                          ),
                          IconButton(
                            onPressed: _removerResponsavel,
                            icon: const Icon(Icons.close, size: 18),
                            color: AppColors.mutedForeground,
                            tooltip: 'Remover responsável',
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              title: const Text('Público'),
              subtitle: Text(
                _publico
                    ? 'Visível também para visitantes.'
                    : 'Visível apenas para membros.',
                style: const TextStyle(
                    color: AppColors.mutedForeground, fontSize: 13),
              ),
              value: _publico,
              onChanged: (v) => setState(() => _publico = v),
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
                  Text(_editando ? 'Salvar alterações' : 'Adicionar evento'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderFocus),
        ),
      );
}

class _Campo extends StatelessWidget {
  const _Campo({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
