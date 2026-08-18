import '../../igrejas/providers/igreja_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../avisos/data/aviso_model.dart';
import '../../avisos/providers/avisos_providers.dart';

/// Formulário para publicar um novo aviso ou editar um existente.
///
/// Passe [aviso] para editar; deixe nulo para criar. A escrita é validada pelas
/// regras do Firestore (apenas liderança). A UI só é aberta a partir da Gestão,
/// então aqui apenas reforçamos o perfil e traduzimos falhas.
class AvisoFormScreen extends ConsumerStatefulWidget {
  const AvisoFormScreen({super.key, this.aviso});

  final AvisoModel? aviso;

  @override
  ConsumerState<AvisoFormScreen> createState() => _AvisoFormScreenState();
}

class _AvisoFormScreenState extends ConsumerState<AvisoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _conteudoController;

  late PrioridadeAviso _prioridade;
  late SegmentoAviso _segmento;
  late bool _ativo;
  bool _salvando = false;

  bool get _editando => widget.aviso != null;

  // Segmentos oferecidos no formulário. "ministério" exige um seletor dedicado
  // (id do ministério) e fica para uma etapa futura — se um aviso já vier com
  // esse segmento, ele é preservado no salvamento.
  static const _segmentosForm = [
    SegmentoAviso.todos,
    SegmentoAviso.jovens,
    SegmentoAviso.lideres,
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.aviso;
    _tituloController = TextEditingController(text: a?.titulo ?? '');
    _conteudoController = TextEditingController(text: a?.conteudo ?? '');
    _prioridade = a?.prioridade ?? PrioridadeAviso.normal;
    _segmento = a?.segmento ?? SegmentoAviso.todos;
    _ativo = a?.ativo ?? true;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _conteudoController.dispose();
    super.dispose();
  }

  String _rotuloSegmento(SegmentoAviso s) {
    switch (s) {
      case SegmentoAviso.todos:
        return 'Todos';
      case SegmentoAviso.jovens:
        return 'Jovens';
      case SegmentoAviso.lideres:
        return 'Líderes';
      case SegmentoAviso.ministerio:
        return 'Ministério';
    }
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
    // Autorizacao vem do VINCULO com a unidade em foco, nao do perfil global:
    // liderar uma igreja nao autoriza escrever em outra. As Rules repetem
    // esta checagem no servidor.
    if (autor == null || !ref.read(podeGerenciarConteudoProvider)) {
      _mostrar('Você não tem permissão para editar o conteúdo desta igreja.');
      return;
    }

    setState(() => _salvando = true);
    final anterior = widget.aviso;
    final aviso = AvisoModel(
      // Em edição preservamos id/autor/data originais; em criação geramos.
      id: anterior?.id ?? '',
      titulo: _tituloController.text.trim(),
      conteudo: _conteudoController.text.trim(),
      prioridade: _prioridade,
      segmento: _segmento,
      segmentoId: anterior?.segmentoId,
      imagemUrl: anterior?.imagemUrl,
      autorId: anterior?.autorId ?? autor.uid,
      publicadoEm: anterior?.publicadoEm ?? DateTime.now(),
      ativo: _ativo,
    );

    String mensagem;
    bool ok = false;
    try {
      final repo = ref.read(avisosRepositoryProvider);
      if (_editando) {
        await repo.atualizar(aviso);
        mensagem = 'Aviso atualizado.';
      } else {
        await repo.criar(aviso);
        mensagem = _ativo ? 'Aviso publicado.' : 'Aviso salvo como rascunho.';
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
          _editando ? 'Editar aviso' : 'Novo aviso',
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
                decoration: _dec('Ex.: Culto de celebração neste domingo'),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Informe um título (mín. 3 letras).'
                    : null,
              ),
            ),
            _Campo(
              label: 'Mensagem',
              child: TextFormField(
                controller: _conteudoController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 4,
                maxLines: 10,
                decoration: _dec('Escreva o conteúdo do aviso…'),
                validator: (v) => (v == null || v.trim().length < 5)
                    ? 'Escreva a mensagem do aviso.'
                    : null,
              ),
            ),
            _Campo(
              label: 'Prioridade',
              child: SegmentedButton<PrioridadeAviso>(
                segments: const [
                  ButtonSegment(
                    value: PrioridadeAviso.normal,
                    label: Text('Normal'),
                    icon: Icon(Icons.notifications_none),
                  ),
                  ButtonSegment(
                    value: PrioridadeAviso.urgente,
                    label: Text('Urgente'),
                    icon: Icon(Icons.priority_high),
                  ),
                ],
                selected: {_prioridade},
                onSelectionChanged: (s) =>
                    setState(() => _prioridade = s.first),
              ),
            ),
            _Campo(
              label: 'Para quem',
              child: Wrap(
                spacing: 8,
                children: _segmentosForm.map((s) {
                  final sel = _segmento == s;
                  return ChoiceChip(
                    label: Text(_rotuloSegmento(s)),
                    selected: sel,
                    onSelected: (_) => setState(() => _segmento = s),
                    selectedColor: AppColors.primarySoft,
                    labelStyle: TextStyle(
                      color: sel ? AppColors.primary : AppColors.foreground,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              title: const Text('Publicado'),
              subtitle: Text(
                _ativo
                    ? 'Visível para os membros agora.'
                    : 'Salvo, mas oculto dos membros (rascunho).',
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
              label: Text(_editando ? 'Salvar alterações' : 'Publicar aviso'),
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
