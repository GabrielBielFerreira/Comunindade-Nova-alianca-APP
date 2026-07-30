import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../visual_router.dart';
import '../widgets/internal_header.dart';

/// Tela de Configurações (membro e liderança — idêntica para ambos).
///
/// Tela interna (push), sem bottom navigation. Toggles são dados simulados.
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  static const _designWidth = 394.0;
  static const _background = Color(0xFFFAFAFA);
  static const _primary = Color(0xFF7A0022);
  static const _title = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _danger = Color(0xFFDC2626);

  String _churchLabel = 'Nova Aliança Olinda';

  bool _liveNotifications = true;
  bool _eventNotifications = true;
  bool _communicationNotifications = true;

  Future<void> _openChurchSelection() async {
    final result = await Navigator.pushNamed(
      context,
      VisualRoutes.visualizarOutraIgreja,
    );

    if (result is String && mounted) {
      setState(() => _churchLabel = result);
    }
  }

  void _showFutureMessage(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"$label" será conectado futuramente'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        body: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = (constraints.maxWidth / _designWidth)
                  .clamp(0.86, 1.0)
                  .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;

              return Column(
                children: [
                  InternalHeader(
                    title: 'Configurações',
                    scale: scale,
                    topPadding: topPadding,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.only(bottom: bottomPadding + 24 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20 * scale),
                          _SectionLabel(
                            'Visualizar outra igreja',
                            scale: scale,
                          ),
                          SizedBox(height: 12 * scale),
                          _SurfaceGroup(
                            scale: scale,
                            children: [
                              _ChangeChurchRow(
                                scale: scale,
                                label: _churchLabel,
                                onTap: _openChurchSelection,
                              ),
                            ],
                          ),
                          SizedBox(height: 28 * scale),
                          _SurfaceGroup(
                            scale: scale,
                            children: [
                              _SwitchRow(
                                scale: scale,
                                label: 'Notificações de transmissões ao vivo',
                                value: _liveNotifications,
                                onChanged: (value) =>
                                    setState(() => _liveNotifications = value),
                              ),
                              _Divider(scale: scale),
                              _SwitchRow(
                                scale: scale,
                                label: 'Notificações de eventos',
                                value: _eventNotifications,
                                onChanged: (value) =>
                                    setState(() => _eventNotifications = value),
                              ),
                              _Divider(scale: scale),
                              _SwitchRow(
                                scale: scale,
                                label: 'Notificações de comunicações',
                                value: _communicationNotifications,
                                onChanged: (value) => setState(
                                  () => _communicationNotifications = value,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 28 * scale),
                          _SurfaceGroup(
                            scale: scale,
                            children: [
                              for (final label in const [
                                'Sobre o desenvolvedor',
                                'Política de privacidade',
                                'Termos de serviço',
                                'Compartilhar este aplicativo',
                              ]) ...[
                                _LinkRow(
                                  scale: scale,
                                  label: label,
                                  onTap: () => _showFutureMessage(label),
                                ),
                                if (label != 'Compartilhar este aplicativo')
                                  _Divider(scale: scale),
                              ],
                            ],
                          ),
                          SizedBox(height: 36 * scale),
                          _SurfaceGroup(
                            scale: scale,
                            children: [
                              _LinkRow(
                                scale: scale,
                                label: 'Excluir minha conta',
                                color: _danger,
                                onTap: () =>
                                    _showFutureMessage('Excluir minha conta'),
                              ),
                            ],
                          ),
                          SizedBox(height: 16 * scale),
                          Center(
                            child: Text(
                              'Versão: 1.0.0',
                              style: GoogleFonts.inter(
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.w400,
                                height: 16 / 12,
                                color: _muted,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12 * scale,
          fontWeight: FontWeight.w400,
          height: 16.8 / 12,
          letterSpacing: 0.6 * scale,
          color: _ConfiguracoesScreenState._muted,
        ),
      ),
    );
  }
}

/// Bloco branco com borda superior/inferior, agrupando linhas da lista.
class _SurfaceGroup extends StatelessWidget {
  const _SurfaceGroup({required this.scale, required this.children});

  final double scale;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _ConfiguracoesScreenState._line),
          bottom: BorderSide(color: _ConfiguracoesScreenState._line),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
      child: const Divider(
        height: 1,
        thickness: 1,
        color: _ConfiguracoesScreenState._line,
      ),
    );
  }
}

class _ChangeChurchRow extends StatelessWidget {
  const _ChangeChurchRow({
    required this.scale,
    required this.label,
    required this.onTap,
  });

  final double scale;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 16 * scale,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                  color: _ConfiguracoesScreenState._title,
                ),
              ),
            ),
            SizedBox(width: 12 * scale),
            Text(
              'TROCAR',
              style: GoogleFonts.montserrat(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w700,
                color: _ConfiguracoesScreenState._title,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22 * scale,
              color: _ConfiguracoesScreenState._title,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.scale,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final double scale;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 8 * scale,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w400,
                height: 24 / 16,
                color: _ConfiguracoesScreenState._title,
              ),
            ),
          ),
          SizedBox(width: 12 * scale),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: _ConfiguracoesScreenState._primary,
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.scale,
    required this.label,
    required this.onTap,
    this.color,
  });

  final double scale;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 16 * scale,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w400,
                  height: 24 / 16,
                  color: color ?? _ConfiguracoesScreenState._title,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22 * scale,
              color: color ?? _ConfiguracoesScreenState._muted,
            ),
          ],
        ),
      ),
    );
  }
}
