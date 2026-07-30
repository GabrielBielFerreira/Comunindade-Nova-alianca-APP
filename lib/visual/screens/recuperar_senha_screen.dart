import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../mock_data.dart';
import '../visual_router.dart';
import '../widgets/auth_widgets.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _submitRecovery() {
    FocusScope.of(context).unfocus();

    if (!_isValidEmail(_emailController.text)) {
      _showMessage('Informe um e-mail válido');
      return;
    }

    Navigator.pushNamed(context, VisualRoutes.emailEnviado);
  }

  @override
  Widget build(BuildContext context) {
    final scale = authScaleFor(context, 391);

    return AuthCanvas(
      referenceWidth: 391,
      minHeight: 777 * scale,
      backgroundColor: AuthColors.white,
      child: Column(
        children: [
          AuthHeroHeader(
            height: 287,
            title: RecuperarSenhaMockData.headerTitle,
            subtitle: RecuperarSenhaMockData.subtitle,
            scale: scale,
          ),
          Transform.translate(
            offset: Offset(0, -14 * scale),
            child: _RecoveryCard(
              scale: scale,
              emailController: _emailController,
              onSubmit: _submitRecovery,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({
    required this.scale,
    required this.emailController,
    required this.onSubmit,
  });

  final double scale;
  final TextEditingController emailController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 552 * scale),
      padding: EdgeInsets.all(32 * scale),
      decoration: BoxDecoration(
        color: AuthColors.white,
        borderRadius: BorderRadius.circular(32 * scale),
      ),
      child: Column(
        children: [
          Text(
            RecuperarSenhaMockData.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 24 * scale,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: AuthColors.nearBlack,
            ),
          ),
          SizedBox(height: 15.99 * scale),
          Text(
            RecuperarSenhaMockData.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: AuthColors.muted,
            ),
          ),
          SizedBox(height: 32 * scale),
          AuthInputField(
            label: RecuperarSenhaMockData.emailLabel,
            hint: RecuperarSenhaMockData.emailHint,
            iconAsset: AuthAssets.recuperarEmail,
            scale: scale,
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            radius: 12,
            iconWidth: 20,
            iconHeight: 16,
            leftPadding: 49,
            labelColor: AuthColors.muted,
          ),
          SizedBox(height: 24.01 * scale),
          AuthPrimaryButton(
            text: RecuperarSenhaMockData.submit,
            scale: scale,
            radius: 12,
            onTap: onSubmit,
          ),
          SizedBox(height: 32 * scale),
          GestureDetector(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              VisualRoutes.entraconta,
              (route) => false,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12 * scale,
                  height: 12 * scale,
                  child: AuthAssetImage(
                    AuthAssets.recuperarBack,
                    width: 12 * scale,
                    height: 12 * scale,
                  ),
                ),
                SizedBox(width: 8 * scale),
                Text(
                  RecuperarSenhaMockData.backToLogin,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: AuthColors.primary,
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
