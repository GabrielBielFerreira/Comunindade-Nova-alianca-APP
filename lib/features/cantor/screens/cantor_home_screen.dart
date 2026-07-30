import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../data/hino.dart';
import '../providers/hymnal_providers.dart';
import 'hino_detalhe_screen.dart';

/// Tela inicial do Cantor Cristão: lista por número, busca por número/título,
/// estados de carregamento, erro e vazio (quando ainda não há conteúdo
/// autorizado).
class CantorHomeScreen extends ConsumerStatefulWidget {
  const CantorHomeScreen({super.key});

  @override
  ConsumerState<CantorHomeScreen> createState() => _CantorHomeScreenState();
}

class _CantorHomeScreenState extends ConsumerState<CantorHomeScreen> {
  final _buscaController = TextEditingController();
  String _busca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  List<Hino> _filtrar(List<Hino> hinos) {
    final q = _busca.trim().toLowerCase();
    if (q.isEmpty) return hinos;
    final numero = int.tryParse(q);
    return hinos.where((h) {
      if (numero != null && h.numero == numero) return true;
      return h.titulo.toLowerCase().contains(q) || '${h.numero}'.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hinosAsync = ref.watch(hinosProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Cantor Cristão',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: hinosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Estado(
          icone: Icons.error_outline,
          titulo: 'Não foi possível carregar',
          texto: e.toString(),
        ),
        data: (hinos) {
          if (hinos.isEmpty) {
            return const _Estado(
              icone: Icons.library_music_outlined,
              titulo: 'Cantor Cristão em preparação',
              texto:
                  'O conteúdo dos hinos ainda não foi disponibilizado. É '
                  'necessário fornecer o arquivo autorizado de hinos '
                  '(assets/hinos/cantor_cristao.json). Fale com a administração '
                  'da igreja. Nenhuma letra é exibida sem autorização.',
            );
          }
          final filtrados = _filtrar(hinos);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _buscaController,
                  onChanged: (v) => setState(() => _busca = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar por número ou título',
                    prefixIcon: const Icon(Icons.search),
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
                  ),
                ),
              ),
              Expanded(
                child: filtrados.isEmpty
                    ? const _Estado(
                        icone: Icons.search_off,
                        titulo: 'Nada encontrado',
                        texto: 'Nenhum hino corresponde à sua busca.',
                      )
                    : ListView.separated(
                        itemCount: filtrados.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, i) {
                          final h = filtrados[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primarySoft,
                              child: Text(
                                '${h.numero}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            title: Text(h.titulo,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500)),
                            trailing: const Icon(Icons.chevron_right,
                                color: AppColors.mutedForeground),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => HinoDetalheScreen(
                                    hinos: hinos, numero: h.numero),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Estado extends StatelessWidget {
  const _Estado({
    required this.icone,
    required this.titulo,
    required this.texto,
  });
  final IconData icone;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: AppColors.mutedForeground),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.mutedForeground, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
