import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_alianca_core/nova_alianca_core.dart';

import '../../features/igrejas/providers/igreja_providers.dart';
import '../widgets/internal_header.dart';
import '../escala_tela.dart';

/// "Ajuda" — tela interna (push) acessível pelo menu "Mais".
///
/// Perguntas frequentes honestas sobre os recursos reais do app e formas de
/// contato reais (Instagram e e-mail da igreja). Nada aqui é simulado.
class AjudaScreen extends ConsumerWidget {
  const AjudaScreen({super.key});

  static const _designWidth = 394.0;
  static const _background = Color(0xFFFAFAFA);
  static const _primary = Color(0xFF7A0022);
  static const _title = Color(0xFF1A1A1A);
  static const _body = Color(0xFF584142);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _soft = Color(0xFFF5E6EC);

  static const List<(String, String)> _faq = [
    (
      'Como enviar um pedido de oração?',
      'Abra o Mural de Oração e toque em "Novo pedido". Seu pedido aparece '
          'imediatamente em "Meus Pedidos". Para ficar visível a toda a '
          'comunidade, ele passa por aprovação da liderança.',
    ),
    (
      'Como atualizar meus dados?',
      'Acesse Perfil → Dados pessoais para revisar nome, telefone e demais '
          'informações do seu cadastro.',
    ),
    (
      'Como funcionam as contribuições?',
      'Na tela Contribuir você faz sua oferta via PIX usando a chave da '
          'igreja (copia-e-cola ou QR Code). A confirmação é feita pela '
          'tesouraria — o app não confirma pagamentos automaticamente.',
    ),
    (
      'Meu cadastro está "aguardando aprovação". E agora?',
      'Novos cadastros são revisados pela liderança. Assim que aprovado, '
          'você recebe uma notificação e o acesso completo é liberado.',
    ),
    (
      'Não estou recebendo notificações.',
      'Verifique se as permissões de notificação estão ativas nas '
          'configurações do seu celular e no menu Configurações do app.',
    ),
  ];

  Future<void> _abrir(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final igreja = ref.watch(igrejaAtualDadosProvider).valueOrNull;
    final mapaUrl = igreja?.mapaUrl;
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
                  .clamp(escalaMinima, 1.0)
                  .toDouble();
              final topPadding = MediaQuery.paddingOf(context).top;
              final bottomPadding = MediaQuery.paddingOf(context).bottom;

              return Column(
                children: [
                  InternalHeader(
                    title: 'Ajuda',
                    scale: scale,
                    topPadding: topPadding,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16 * scale,
                        20 * scale,
                        16 * scale,
                        bottomPadding + 24 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle('Perguntas frequentes', scale: scale),
                          SizedBox(height: 12 * scale),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: _line),
                              borderRadius: BorderRadius.circular(16 * scale),
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < _faq.length; i++) ...[
                                  _FaqTile(
                                    scale: scale,
                                    pergunta: _faq[i].$1,
                                    resposta: _faq[i].$2,
                                  ),
                                  if (i != _faq.length - 1)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: _line,
                                      indent: 16 * scale,
                                      endIndent: 16 * scale,
                                    ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: 28 * scale),
                          _SectionTitle('Fale com a gente', scale: scale),
                          SizedBox(height: 12 * scale),
                          // Contatos da UNIDADE EM FOCO. Cada item só aparece
                          // quando a igreja tem aquele dado cadastrado — nunca
                          // cai no contato de Olinda como padrão.
                          if (igreja?.instagram != null) ...[
                            _ContatoTile(
                              scale: scale,
                              icon: Icons.camera_alt_outlined,
                              title: 'Instagram',
                              subtitle: igreja!.instagram!,
                              onTap: () => _abrir(
                                'https://instagram.com/'
                                '${igreja.instagram!.replaceAll('@', '')}',
                              ),
                            ),
                            SizedBox(height: 10 * scale),
                          ],
                          if (igreja?.telefone != null) ...[
                            _ContatoTile(
                              scale: scale,
                              icon: Icons.phone_outlined,
                              title: 'Telefone',
                              subtitle: igreja!.telefone!,
                              onTap: () => _abrir('tel:${igreja.telefone}'),
                            ),
                            SizedBox(height: 10 * scale),
                          ],
                          if (mapaUrl != null) ...[
                            _ContatoTile(
                              scale: scale,
                              icon: Icons.location_on_outlined,
                              title: 'Endereço',
                              subtitle: igreja!.endereco!,
                              onTap: () => _abrir(mapaUrl),
                            ),
                            SizedBox(height: 10 * scale),
                          ],
                          if (igreja?.instagram == null &&
                              igreja?.telefone == null &&
                              mapaUrl == null)
                            Text(
                              'Esta igreja ainda não cadastrou canais de '
                              'contato no aplicativo.',
                              style: GoogleFonts.inter(
                                fontSize: 13 * scale,
                                color: const Color(0xFF6B7280),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.montserrat(
        fontSize: 16 * scale,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4 * scale,
        color: AjudaScreen._title,
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.scale,
    required this.pergunta,
    required this.resposta,
  });

  final double scale;
  final String pergunta;
  final String resposta;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 2 * scale),
        childrenPadding: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 14 * scale),
        iconColor: AjudaScreen._primary,
        collapsedIconColor: AjudaScreen._muted,
        title: Text(
          pergunta,
          style: GoogleFonts.montserrat(
            fontSize: 15 * scale,
            fontWeight: FontWeight.w600,
            height: 20 / 15,
            color: AjudaScreen._title,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              resposta,
              style: GoogleFonts.inter(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w400,
                height: 21 / 14,
                color: AjudaScreen._body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContatoTile extends StatelessWidget {
  const _ContatoTile({
    required this.scale,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(16 * scale),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(14 * scale),
          decoration: BoxDecoration(
            border: Border.all(color: AjudaScreen._line),
            borderRadius: BorderRadius.circular(16 * scale),
          ),
          child: Row(
            children: [
              Container(
                width: 44 * scale,
                height: 44 * scale,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AjudaScreen._soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22 * scale, color: AjudaScreen._primary),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15 * scale,
                        fontWeight: FontWeight.w600,
                        height: 20 / 15,
                        color: AjudaScreen._title,
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w400,
                        height: 19 / 13,
                        color: AjudaScreen._muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 22 * scale, color: AjudaScreen._muted),
            ],
          ),
        ),
      ),
    );
  }
}
