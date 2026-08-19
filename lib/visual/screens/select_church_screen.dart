import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/igrejas/data/igreja_opcao.dart';
import '../../features/igrejas/providers/escolha_igreja_provider.dart';
import '../../features/igrejas/providers/igreja_providers.dart';
import '../mock_data.dart';
import '../widgets/auth_widgets.dart';
import '../escala_tela.dart';

/// Escolha da unidade no onboarding.
///
/// A lista vem de `igrejasAtivasProvider` (Firestore), não de constante: novas
/// unidades cadastradas pelo superadministrador aparecem aqui sem publicar
/// versão nova do aplicativo. Só unidades ATIVAS entram.
///
/// A mesma tela serve a quatro contextos — ver [ModoSelecaoIgreja].

/// Contexto em que a seleção de igreja foi aberta.
///
/// O que muda entre os modos é O QUE SE FAZ com a escolha e PARA ONDE se vai
/// depois. A lista e o visual são idênticos.
enum ModoSelecaoIgreja {
  /// Primeira abertura do aplicativo, sem sessão.
  ///
  /// Define a unidade pública em foco (o visitante passa a ver o conteúdo
  /// dela) e também a pré-seleção do cadastro. O [RootGate] permanece como
  /// rota raiz e reconstrói para "Bem-vindo" quando a preferência muda.
  onboarding,

  /// Aberta a partir do formulário de cadastro.
  ///
  /// Só define a igreja do cadastro e VOLTA para o formulário, preservando o
  /// que a pessoa já digitou. Mandar para o Welcome aqui perderia o
  /// preenchimento.
  cadastro,

  /// Troca de unidade dentro do aplicativo, com sessão ativa.
  ///
  /// Define apenas a unidade visualizada. Não altera `igreja_principal_id`,
  /// vínculo, perfil ou funções.
  troca,
}

class SelectChurchScreen extends ConsumerStatefulWidget {
  const SelectChurchScreen({
    super.key,
    this.modo = ModoSelecaoIgreja.onboarding,
  });

  static const routeName = '/select-church';

  final ModoSelecaoIgreja modo;

  static const _referenceWidth = 390.0;

  static double _scaleFor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final effectiveWidth = math.min(width, _referenceWidth);
    return (effectiveWidth / _referenceWidth)
        .clamp(escalaMinima, 1.0)
        .toDouble();
  }

  @override
  ConsumerState<SelectChurchScreen> createState() => _SelectChurchScreenState();
}

class _SelectChurchScreenState extends ConsumerState<SelectChurchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<IgrejaOpcao> _filtrar(List<IgrejaOpcao> todas) {
    final query = _normalize(_query.trim());
    if (query.isEmpty) return todas;
    return todas
        .where((church) => _normalize(church.buscavel).contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final scale = SelectChurchScreen._scaleFor(context);
    final igrejasAsync = ref.watch(igrejasAtivasProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SelectChurchTopBar(scale: scale),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16 * scale,
                          16 * scale,
                          16 * scale,
                          0,
                        ),
                        child: Column(
                          children: [
                            _SearchBox(
                              scale: scale,
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() => _query = value);
                              },
                            ),
                            SizedBox(height: 24 * scale),
                            igrejasAsync.when(
                              loading: () => Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 32 * scale,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (erro, _) {
                                final mensagem = _mensagemParaErro(erro);
                                return _MensagemLista(
                                  scale: scale,
                                  titulo: mensagem.titulo,
                                  detalhe: mensagem.detalhe,
                                  onTentarNovamente: () =>
                                      ref.invalidate(igrejasAtivasProvider),
                                );
                              },
                              data: (igrejas) {
                                final opcoes = igrejas
                                    .map(IgrejaOpcao.de)
                                    .toList(growable: false);
                                final filtradas = _filtrar(opcoes);

                                if (opcoes.isEmpty) {
                                  return _MensagemLista(
                                    scale: scale,
                                    titulo: 'Nenhuma igreja disponível',
                                    detalhe:
                                        'Ainda não há unidades ativas para '
                                        'cadastro. Procure a liderança da sua '
                                        'igreja.',
                                  );
                                }

                                if (filtradas.isEmpty) {
                                  return _MensagemLista(
                                    scale: scale,
                                    titulo: 'Nenhuma igreja encontrada',
                                    detalhe:
                                        'Nenhuma unidade corresponde a '
                                        '"${_query.trim()}".',
                                  );
                                }

                                return Column(
                                  children: [
                                    for (final church in filtradas) ...[
                                      _ChurchCard(
                                        church: church,
                                        scale: scale,
                                        onTap: () =>
                                            _showChurchDetails(context, church),
                                      ),
                                      SizedBox(height: 16 * scale),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Aplica a escolha conforme o modo.
  ///
  /// Em todos os casos o que é gravado é o [IgrejaId]; o nome nunca vira
  /// chave de escopo.
  Future<void> _confirmar(IgrejaOpcao church) async {
    switch (widget.modo) {
      case ModoSelecaoIgreja.onboarding:
        final rotaDireta =
            ModalRoute.of(context)?.settings.name ==
            SelectChurchScreen.routeName;
        final navigator = Navigator.of(context);
        final escolhaCadastro = ref.read(
          igrejaEscolhidaCadastroProvider.notifier,
        );
        final igrejaVisualizada = ref.read(igrejaVisualizadaProvider.notifier);

        // Fecha o sheet ANTES de alterar o provider observado pelo RootGate.
        // A mudança de estado é síncrona e pode desmontar esta tela enquanto
        // o SharedPreferences ainda está sendo persistido.
        navigator.pop();

        // Persiste primeiro a pré-seleção do cadastro e, por último, muda a
        // unidade pública. Esta última alteração faz o RootGate reconstruir
        // para "Bem-vindo" com as duas preferências já coerentes.
        await escolhaCadastro.definir(church.id);
        await igrejaVisualizada.definir(church.id);

        if (!rotaDireta || !navigator.mounted) return;
        // Compatibilidade com links/rotas antigas: remove a rota própria e
        // revela o RootGate, que já reagiu à preferência persistida. Assim a
        // decisão de entrada continua centralizada no gate.
        navigator.pop();

      case ModoSelecaoIgreja.cadastro:
        // Só a escolha do cadastro. NÃO mexe na unidade visualizada: o
        // formulário está no meio do preenchimento e trocar o escopo agora
        // recarregaria a tela por baixo.
        await ref
            .read(igrejaEscolhidaCadastroProvider.notifier)
            .definir(church.id);

        if (!mounted) return;
        Navigator.of(context).pop(); // fecha o sheet
        if (!mounted) return;
        // Volta ao MESMO CadastroScreen, preservando o que já foi digitado.
        Navigator.of(context).pop(church.id);

      case ModoSelecaoIgreja.troca:
        await ref.read(igrejaVisualizadaProvider.notifier).definir(church.id);

        if (!mounted) return;
        Navigator.of(context).pop();
        if (!mounted) return;
        Navigator.of(context).pop(church.nome);
    }
  }

  void _showChurchDetails(BuildContext context, IgrejaOpcao church) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      isScrollControlled: true,
      useSafeArea: false,
      builder: (_) => _ChurchDetailsSheet(
        church: church,
        onConfirm: () => _confirmar(church),
      ),
    );
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }
}

class _SelectChurchTopBar extends StatelessWidget {
  const _SelectChurchTopBar({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * scale,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 8 * scale,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 48 * scale,
                height: 48 * scale,
                child: Center(
                  child: AuthAssetImage(
                    ChurchAssets.back,
                    width: 16 * scale,
                    height: 16 * scale,
                  ),
                ),
              ),
            ),
          ),
          Text(
            SelectChurchMockData.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              height: 28 / 20,
              color: AuthColors.nearBlack,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.scale,
    required this.controller,
    required this.onChanged,
  });

  final double scale;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AuthColors.border),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Row(
        children: [
          SizedBox(width: 16 * scale),
          AuthAssetImage(
            ChurchAssets.search,
            width: 18 * scale,
            height: 18 * scale,
          ),
          SizedBox(width: 22 * scale),
          Expanded(
            child: TextField(
              key: const Key('select-church-search-field'),
              controller: controller,
              onChanged: onChanged,
              cursorColor: AuthColors.primary,
              textInputAction: TextInputAction.search,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w400,
                height: 24 / 16,
                color: AuthColors.nearBlack,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                hintText: 'Nome ou endereço',
                hintStyle: GoogleFonts.inter(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w400,
                  height: 24 / 16,
                  color: AuthColors.muted,
                ),
              ),
            ),
          ),
          SizedBox(width: 16 * scale),
        ],
      ),
    );
  }
}

class _MensagemErroIgrejas {
  const _MensagemErroIgrejas(this.titulo, this.detalhe);

  final String titulo;
  final String detalhe;
}

_MensagemErroIgrejas _mensagemParaErro(Object erro) {
  if (erro is FirebaseException) {
    switch (erro.code) {
      case 'permission-denied':
        return const _MensagemErroIgrejas(
          'Lista de igrejas temporariamente indisponível',
          'Não foi possível acessar a lista. Tente novamente e, se o problema '
              'continuar, entre em contato com o suporte.',
        );
      case 'unavailable':
        return const _MensagemErroIgrejas(
          'Sem conexão com o serviço',
          'Confirme sua conexão com a internet e tente novamente.',
        );
      case 'failed-precondition':
        return const _MensagemErroIgrejas(
          'Lista de igrejas em atualização',
          'O serviço está sendo preparado. Tente novamente em alguns minutos.',
        );
    }
  }

  return const _MensagemErroIgrejas(
    'Não foi possível carregar as igrejas',
    'Tente novamente. Se o problema continuar, entre em contato com o suporte.',
  );
}

class _ChurchCard extends StatelessWidget {
  const _ChurchCard({
    required this.church,
    required this.scale,
    required this.onTap,
  });

  final IgrejaOpcao church;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8 * scale),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(17 * scale),
          decoration: BoxDecoration(
            border: Border.all(color: AuthColors.border),
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      church.nome,
                      style: GoogleFonts.montserrat(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.w600,
                        height: 28 / 20,
                        color: AuthColors.nearBlack,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      church.endereco,
                      style: GoogleFonts.inter(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w400,
                        height: 22.75 / 14,
                        color: AuthColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16 * scale),
              AuthAssetImage(
                ChurchAssets.chevron,
                width: 7.42 * scale,
                height: 12 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChurchDetailsSheet extends StatelessWidget {
  const _ChurchDetailsSheet({required this.church, required this.onConfirm});

  final IgrejaOpcao church;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final scale = SelectChurchScreen._scaleFor(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final sheetHeight = math.min(
      554 * scale + bottomPadding,
      screenHeight * 0.8,
    );

    return Container(
      width: double.infinity,
      height: sheetHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: Offset(0, 25 * scale),
            blurRadius: 50 * scale,
            spreadRadius: -12 * scale,
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24 * scale,
            24 * scale,
            24 * scale,
            (24 * scale) + bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHeader(scale: scale),
              SizedBox(height: 24 * scale),
              _ChurchInfoRow(church: church, scale: scale),
              SizedBox(height: 24 * scale),
              _ChurchMap(scale: scale),
              SizedBox(height: 24 * scale),
              _SheetPrimaryButton(
                text: SelectChurchMockData.confirmChoice,
                scale: scale,
                onTap: onConfirm,
              ),
              SizedBox(height: 12 * scale),
              _SheetOutlineButton(
                text: SelectChurchMockData.backToList,
                scale: scale,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 33 * scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            SelectChurchMockData.modalTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22 * scale,
              fontWeight: FontWeight.w700,
              height: 33 / 22,
              color: const Color(0xFF454555),
            ),
          ),
          Positioned(
            right: -2 * scale,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(
                width: 36 * scale,
                height: 36 * scale,
                child: Center(
                  child: AuthAssetImage(
                    ChurchAssets.modalClose,
                    width: 28 * scale,
                    height: 28 * scale,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChurchInfoRow extends StatelessWidget {
  const _ChurchInfoRow({required this.church, required this.scale});

  final IgrejaOpcao church;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44 * scale,
          height: 44 * scale,
          decoration: BoxDecoration(
            color: AuthColors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AuthAssetImage(
              ChurchAssets.modalLocation,
              width: 20 * scale,
              height: 20 * scale,
            ),
          ),
        ),
        SizedBox(width: 16 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                church.nome,
                style: GoogleFonts.montserrat(
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.w600,
                  height: 28 / 20,
                  color: AuthColors.nearBlack,
                ),
              ),
              SizedBox(height: 8 * scale),
              Text(
                church.endereco,
                style: GoogleFonts.inter(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w400,
                  height: 22.75 / 16,
                  color: AuthColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChurchMap extends StatelessWidget {
  const _ChurchMap({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16 * scale),
      child: Container(
        height: 180 * scale,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(16 * scale),
        ),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            Image.asset(
              ChurchAssets.map,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            AuthAssetImage(
              ChurchAssets.mapPin,
              width: 40 * scale,
              height: 40 * scale,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetPrimaryButton extends StatelessWidget {
  const _SheetPrimaryButton({
    required this.text,
    required this.scale,
    required this.onTap,
  });

  final String text;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52 * scale,
        decoration: BoxDecoration(
          color: AuthColors.primary,
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 17 * scale,
              fontWeight: FontWeight.w700,
              height: 25.5 / 17,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetOutlineButton extends StatelessWidget {
  const _SheetOutlineButton({
    required this.text,
    required this.scale,
    required this.onTap,
  });

  final String text;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52 * scale,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AuthColors.primary, width: 2 * scale),
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 17 * scale,
              fontWeight: FontWeight.w700,
              height: 25.5 / 17,
              color: AuthColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado honesto da lista: carregando falhou, vazio ou busca sem resultado.
///
/// Nunca substitui a lista por uma unidade fictícia para "não ficar vazio".
class _MensagemLista extends StatelessWidget {
  const _MensagemLista({
    required this.scale,
    required this.titulo,
    required this.detalhe,
    this.onTentarNovamente,
  });

  final double scale;
  final String titulo;
  final String detalhe;
  final VoidCallback? onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32 * scale),
      child: Column(
        children: [
          Icon(
            Icons.church_outlined,
            size: 40 * scale,
            color: AuthColors.primary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 12 * scale),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w600,
              color: AuthColors.title,
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            detalhe,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13 * scale,
              color: AuthColors.muted,
            ),
          ),
          if (onTentarNovamente != null) ...[
            SizedBox(height: 16 * scale),
            TextButton(
              onPressed: onTentarNovamente,
              child: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }
}
