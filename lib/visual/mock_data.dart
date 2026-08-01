import 'package:flutter/material.dart';

class EntracontaMockData {
  const EntracontaMockData._();

  static const logoAsset = 'assets/images/figma/entraconta_logo.png';
  static const emailIconAsset = 'assets/images/figma/entraconta_email_icon.svg';
  static const lockIconAsset = 'assets/images/figma/entraconta_lock_icon.svg';
  static const eyeOffIconAsset =
      'assets/images/figma/entraconta_eye_off_icon.svg';

  static const welcome = 'Bem vindo';
  static const subtitle = 'Junte-se à nossa comunidade';
  static const title = 'Entre com sua conta';
  static const emailLabel = 'E-mail';
  static const emailHint = 'insira seu email';
  static const passwordLabel = 'Senha';
  static const passwordHint = '••••••••';
  static const submit = 'ENTRAR';
  static const forgotPassword = 'Esqueceu a senha ?';
  static const noAccount = 'Não possui uma conta?';
  static const createAccount = 'Criar conta';
}

class AuthAssets {
  const AuthAssets._();

  static const logo = EntracontaMockData.logoAsset;
  static const cadastroUser = 'assets/images/figma/auth/cadastro_user_icon.svg';
  static const cadastroEmail =
      'assets/images/figma/auth/cadastro_email_icon.svg';
  static const cadastroPhone =
      'assets/images/figma/auth/cadastro_phone_icon.svg';
  static const cadastroLock = 'assets/images/figma/auth/cadastro_lock_icon.svg';
  static const cadastroEye = 'assets/images/figma/auth/cadastro_eye_icon.svg';
  static const cadastroArrow =
      'assets/images/figma/auth/cadastro_arrow_icon.svg';
  static const recuperarEmail =
      'assets/images/figma/auth/recuperar_email_icon.svg';
  static const recuperarBack =
      'assets/images/figma/auth/recuperar_back_icon.svg';
  static const emailEnviado = 'assets/images/figma/auth/email_enviado_icon.svg';
}

class ChurchAssets {
  const ChurchAssets._();

  static const back = 'assets/images/figma/church/select_back.svg';
  static const search = 'assets/images/figma/church/select_search.svg';
  static const location = 'assets/images/figma/church/select_location.svg';
  static const chevron = 'assets/images/figma/church/select_chevron.svg';
  static const map = 'assets/images/figma/church/church_map.png';
  static const modalLocation =
      'assets/images/figma/church/church_modal_location.svg';
  static const modalClose = 'assets/images/figma/church/church_modal_close.svg';
  static const mapPin = 'assets/images/figma/church/church_map_pin.svg';
}

class WelcomeAssets {
  const WelcomeAssets._();

  static const logo = 'assets/images/figma/welcome/welcome_logo.png';
  static const check = 'assets/images/figma/welcome/welcome_check.svg';
}

class WelcomeAccessMockData {
  const WelcomeAccessMockData._();

  static const title = 'Bem-vindo(a) à\nComunidade Nova\nAliança';
  static const consentPrefix = 'Estou ciente e concordo com a ';
  static const privacyPolicy = 'política de privacidade';
  static const consentMiddle = ' e ';
  static const terms = 'termos de serviços';
  static const login = 'Login';
  static const continueWithoutLogin = 'Continuar sem login';
  static const acceptTermsMessage = 'Aceite os termos para continuar';
  static const visitorTitle = 'Visitante';
  static const visitorBody = 'Home pública do visitante';
}

class SelectChurchMockData {
  const SelectChurchMockData._();

  static const title = 'Selecione uma igreja';
  static const searchHint = 'Busque o nome ou endereço da igreja';
  static const locationButton = 'Usar localização atual';
  static const modalTitle = 'Igreja';
  static const confirmChoice = 'Confirmar escolha';
  static const backToList = 'Voltar para a lista';

  static const churches = <ChurchOptionData>[
    ChurchOptionData(
      name: 'Nova Aliança olinda',
      address:
          'Av. Leopoldino Canuto de Melo, 846 - Caixa D Água, Olinda - PE, 53210-250',
    ),
    ChurchOptionData(
      name: 'Nova Aliança petrolina',
      address: 'rua 47, número 180- São Gonçalo',
    ),
  ];
}

class ChurchOptionData {
  const ChurchOptionData({required this.name, required this.address});

  final String name;
  final String address;
}

class CadastroMockData {
  const CadastroMockData._();

  static const headerTitle = 'Criar Conta';
  static const subtitle = EntracontaMockData.subtitle;
  static const nomeLabel = 'Nome Completo';
  static const nomeHint = 'Seu nome';
  static const emailLabel = 'E-mail';
  static const emailHint = 'seu@email.com';
  static const telefoneLabel = 'Telefone (WhatsApp)';
  static const telefoneHint = '(00) 00000-0000';
  static const senhaLabel = 'Senha';
  static const senhaHint = '••••••••';
  static const senhaHelp = 'Mínimo de 8 caracteres.';
  static const submit = 'CADASTRAR';
  static const loginPrefix = 'Já tem uma conta?';
  static const loginLink = 'Faça login';
  static const termsLine1 = 'Ao se cadastrar, você concorda com nossos Termos';
  static const termsLine2 = 'de Uso e Política de Privacidade.';
}

class RecuperarSenhaMockData {
  const RecuperarSenhaMockData._();

  static const headerTitle = 'Nova alinça';
  static const subtitle = EntracontaMockData.subtitle;
  static const title = 'Recuperar Senha';
  static const description =
      'Digite seu e-mail cadastrado e\nenviaremos um link para redefinir sua\nsenha.';
  static const emailLabel = 'E-mail';
  static const emailHint = 'insira seu email';
  static const submit = 'ENVIAR  LINK';
  static const backToLogin = 'Voltar para o Login';
}

class EmailEnviadoMockData {
  const EmailEnviadoMockData._();

  static const headerTitle = 'Nova alinça';
  static const subtitle = EntracontaMockData.subtitle;
  static const title = 'E-mail Enviado!';
  static const description =
      'Enviamos um link de recuperação para o\ne-mail que você informou.';
  static const backToLogin = 'VOLTAR PARA O LOGIN';
  static const notReceived = 'Não recebeu o e-mail?';
  static const tryAgain = 'Tentar novamente';
}

class HomeAssets {
  const HomeAssets._();

  static const logo = 'assets/images/figma/home/home_logo.jpg';
  static const notification = 'assets/images/figma/home/home_notification.svg';
  static const menu = 'assets/images/figma/home/home_menu.svg';
  static const word = 'assets/images/figma/home/home_word.svg';
  static const calendar = 'assets/images/figma/home/home_calendar.svg';
  static const check = 'assets/images/figma/home/home_check.svg';
  static const arrow = 'assets/images/figma/home/home_arrow.svg';
  static const scaleBell = 'assets/images/figma/home/home_scale_bell.svg';
  static const alert = 'assets/images/figma/home/home_alert.svg';
  static const instagram = 'assets/images/figma/home/home_instagram.svg';
  static const bible = 'assets/images/figma/home/home_bible.svg';
  static const heart = 'assets/images/figma/home/home_quick_1.svg';
  static const community = 'assets/images/figma/home/home_quick_2.svg';
  static const churchCircle = 'assets/images/figma/home/home_quick_3.svg';
  static const trophyCircle = 'assets/images/figma/home/home_quick_4.svg';
  static const ministry = 'assets/images/figma/home/home_quick_5.svg';
  static const devotional = 'assets/images/figma/home/home_quick_6.svg';
  static const home = 'assets/images/figma/home/home_quick_7.svg';
  static const schedule = 'assets/images/figma/home/home_quick_8.svg';
  static const mural = 'assets/images/figma/home/home_mural.svg';
  static const live = 'assets/images/figma/home/home_live.svg';
  static const management = 'assets/images/figma/home/home_management.svg';
  static const prayer = 'assets/images/figma/home/home_bottom_1.svg';
  static const contribute = 'assets/images/figma/home/home_bottom_2.svg';
  static const profile = 'assets/images/figma/home/home_bottom_3.svg';
}

class HomeMockData {
  const HomeMockData._();

  static const communityName = 'Comunidade Nova Aliança';
  static const greeting = 'OLÁ, JOÃO!';
  static const greetingSubtitle = 'Que a paz do Senhor esteja com você hoje.';
  static const wordLabel = 'PALAVRA DO DIA';
  static const verse = '"O Senhor é o meu pastor;\nnada me faltará."';
  static const verseReference = 'Salmos 23:1';
  static const nextServiceLabel = 'PRÓXIMO CULTO';
  static const leaderMinistryLabel = 'MEU MINISTÉRIO';
  static const nextStepsTitle = 'ACESSO RÁPIDO';
  static const seeAll = 'Ver tudo';

  static const quickLinks = <HomeQuickLinkData>[
    HomeQuickLinkData(
      'Sobre nós',
      asset: HomeAssets.churchCircle,
      iconIncludesCircle: true,
    ),
    HomeQuickLinkData(
      'Ministério',
      asset: HomeAssets.ministry,
      iconWidth: 24,
      iconHeight: 12,
    ),
    HomeQuickLinkData('Devocionais', asset: HomeAssets.devotional),
    HomeQuickLinkData(
      'Mural de oração',
      asset: HomeAssets.mural,
      iconIncludesCircle: true,
    ),
    HomeQuickLinkData('Bíblia', asset: HomeAssets.bible),
    HomeQuickLinkData('Instagram', asset: HomeAssets.instagram),
    HomeQuickLinkData(
      'Contribuir',
      asset: HomeAssets.heart,
      iconWidth: 18.333,
      iconHeight: 18.821,
    ),
    HomeQuickLinkData(
      'Ao vivo',
      asset: HomeAssets.live,
      iconIncludesCircle: true,
    ),
  ];

  static const bottomNavigation = <HomeBottomNavigationData>[
    HomeBottomNavigationData(
      'Início',
      HomeAssets.home,
      width: 60.78,
      iconWidth: 16,
      iconHeight: 18,
      selected: true,
    ),
    HomeBottomNavigationData(
      'Avisos',
      HomeAssets.notification,
      width: 60.78,
      iconWidth: 16,
      iconHeight: 20,
      fontSize: 11,
    ),
    HomeBottomNavigationData(
      'Programação',
      HomeAssets.schedule,
      width: 86,
      iconWidth: 16.5,
      iconHeight: 20.333,
      fontSize: 11,
    ),
    HomeBottomNavigationData(
      'Oração',
      HomeAssets.prayer,
      width: 49,
      iconWidth: 20,
      iconHeight: 20,
    ),
    HomeBottomNavigationData(
      'Contribuir',
      HomeAssets.contribute,
      width: 69,
      iconWidth: 18.333,
      iconHeight: 18.821,
      fontSize: 11,
    ),
    HomeBottomNavigationData(
      'Perfil',
      HomeAssets.profile,
      width: 55,
      iconWidth: 14.667,
      iconHeight: 16.667,
    ),
  ];
}

class HomeQuickLinkData {
  const HomeQuickLinkData(
    this.label, {
    this.asset,
    this.icon,
    this.iconIncludesCircle = false,
    this.iconWidth = 24,
    this.iconHeight = 24,
  });

  final String label;
  final String? asset;
  final IconData? icon;
  final bool iconIncludesCircle;
  final double iconWidth;
  final double iconHeight;
}

class HomeBottomNavigationData {
  const HomeBottomNavigationData(
    this.label,
    this.asset, {
    required this.width,
    required this.iconWidth,
    required this.iconHeight,
    this.selected = false,
    this.fontSize = 12,
  });

  final String label;
  final String asset;
  final double width;
  final double iconWidth;
  final double iconHeight;
  final bool selected;
  final double fontSize;
}
