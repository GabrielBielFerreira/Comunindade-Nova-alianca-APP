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

class OracaoNovoPedidoScreen extends ConsumerStatefulWidget {
  const OracaoNovoPedidoScreen({super.key, required this.isLeader});

  final bool isLeader;

  @override
  ConsumerState<OracaoNovoPedidoScreen> createState() =>
      _OracaoNovoPedidoScreenState();
}

class _OracaoNovoPedidoScreenState
    extends ConsumerState<OracaoNovoPedidoScreen> {
  static const _designWidth = 390.0;
  static const _background = Color(0xFFFAFAFA);
  static const _header = Color(0xFFFCF9F8);
  static const _primary = Color(0xFF7A0022);
  static const _darkPrimary = Color(0xFF510014);
  static const _title = Color(0xFF1C1B1B);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _category;
  bool _publishToMural = false;
  bool _saving = false;
  bool _nomePreenchido = false;

  @override
  void dispose() {
    _nameController.dispose();
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
    if (_nameController.text.trim().isEmpty) {
      _showMessage('Informe seu nome');
      return;
    }
    if (_category == null) {
      _showMessage('Selecione o motivo da oração');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showMessage('Descreva o seu pedido');
      return;
    }

    setState(() => _saving = true);
    try {
      // Aberto a visitantes: se não houver sessão, cria uma sessão anônima
      // (requer "Autenticação anônima" habilitada no Firebase). O pedido vai
      // para moderação como qualquer outro.
      final usuario = ref.read(usuarioProvider);
      final uid =
          usuario?.uid ?? await ref.read(authActionsProvider).garantirUsuario();

      await ref
          .read(oracaoRepositoryProvider)
          .criarPedido(
            autorId: uid,
            autorNome: _nameController.text.trim(),
            texto: _descriptionController.text.trim(),
            // "Publicar no mural" => público; caso contrário, privado.
            privado: !_publishToMural,
            categoria: _category,
          );
      if (!mounted) return;
      _showMessage('Pedido enviado com fé!');
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
    // Preenche o nome com o do usuário logado na primeira montagem.
    if (!_nomePreenchido) {
      final nome = ref.read(usuarioProvider)?.nome;
      if (nome != null && nome.isNotEmpty) _nameController.text = nome;
      _nomePreenchido = true;
    }
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
                      _TaskTopBar(
                        scale: scale,
                        topPadding: topPadding,
                        title: 'Mural de orações',
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
                              Text(
                                'Novo pedido de oração',
                                style: GoogleFonts.montserrat(
                                  fontSize: 24 * scale,
                                  fontWeight: FontWeight.w700,
                                  height: 32 / 24,
                                  color: _title,
                                ),
                              ),
                              SizedBox(height: 24 * scale),
                              Text(
                                'Compartilhe apenas o que se sentir\n'
                                'confortável em contar. Seu pedido será tratado\n'
                                'com cuidado pela liderança e pela equipe de\n'
                                'intercessão.',
                                style: GoogleFonts.inter(
                                  fontSize: 16 * scale,
                                  fontWeight: FontWeight.w400,
                                  height: 24 / 16,
                                  color: _muted,
                                ),
                              ),
                              SizedBox(height: 24 * scale),
                              _FieldLabel(scale: scale, label: 'Seu nome'),
                              SizedBox(height: 8 * scale),
                              _TextInput(
                                scale: scale,
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                              ),
                              SizedBox(height: 24 * scale),
                              _FieldLabel(
                                scale: scale,
                                label: 'Motivo da oração',
                              ),
                              SizedBox(height: 8 * scale),
                              _CategoryDropdown(
                                scale: scale,
                                value: _category,
                                onChanged: (value) {
                                  setState(() => _category = value);
                                },
                              ),
                              SizedBox(height: 24 * scale),
                              _FieldLabel(scale: scale, label: 'Descrição'),
                              SizedBox(height: 8 * scale),
                              _TextInput(
                                scale: scale,
                                controller: _descriptionController,
                                hint: 'Descreva o seu pedido',
                                minLines: 6,
                                maxLines: 6,
                                textInputAction: TextInputAction.newline,
                              ),
                              SizedBox(height: 24 * scale),
                              _YesNoGroup(
                                scale: scale,
                                question: 'Publicar no mural de oração?',
                                value: _publishToMural,
                                onChanged: (value) {
                                  setState(() => _publishToMural = value);
                                },
                              ),
                              SizedBox(height: 8 * scale),
                              Text(
                                'Se escolher “Sim”, seu pedido poderá aparecer para a\n'
                                'comunidade orar junto. Se escolher “Não”, ele ficará visível\n'
                                'apenas para você e a equipe de gestão',
                                style: GoogleFonts.inter(
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w400,
                                  height: 16 / 12,
                                  color: _muted,
                                ),
                              ),
                              SizedBox(height: 24 * scale),
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
                                child: _SubmitButton(
                                  scale: scale,
                                  label: 'Enviar pedido',
                                  onTap: _submit,
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

class _TaskTopBar extends StatelessWidget {
  const _TaskTopBar({
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
        color: _OracaoNovoPedidoScreenState._header,
        border: Border(
          bottom: BorderSide(color: _OracaoNovoPedidoScreenState._line),
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
                color: _OracaoNovoPedidoScreenState._darkPrimary,
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
                  color: _OracaoNovoPedidoScreenState._darkPrimary,
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
        color: _OracaoNovoPedidoScreenState._title,
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.scale,
    required this.controller,
    this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.textInputAction,
  });

  final double scale;
  final TextEditingController controller;
  final String? hint;
  final int minLines;
  final int maxLines;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular((minLines == 1 ? 8 : 10) * scale);

    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      style: GoogleFonts.inter(
        fontSize: 16 * scale,
        fontWeight: FontWeight.w400,
        color: _OracaoNovoPedidoScreenState._title,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 16 * scale,
          color: _OracaoNovoPedidoScreenState._muted,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 17 * scale,
          vertical: minLines == 1 ? 15 * scale : 17 * scale,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: _OracaoNovoPedidoScreenState._line,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: _OracaoNovoPedidoScreenState._line,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: _OracaoNovoPedidoScreenState._primary,
          ),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.scale,
    required this.value,
    required this.onChanged,
  });

  final double scale;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down,
        size: 24 * scale,
        color: _OracaoNovoPedidoScreenState._muted,
      ),
      items: const ['Família', 'Saúde', 'Trabalho', 'Gratidão', 'Outro']
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: 16 * scale,
        color: _OracaoNovoPedidoScreenState._title,
      ),
      decoration: InputDecoration(
        hintText: 'Selecione uma categoria',
        hintStyle: GoogleFonts.inter(
          fontSize: 16 * scale,
          color: _OracaoNovoPedidoScreenState._title,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 17 * scale,
          vertical: 13 * scale,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8 * scale),
          borderSide: const BorderSide(
            color: _OracaoNovoPedidoScreenState._line,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8 * scale),
          borderSide: const BorderSide(
            color: _OracaoNovoPedidoScreenState._line,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8 * scale),
          borderSide: const BorderSide(
            color: _OracaoNovoPedidoScreenState._primary,
          ),
        ),
      ),
    );
  }
}

class _YesNoGroup extends StatelessWidget {
  const _YesNoGroup({
    required this.scale,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final double scale;
  final String question;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(scale: scale, label: question),
        SizedBox(height: 8 * scale),
        Row(
          children: [
            _RadioOption(
              scale: scale,
              label: 'Sim',
              selected: value,
              onTap: () => onChanged(true),
            ),
            SizedBox(width: 15 * scale),
            _RadioOption(
              scale: scale,
              label: 'Não',
              selected: !value,
              onTap: () => onChanged(false),
            ),
          ],
        ),
      ],
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.scale,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double scale;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: (selected ? 22 : 20) * scale,
            height: (selected ? 22 : 20) * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? _OracaoNovoPedidoScreenState._primary
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? _OracaoNovoPedidoScreenState._primary
                    : _OracaoNovoPedidoScreenState._line,
              ),
            ),
            child: selected
                ? Container(
                    width: 8 * scale,
                    height: 8 * scale,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 8 * scale),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w400,
              height: 24 / 16,
              color: _OracaoNovoPedidoScreenState._title,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.scale,
    required this.label,
    required this.onTap,
  });

  final double scale;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56 * scale,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _OracaoNovoPedidoScreenState._primary,
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
