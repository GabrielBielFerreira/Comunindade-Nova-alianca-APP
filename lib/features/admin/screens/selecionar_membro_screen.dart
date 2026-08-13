import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/data/usuario_model.dart';
import '../providers/membros_providers.dart';

/// Seletor de membro (líder de ministério, etc.). Abra com Navigator.push e
/// aguarde o retorno: devolve o [UsuarioModel] escolhido, ou null se cancelado.
///
/// Só a liderança consegue listar todos os membros (regras do Firestore).
class SelecionarMembroScreen extends ConsumerStatefulWidget {
  const SelecionarMembroScreen({super.key, this.selecionadoUid});

  /// Uid já selecionado (marca com um check na lista), se houver.
  final String? selecionadoUid;

  @override
  ConsumerState<SelecionarMembroScreen> createState() =>
      _SelecionarMembroScreenState();
}

class _SelecionarMembroScreenState
    extends ConsumerState<SelecionarMembroScreen> {
  final _buscaController = TextEditingController();
  String _busca = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  List<UsuarioModel> _filtrar(List<UsuarioModel> todos) {
    final q = _busca.trim().toLowerCase();
    if (q.isEmpty) return todos;
    return todos
        .where((u) =>
            u.nome.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(membrosAprovadosProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Selecionar membro',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _buscaController,
              onChanged: (v) => setState(() => _busca = v),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou e-mail…',
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderFocus),
                ),
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Não foi possível carregar os membros. Verifique sua '
                    'conexão e seu perfil de liderança.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mutedForeground),
                  ),
                ),
              ),
              data: (todos) {
                final lista = _filtrar(todos);
                if (lista.isEmpty) {
                  return Center(
                    child: Text(
                      todos.isEmpty
                          ? 'Nenhum membro aprovado ainda.'
                          : 'Nenhum membro encontrado.',
                      style:
                          const TextStyle(color: AppColors.mutedForeground),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _MembroTile(
                    membro: lista[i],
                    selecionado: lista[i].uid == widget.selecionadoUid,
                    onTap: () => Navigator.of(context).pop(lista[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MembroTile extends StatelessWidget {
  const _MembroTile({
    required this.membro,
    required this.selecionado,
    required this.onTap,
  });

  final UsuarioModel membro;
  final bool selecionado;
  final VoidCallback onTap;

  String _rotuloPerfil(PerfilUsuario p) {
    switch (p) {
      case PerfilUsuario.pastor:
        return 'Pastor';
      case PerfilUsuario.diacono:
        return 'Diácono';
      case PerfilUsuario.lider:
        return 'Líder';
      case PerfilUsuario.membro:
        return 'Membro';
      case PerfilUsuario.visitante:
        return 'Visitante';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selecionado ? AppColors.primary : AppColors.border,
              width: selecionado ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _Avatar(membro: membro),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membro.nome.isEmpty ? '(sem nome)' : membro.nome,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      membro.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.mutedForeground, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (membro.isLider)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _rotuloPerfil(membro.perfil),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              if (selecionado) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.membro});

  final UsuarioModel membro;

  @override
  Widget build(BuildContext context) {
    final url = membro.fotoUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          placeholder: (_, _) => _iniciais(),
          errorWidget: (_, _, _) => _iniciais(),
        ),
      );
    }
    return _iniciais();
  }

  Widget _iniciais() {
    final n = membro.nome.trim();
    final letra = n.isEmpty ? '?' : n[0].toUpperCase();
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        letra,
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          fontSize: 18,
        ),
      ),
    );
  }
}
