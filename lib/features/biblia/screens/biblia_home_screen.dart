import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/theme/app_colors.dart';
import '../data/bible_book.dart';
import '../providers/bible_providers.dart';
import 'biblia_capitulos_screen.dart';
import 'biblia_favoritos_screen.dart';
import 'biblia_historico_screen.dart';
import 'capitulo_reader_screen.dart';

/// Tela inicial da Bíblia: seleção por Antigo/Novo Testamento, busca por
/// referência, favoritos, histórico e "continuar leitura".
class BibliaHomeScreen extends ConsumerWidget {
  const BibliaHomeScreen({super.key});

  void _abrirLivro(BuildContext context, BibleBook livro) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BibliaCapitulosScreen(livro: livro)),
    );
  }

  Future<void> _buscarReferencia(BuildContext context) async {
    final ref = await showDialog<_ReferenciaResultado>(
      context: context,
      builder: (_) => const _BuscaReferenciaDialog(),
    );
    if (ref == null) return;
    if (!context.mounted) return;
    if (ref.livro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referência não reconhecida.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CapituloReaderScreen(
          livro: ref.livro!,
          capitulo: ref.capitulo.clamp(1, ref.livro!.capitulos),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final antigos =
        kBibliaLivros.where((l) => l.testamento == Testamento.antigo).toList();
    final novos =
        kBibliaLivros.where((l) => l.testamento == Testamento.novo).toList();
    final ultimoLido = ref.watch(ultimoLidoProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
          title: Text(
            'Bíblia',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Buscar referência',
              icon: const Icon(Icons.search),
              onPressed: () => _buscarReferencia(context),
            ),
            IconButton(
              tooltip: 'Favoritos',
              icon: const Icon(Icons.favorite_border),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const BibliaFavoritosScreen())),
            ),
            IconButton(
              tooltip: 'Histórico',
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const BibliaHistoricoScreen())),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.mutedForeground,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Antigo Testamento'),
              Tab(text: 'Novo Testamento'),
            ],
          ),
        ),
        body: Column(
          children: [
            ultimoLido.maybeWhen(
              data: (dados) => dados == null
                  ? const SizedBox.shrink()
                  : _ContinuarLeitura(
                      nome: dados['nome'] as String? ?? '',
                      onTap: () {
                        final livro = livroPorNome(dados['nome'] as String? ?? '');
                        if (livro == null) return;
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CapituloReaderScreen(
                            livro: livro,
                            capitulo: (dados['capitulo'] as num?)?.toInt() ?? 1,
                          ),
                        ));
                      },
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ListaLivros(livros: antigos, onTap: (l) => _abrirLivro(context, l)),
                  _ListaLivros(livros: novos, onTap: (l) => _abrirLivro(context, l)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinuarLeitura extends StatelessWidget {
  const _ContinuarLeitura({required this.nome, required this.onTap});
  final String nome;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      child: ListTile(
        leading: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
        title: Text('Continuar leitura',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        subtitle: Text(nome),
        trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
        onTap: onTap,
      ),
    );
  }
}

class _ListaLivros extends StatelessWidget {
  const _ListaLivros({required this.livros, required this.onTap});
  final List<BibleBook> livros;
  final void Function(BibleBook) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: livros.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, i) {
        final l = livros[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primarySoft,
            child: Text(
              l.abreviacao,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          title: Text(l.nome,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500, color: AppColors.foreground)),
          subtitle: Text('${l.capitulos} capítulos',
              style: const TextStyle(color: AppColors.mutedForeground)),
          trailing:
              const Icon(Icons.chevron_right, color: AppColors.mutedForeground),
          onTap: () => onTap(l),
        );
      },
    );
  }
}

class _ReferenciaResultado {
  const _ReferenciaResultado(this.livro, this.capitulo);
  final BibleBook? livro;
  final int capitulo;
}

/// Diálogo de busca de referência com opção de **ditar por voz** (fala → texto),
/// pensado para quem tem dificuldade de ler/digitar. O microfone é solicitado
/// em runtime; se não estiver disponível, a busca por digitação continua normal.
class _BuscaReferenciaDialog extends StatefulWidget {
  const _BuscaReferenciaDialog();

  @override
  State<_BuscaReferenciaDialog> createState() => _BuscaReferenciaDialogState();
}

class _BuscaReferenciaDialogState extends State<_BuscaReferenciaDialog> {
  final _controller = TextEditingController();
  final _speech = SpeechToText();
  bool _speechDisponivel = false;
  bool _ouvindo = false;
  String? _erroMic;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechDisponivel = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && mounted) {
            setState(() => _ouvindo = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _ouvindo = false);
        },
      );
    } catch (_) {
      _speechDisponivel = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleMic() async {
    if (_ouvindo) {
      await _speech.stop();
      if (mounted) setState(() => _ouvindo = false);
      return;
    }
    if (!_speechDisponivel) {
      await _initSpeech();
    }
    if (!_speechDisponivel) {
      if (mounted) {
        setState(() => _erroMic = 'Microfone/voz indisponível neste aparelho.');
      }
      return;
    }
    setState(() {
      _ouvindo = true;
      _erroMic = null;
    });
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        partialResults: true,
        localeId: 'pt_BR',
      ),
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.collapsed(
            offset: _controller.text.length,
          );
        });
      },
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buscar referência'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Ex.: João 3  ou  Salmos 23',
              suffixIcon: IconButton(
                tooltip: _ouvindo ? 'Parar' : 'Falar a referência',
                icon: Icon(
                  _ouvindo ? Icons.mic : Icons.mic_none_rounded,
                  color: _ouvindo ? AppColors.primary : AppColors.mutedForeground,
                ),
                onPressed: _toggleMic,
              ),
            ),
            onSubmitted: (v) =>
                Navigator.of(context).pop(_parseReferencia(v)),
          ),
          if (_ouvindo)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const Icon(Icons.graphic_eq_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Ouvindo… diga o livro e o capítulo',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )
          else if (_erroMic != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _erroMic!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_parseReferencia(_controller.text)),
          child: const Text('Buscar'),
        ),
      ],
    );
  }
}

/// Interpreta uma referência como "João 3", "1 Coríntios 13", "Salmos 23:1".
_ReferenciaResultado _parseReferencia(String entrada) {
  final texto = entrada.trim();
  if (texto.isEmpty) return const _ReferenciaResultado(null, 1);
  final match = RegExp(r'^(.*?)\s+(\d+)(?::\d+)?\s*$').firstMatch(texto);
  if (match == null) {
    return _ReferenciaResultado(livroPorNome(texto), 1);
  }
  final nomeLivro = match.group(1)!.trim();
  final capitulo = int.tryParse(match.group(2) ?? '1') ?? 1;
  BibleBook? livro = livroPorNome(nomeLivro);
  livro ??= kBibliaLivros.cast<BibleBook?>().firstWhere(
        (l) => l!.nome.toLowerCase().startsWith(nomeLivro.toLowerCase()),
        orElse: () => null,
      );
  return _ReferenciaResultado(livro, capitulo);
}
