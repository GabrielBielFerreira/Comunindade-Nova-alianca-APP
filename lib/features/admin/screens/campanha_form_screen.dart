import '../../igrejas/providers/igreja_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../../campanhas/data/campanha_model.dart';
import '../../campanhas/providers/campanhas_providers.dart';
import '../widgets/admin_form_widgets.dart';

/// Formulário para criar/editar uma campanha (arrecadação). Passe [campanha]
/// para editar; nulo para criar. Escrita restrita à liderança pelas regras.
///
/// O valor arrecadado é um cache mantido pelo servidor (pagamentos): aqui ele
/// NUNCA é editado — apenas preservado ao salvar.
class CampanhaFormScreen extends ConsumerStatefulWidget {
  const CampanhaFormScreen({super.key, this.campanha});

  final CampanhaModel? campanha;

  @override
  ConsumerState<CampanhaFormScreen> createState() => _CampanhaFormScreenState();
}

class _CampanhaFormScreenState extends ConsumerState<CampanhaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _metaController;

  late StatusCampanha _status;
  late DateTime _dataInicio;
  DateTime? _dataFim;
  bool _salvando = false;

  bool get _editando => widget.campanha != null;

  @override
  void initState() {
    super.initState();
    final c = widget.campanha;
    _tituloController = TextEditingController(text: c?.titulo ?? '');
    _descricaoController = TextEditingController(text: c?.descricao ?? '');
    // Meta em reais no campo (o modelo guarda centavos).
    _metaController = TextEditingController(
      text: c != null ? c.metaReais.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
    _status = c?.status ?? StatusCampanha.ativa;
    _dataInicio = c?.dataInicio ?? DateTime.now();
    _dataFim = c?.dataFim;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _metaController.dispose();
    super.dispose();
  }

  void _mostrar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Converte o texto "1.234,56" / "1234,56" / "1234" em centavos (int).
  int? _metaEmCentavos(String bruto) {
    final limpo = bruto.trim().replaceAll('.', '').replaceAll(',', '.');
    final valor = double.tryParse(limpo);
    if (valor == null || valor <= 0) return null;
    return (valor * 100).round();
  }

  Future<void> _escolherData({required bool inicio}) async {
    final base = inicio ? _dataInicio : (_dataFim ?? _dataInicio);
    final escolhida = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (escolhida == null) return;
    setState(() {
      if (inicio) {
        _dataInicio = escolhida;
      } else {
        _dataFim = escolhida;
      }
    });
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final centavos = _metaEmCentavos(_metaController.text);
    if (centavos == null) {
      _mostrar('Informe uma meta válida (ex.: 5.000,00).');
      return;
    }

    final autor = ref.read(usuarioProvider);
    // Autorizacao vem do VINCULO com a unidade em foco, nao do perfil global:
    // liderar uma igreja nao autoriza escrever em outra. As Rules repetem
    // esta checagem no servidor.
    if (autor == null || !ref.read(podeGerenciarConteudoProvider)) {
      _mostrar('Você não tem permissão para editar o conteúdo desta igreja.');
      return;
    }

    setState(() => _salvando = true);
    final anterior = widget.campanha;
    final campanha = CampanhaModel(
      id: anterior?.id ?? '',
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim(),
      metaValor: centavos,
      // Preserva o arrecadado (cache do servidor); nunca reseta em edição.
      valorArrecadado: anterior?.valorArrecadado ?? 0,
      status: _status,
      dataInicio: _dataInicio,
      dataFim: _dataFim,
      imagemUrl: anterior?.imagemUrl,
      criadoPor: anterior?.criadoPor ?? autor.uid,
    );

    String mensagem;
    bool ok = false;
    try {
      final repo = ref.read(campanhasRepositoryProvider);
      if (_editando) {
        await repo.atualizar(campanha);
        mensagem = 'Campanha atualizada.';
      } else {
        await repo.criar(campanha);
        mensagem = 'Campanha criada.';
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
          _editando ? 'Editar campanha' : 'Nova campanha',
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
                decoration:
                    adminInputDecoration('Ex.: Reforma do templo'),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Informe um título (mín. 3 letras).'
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
                decoration:
                    adminInputDecoration('Explique o objetivo da campanha…'),
              ),
            ),
            AdminFormField(
              label: 'Meta (R\$)',
              child: TextFormField(
                controller: _metaController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: adminInputDecoration('Ex.: 5.000,00'),
                validator: (v) => _metaEmCentavos(v ?? '') == null
                    ? 'Informe uma meta válida.'
                    : null,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AdminFormField(
                    label: 'Início',
                    child: _CampoData(
                      texto: Formatters.data(_dataInicio),
                      onTap: () => _escolherData(inicio: true),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminFormField(
                    label: 'Fim (opcional)',
                    child: _CampoData(
                      texto: _dataFim != null
                          ? Formatters.data(_dataFim!)
                          : 'Sem prazo',
                      onTap: () => _escolherData(inicio: false),
                      onLimpar: _dataFim != null
                          ? () => setState(() => _dataFim = null)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            AdminFormField(
              label: 'Status',
              child: SegmentedButton<StatusCampanha>(
                segments: const [
                  ButtonSegment(
                    value: StatusCampanha.ativa,
                    label: Text('Ativa'),
                    icon: Icon(Icons.play_circle_outline),
                  ),
                  ButtonSegment(
                    value: StatusCampanha.encerrada,
                    label: Text('Encerrada'),
                    icon: Icon(Icons.stop_circle_outlined),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
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
              label: Text(_editando ? 'Salvar alterações' : 'Criar campanha'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de data reutilizável (abre o date picker; opcionalmente limpável).
class _CampoData extends StatelessWidget {
  const _CampoData({required this.texto, required this.onTap, this.onLimpar});

  final String texto;
  final VoidCallback onTap;
  final VoidCallback? onLimpar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: adminInputDecoration(''),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                texto,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.foreground),
              ),
            ),
            if (onLimpar != null)
              GestureDetector(
                onTap: onLimpar,
                child: const Icon(Icons.close,
                    size: 18, color: AppColors.mutedForeground),
              ),
          ],
        ),
      ),
    );
  }
}
