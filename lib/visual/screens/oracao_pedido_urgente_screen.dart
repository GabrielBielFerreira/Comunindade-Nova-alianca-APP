import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/providers/auth_controller.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/oracao/providers/oracao_providers.dart';
import '../widgets/leader_bottom_navigation.dart';
import '../widgets/oracao_bottom_navigation.dart';
import '../escala_tela.dart';

class OracaoPedidoUrgenteScreen extends ConsumerStatefulWidget {
  const OracaoPedidoUrgenteScreen({super.key, required this.isLeader});

  final bool isLeader;

  @override
  ConsumerState<OracaoPedidoUrgenteScreen> createState() =>
      _OracaoPedidoUrgenteScreenState();
}

class _OracaoPedidoUrgenteScreenState
    extends ConsumerState<OracaoPedidoUrgenteScreen> {
  static const _designWidth = 390.0;
  static const _background = Color(0xFFFAFAFA);
  static const _header = Color(0xFFFCF9F8);
  static const _primary = Color(0xFF7A0022);
  static const _darkPrimary = Color(0xFF510014);
  static const _title = Color(0xFF1C1B1B);
  static const _body = Color(0xFF584142);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);
  static const _alert = Color(0xFFFCEAE8);
  static const _alertBorder = Color(0xFFDFBFC0);

  final _descriptionController = TextEditingController();

  String _category = 'Outro';
  bool _saving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (_descriptionController.text.trim().isEmpty) {
      _showMessage('Descreva brevemente o pedido');
      return;
    }

    setState(() => _saving = true);
    try {
      // Visitantes recebem uma sessão anônima apenas para satisfazer as Rules.
      // O RootGate continua tratando essa credencial como experiência pública.
      final firebaseUser = ref.read(authStateProvider).valueOrNull;
      final usuario = ref.read(usuarioProvider);
      final uid =
          firebaseUser?.uid ??
          await ref.read(authActionsProvider).garantirUsuario();
      final anonimo = firebaseUser == null || firebaseUser.isAnonymous;
      final nome = usuario?.nome.trim().isNotEmpty == true
          ? usuario!.nome.trim()
          : (firebaseUser?.displayName?.trim().isNotEmpty == true
                ? firebaseUser!.displayName!.trim()
                : 'Visitante');

      await ref
          .read(oracaoRepositoryProvider)
          .criarPedido(
            autorId: uid,
            autorNome: nome,
            texto: _descriptionController.text.trim(),
            // Urgência é sempre reservada. Publicação no mural deve passar
            // pelo fluxo comum e pela decisão explícita de moderação.
            privado: true,
            anonimo: anonimo,
            urgente: true,
            categoria: _category,
          );

      if (!mounted) return;
      _showMessage('Pedido urgente registrado com prioridade.');
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        _showMessage('Não foi possível enviar. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          top: false,
          bottom: false,
          // Tamanho de tela (estável com o teclado aberto) evita reconstruir a
          // árvore a cada quadro da animação do teclado.
          child: Builder(
            builder: (context) {
              final scale = (MediaQuery.sizeOf(context).width / _designWidth)
                  .clamp(escalaMinima, 1.0)
                  .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;
              final navigationHeight = 72 * scale + bottomPadding;

              return Stack(
                children: [
                  Column(
                    children: [
                      _UrgentTopBar(
                        scale: scale,
                        topPadding: topPadding,
                        title: 'Pedido urgente',
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            24 * scale,
                            16 * scale,
                            navigationHeight + 16 * scale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _UrgentAlertCard(scale: scale),
                              SizedBox(height: 32 * scale),
                              _FieldLabel(
                                scale: scale,
                                label: 'O que aconteceu?',
                              ),
                              SizedBox(height: 8 * scale),
                              _CategoryGrid(
                                scale: scale,
                                selected: _category,
                                onSelected: (value) {
                                  setState(() => _category = value);
                                },
                              ),
                              SizedBox(height: 24 * scale),
                              _FieldLabel(
                                scale: scale,
                                label: 'Descreva brevemente',
                              ),
                              SizedBox(height: 8 * scale),
                              _UrgentTextArea(
                                scale: scale,
                                controller: _descriptionController,
                              ),
                              SizedBox(height: 32 * scale),
                              _FieldLabel(
                                scale: scale,
                                label: 'Privacidade do pedido',
                              ),
                              SizedBox(height: 8 * scale),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16 * scale),
                                decoration: BoxDecoration(
                                  color: _soft,
                                  borderRadius: BorderRadius.circular(
                                    10 * scale,
                                  ),
                                ),
                                child: Text(
                                  'Este pedido ficará reservado e será '
                                  'visível somente para a equipe autorizada '
                                  'da igreja selecionada.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14 * scale,
                                    height: 20 / 14,
                                    color: _body,
                                  ),
                                ),
                              ),
                              SizedBox(height: 32 * scale),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.fromLTRB(
                                  16 * scale,
                                  9 * scale,
                                  16 * scale,
                                  16 * scale,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(top: BorderSide(color: _line)),
                                ),
                                child: _UrgentSubmitButton(
                                  scale: scale,
                                  label: _saving
                                      ? 'Enviando...'
                                      : 'Enviar pedido',
                                  onTap: _saving ? null : _submit,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: widget.isLeader
                        ? LeaderBottomNavigation(
                            activeItem: LeaderNavItem.prayer,
                            scale: scale,
                            bottomPadding: bottomPadding,
                          )
                        : OracaoBottomNavigation(
                            scale: scale,
                            bottomPadding: bottomPadding,
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UrgentTopBar extends StatelessWidget {
  const _UrgentTopBar({
    required this.scale,
    required this.topPadding,
    required this.title,
  });

  final double scale;
  final double topPadding;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64 * scale + topPadding,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        color: _OracaoPedidoUrgenteScreenState._header,
        border: Border(
          bottom: BorderSide(color: _OracaoPedidoUrgenteScreenState._line),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56 * scale,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back,
                size: 20 * scale,
                color: _OracaoPedidoUrgenteScreenState._darkPrimary,
              ),
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: Offset(-20 * scale, 0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w700,
                  height: 32 / 24,
                  color: _OracaoPedidoUrgenteScreenState._darkPrimary,
                ),
              ),
            ),
          ),
          SizedBox(width: 40 * scale),
        ],
      ),
    );
  }
}

class _UrgentAlertCard extends StatelessWidget {
  const _UrgentAlertCard({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25 * scale),
      decoration: BoxDecoration(
        color: _OracaoPedidoUrgenteScreenState._alert,
        border: Border.all(color: _OracaoPedidoUrgenteScreenState._alertBorder),
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 1.5,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error,
            size: 24 * scale,
            color: _OracaoPedidoUrgenteScreenState._primary,
          ),
          SizedBox(width: 16 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido registrado com prioridade',
                  style: GoogleFonts.montserrat(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w600,
                    height: 28 / 20,
                    color: _OracaoPedidoUrgenteScreenState._primary,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text.rich(
                  TextSpan(
                    text:
                        'O pedido ficará destacado na fila reservada da igreja. Este canal é para apoio espiritual e ',
                    children: [
                      TextSpan(
                        text:
                            'não substitui serviços de emergência (SAMU, Polícia, etc).',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: _OracaoPedidoUrgenteScreenState._primary,
                        ),
                      ),
                    ],
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                    color: _OracaoPedidoUrgenteScreenState._body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.scale, required this.label});

  final double scale;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
        color: _OracaoPedidoUrgenteScreenState._title,
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.scale,
    required this.selected,
    required this.onSelected,
  });

  final double scale;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      _UrgentCategoryData(Icons.medical_services_outlined, 'Morte de parente'),
      _UrgentCategoryData(Icons.local_hospital_outlined, 'Hospitalização'),
      _UrgentCategoryData(Icons.warning_amber_rounded, 'Acidente'),
      _UrgentCategoryData(Icons.more_horiz, 'Outro'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.92,
      crossAxisSpacing: 16 * scale,
      mainAxisSpacing: 16 * scale,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final item in items)
          _UrgentCategoryCard(
            scale: scale,
            data: item,
            selected: selected == item.label,
            onTap: () => onSelected(item.label),
          ),
      ],
    );
  }
}

class _UrgentCategoryCard extends StatelessWidget {
  const _UrgentCategoryCard({
    required this.scale,
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final _UrgentCategoryData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _OracaoPedidoUrgenteScreenState._soft : Colors.white,
      borderRadius: BorderRadius.circular(8 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8 * scale),
        child: Container(
          padding: EdgeInsets.all(17 * scale),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? _OracaoPedidoUrgenteScreenState._primary
                  : _OracaoPedidoUrgenteScreenState._line,
            ),
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                data.icon,
                size: (data.label == 'Hospitalização' ? 18 : 20) * scale,
                color: _OracaoPedidoUrgenteScreenState._muted,
              ),
              SizedBox(height: 7.5 * scale),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  data.label,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                    color: _OracaoPedidoUrgenteScreenState._title,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UrgentTextArea extends StatelessWidget {
  const _UrgentTextArea({required this.scale, required this.controller});

  final double scale;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: 5,
      maxLines: 5,
      textInputAction: TextInputAction.newline,
      style: GoogleFonts.inter(
        fontSize: 16 * scale,
        fontWeight: FontWeight.w400,
        color: _OracaoPedidoUrgenteScreenState._title,
      ),
      decoration: InputDecoration(
        hintText: 'Conte apenas o essencial...',
        hintStyle: GoogleFonts.inter(
          fontSize: 16 * scale,
          color: _OracaoPedidoUrgenteScreenState._muted,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.all(17 * scale),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10 * scale),
          borderSide: const BorderSide(
            color: _OracaoPedidoUrgenteScreenState._line,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10 * scale),
          borderSide: const BorderSide(
            color: _OracaoPedidoUrgenteScreenState._line,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10 * scale),
          borderSide: const BorderSide(
            color: _OracaoPedidoUrgenteScreenState._primary,
          ),
        ),
      ),
    );
  }
}

class _UrgentSubmitButton extends StatelessWidget {
  const _UrgentSubmitButton({
    required this.scale,
    required this.label,
    required this.onTap,
  });

  final double scale;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56 * scale,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _OracaoPedidoUrgenteScreenState._primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scale),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_rounded, size: 16 * scale),
            SizedBox(width: 8 * scale),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgentCategoryData {
  const _UrgentCategoryData(this.icon, this.label);

  final IconData icon;
  final String label;
}
