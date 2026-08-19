import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/igrejas/providers/igreja_providers.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/perfil/providers/perfil_providers.dart';
import '../profile_photo_notifier.dart';
import '../widgets/internal_header.dart';
import '../escala_tela.dart';

/// Tela "Dados pessoais" — versão digital da ficha cadastral.
///
/// Carrega e salva os dados no Firestore (`usuarios/{uid}.dados_pessoais`).
/// A foto é mantida localmente por enquanto (upload ao Firebase Storage
/// depende do plano Blaze — ver STATUS_FINAL_CNA_APP.md).
class DadosPessoaisScreen extends ConsumerStatefulWidget {
  const DadosPessoaisScreen({super.key});

  @override
  ConsumerState<DadosPessoaisScreen> createState() =>
      _DadosPessoaisScreenState();
}

class _DadosPessoaisScreenState extends ConsumerState<DadosPessoaisScreen> {
  static const _designWidth = 394.0;
  static const _background = Color(0xFFFAFAFA);
  static const _primary = Color(0xFF7A0022);
  static const _title = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF6B7280);
  static const _line = Color(0xFFE5E7EB);
  static const _avatarBg = Color(0xFFE5E7EB);
  static const _avatarIcon = Color(0xFF4B5563);

  static const _sim = 'Sim';
  static const _nao = 'Não';
  static const _simNao = [_sim, _nao];

  // ---------- Seleções (todas começam sem escolha) ----------
  String? _sexo;
  String? _estadoCivil;
  String? _conjugeCristao;
  String? _batizado;
  String? _batizadoNestaIgreja;
  String? _ehLider;
  String? _cargo;
  String? _situacaoProfissional;

  bool get _isCasado => _estadoCivil == 'Casado(a)';
  bool get _isBatizado => _batizado == _sim;
  bool get _batizadoFora => _isBatizado && _batizadoNestaIgreja == _nao;
  bool get _isLider => _ehLider == _sim;

  // ---------- Foto de perfil ----------
  final _picker = ImagePicker();
  File? _profileImage;

  // ---------- Endereço (preenchido pelo ViaCEP) ----------
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _cepFocus = FocusNode();

  String? _lastQueriedCep;
  bool _loadingCep = false;

  // ---------- Demais campos de texto ----------
  final _nomeCtrl = TextEditingController();
  final _sobrenomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _nascimentoCtrl = TextEditingController();
  final _conjugeNomeCtrl = TextEditingController();
  final _qualIgrejaCtrl = TextEditingController();
  final _dataBatismoCtrl = TextEditingController();
  final _tempoEvangelhoCtrl = TextEditingController();
  final _tempoIgrejaCtrl = TextEditingController();
  final _qualGrupoCtrl = TextEditingController();
  final _profissaoCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _profileImage = profilePhotoNotifier.value;
    _cepFocus.addListener(() {
      if (!_cepFocus.hasFocus) {
        _buscarCep(_cepController.text);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    _cepController.dispose();
    _logradouroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _cepFocus.dispose();
    for (final c in [
      _nomeCtrl,
      _sobrenomeCtrl,
      _emailCtrl,
      _cpfCtrl,
      _telefoneCtrl,
      _nascimentoCtrl,
      _conjugeNomeCtrl,
      _qualIgrejaCtrl,
      _dataBatismoCtrl,
      _tempoEvangelhoCtrl,
      _tempoIgrejaCtrl,
      _qualGrupoCtrl,
      _profissaoCtrl,
      _numeroCtrl,
      _complementoCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Carrega os dados atuais do Firestore para os campos.
  Future<void> _carregar() async {
    final usuario = ref.read(usuarioProvider);
    if (usuario == null) return;
    try {
      final dados = await ref.read(perfilRepositoryProvider).carregar(usuario.uid);
      final dp = (dados['dados_pessoais'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        // Nome/telefone/email vêm do topo do documento; o resto de dados_pessoais.
        _nomeCtrl.text = (dados['nome'] as String?) ?? usuario.nome;
        _sobrenomeCtrl.text = (dp['sobrenome'] as String?) ?? '';
        _emailCtrl.text = (dados['email'] as String?) ?? usuario.email;
        _cpfCtrl.text = (dp['cpf'] as String?) ?? '';
        _telefoneCtrl.text = (dados['telefone'] as String?) ?? usuario.telefone;
        _nascimentoCtrl.text = (dp['nascimento'] as String?) ?? '';
        _sexo = dp['sexo'] as String?;
        _estadoCivil = dp['estado_civil'] as String?;
        _conjugeNomeCtrl.text = (dp['conjuge_nome'] as String?) ?? '';
        _conjugeCristao = dp['conjuge_cristao'] as String?;
        _batizado = dp['batizado'] as String?;
        _batizadoNestaIgreja = dp['batizado_nesta_igreja'] as String?;
        _qualIgrejaCtrl.text = (dp['qual_igreja'] as String?) ?? '';
        _dataBatismoCtrl.text = (dp['data_batismo'] as String?) ?? '';
        _tempoEvangelhoCtrl.text = (dp['tempo_evangelho'] as String?) ?? '';
        _tempoIgrejaCtrl.text = (dp['tempo_igreja'] as String?) ?? '';
        _cargo = dp['cargo'] as String?;
        _ehLider = dp['eh_lider'] as String?;
        _qualGrupoCtrl.text = (dp['qual_grupo'] as String?) ?? '';
        _situacaoProfissional = dp['situacao_profissional'] as String?;
        _profissaoCtrl.text = (dp['profissao'] as String?) ?? '';
        _cepController.text = (dp['cep'] as String?) ?? '';
        _logradouroController.text = (dp['logradouro'] as String?) ?? '';
        _numeroCtrl.text = (dp['numero'] as String?) ?? '';
        _complementoCtrl.text = (dp['complemento'] as String?) ?? '';
        _bairroController.text = (dp['bairro'] as String?) ?? '';
        _cidadeController.text = (dp['cidade'] as String?) ?? '';
        _estadoController.text = (dp['estado'] as String?) ?? '';
      });
    } catch (_) {
      // Mantém o formulário vazio se a leitura falhar.
    }
  }

  /// Salva todos os campos no Firestore.
  Future<void> _salvar() async {
    if (_saving) return;
    final usuario = ref.read(usuarioProvider);
    if (usuario == null) {
      _showMessage('Faça login para salvar seus dados.');
      return;
    }
    if (_nomeCtrl.text.trim().isEmpty) {
      _showMessage('Informe seu nome');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(perfilRepositoryProvider).salvar(
            usuario.uid,
            nome: _nomeCtrl.text.trim(),
            telefone: _telefoneCtrl.text.trim(),
            dadosPessoais: {
              'sobrenome': _sobrenomeCtrl.text.trim(),
              'cpf': _cpfCtrl.text.trim(),
              'nascimento': _nascimentoCtrl.text.trim(),
              'sexo': _sexo,
              'estado_civil': _estadoCivil,
              'conjuge_nome': _conjugeNomeCtrl.text.trim(),
              'conjuge_cristao': _conjugeCristao,
              'batizado': _batizado,
              'batizado_nesta_igreja': _batizadoNestaIgreja,
              'qual_igreja': _qualIgrejaCtrl.text.trim(),
              'data_batismo': _dataBatismoCtrl.text.trim(),
              'tempo_evangelho': _tempoEvangelhoCtrl.text.trim(),
              'tempo_igreja': _tempoIgrejaCtrl.text.trim(),
              'cargo': _cargo,
              'eh_lider': _ehLider,
              'qual_grupo': _qualGrupoCtrl.text.trim(),
              'situacao_profissional': _situacaoProfissional,
              'profissao': _profissaoCtrl.text.trim(),
              'cep': _cepController.text.trim(),
              'logradouro': _logradouroController.text.trim(),
              'numero': _numeroCtrl.text.trim(),
              'complemento': _complementoCtrl.text.trim(),
              'bairro': _bairroController.text.trim(),
              'cidade': _cidadeController.text.trim(),
              'estado': _estadoController.text.trim(),
            },
          );
      if (!mounted) return;
      _showMessage('Dados salvos com sucesso!');
    } catch (_) {
      if (mounted) _showMessage('Não foi possível salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
      );
      if (picked == null) return;

      final file = File(picked.path);
      if (!mounted) return;
      setState(() => _profileImage = file);
      profilePhotoNotifier.value = file;
    } catch (_) {
      _showMessage('Não foi possível abrir a galeria');
    }
  }

  /// Consulta o ViaCEP e preenche logradouro, bairro, cidade e estado.
  /// Usa `HttpClient` do `dart:io` para não depender de pacote extra.
  Future<void> _buscarCep(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepLimpo.length != 8) return;
    // Evita repetir a mesma consulta (onChanged + saída do campo).
    if (cepLimpo == _lastQueriedCep || _loadingCep) return;

    _lastQueriedCep = cepLimpo;
    _loadingCep = true;

    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final data = jsonDecode(body) as Map<String, dynamic>;
      if (!mounted) return;

      if (data.containsKey('erro')) {
        _showMessage('CEP não encontrado');
        return;
      }

      setState(() {
        _logradouroController.text = (data['logradouro'] ?? '') as String;
        _bairroController.text = (data['bairro'] ?? '') as String;
        _cidadeController.text = (data['localidade'] ?? '') as String;
        _estadoController.text = (data['uf'] ?? '') as String;
      });
    } catch (_) {
      // Permite nova tentativa depois de uma falha de rede.
      _lastQueriedCep = null;
      _showMessage('Erro ao buscar CEP');
    } finally {
      _loadingCep = false;
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

              return Column(
                children: [
                  InternalHeader(
                    title: 'Dados pessoais',
                    scale: scale,
                    topPadding: topPadding,
                    uppercaseTitle: false,
                    titleSize: 18,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16 * scale,
                        24 * scale,
                        16 * scale,
                        24 * scale,
                      ),
                      child: _buildForm(scale),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: _SaveBar(
          onSave: _salvar,
          saving: _saving,
        ),
      ),
    );
  }

  Widget _buildForm(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= Foto de perfil =================
        Center(
          child: _AvatarPicker(
            scale: scale,
            image: _profileImage,
            onTap: _pickImage,
          ),
        ),
        SizedBox(height: 28 * scale),

        // ================= Bloco 1: Dados básicos =================
        _SectionTitle('Dados básicos', scale: scale),
        SizedBox(height: 16 * scale),
        _FormTextField(
          label: 'Nome *',
          scale: scale,
          controller: _nomeCtrl,
        ),
        _FormTextField(
          label: 'Sobrenome *',
          scale: scale,
          controller: _sobrenomeCtrl,
        ),
        _FormTextField(
          label: 'Email',
          scale: scale,
          hint: 'seu@email.com',
          keyboardType: TextInputType.emailAddress,
          controller: _emailCtrl,
        ),
        _FormTextField(
          label: 'CPF',
          scale: scale,
          hint: '000.000.000-00',
          keyboardType: TextInputType.number,
          inputFormatters: [_MaskTextInputFormatter('###.###.###-##')],
          controller: _cpfCtrl,
        ),
        _FormTextField(
          label: 'Telefone',
          scale: scale,
          hint: '(00) 00000-0000',
          keyboardType: TextInputType.phone,
          inputFormatters: [_MaskTextInputFormatter('(##) #####-####')],
          prefix: _PhonePrefix(scale: scale),
          controller: _telefoneCtrl,
        ),
        _FormTextField(
          label: 'Data de nascimento',
          scale: scale,
          hint: '00/00/0000',
          keyboardType: TextInputType.datetime,
          prefixIcon: Icons.calendar_today_outlined,
          inputFormatters: [_MaskTextInputFormatter('##/##/####')],
          controller: _nascimentoCtrl,
        ),
        _RadioField(
          label: 'Sexo',
          scale: scale,
          value: _sexo,
          options: const ['Masculino', 'Feminino'],
          onChanged: (value) => setState(() => _sexo = value),
        ),
        SizedBox(height: 12 * scale),

        // ================= Bloco 2: Vida eclesiástica =================
        _SectionTitle('Vida eclesiástica', scale: scale),
        SizedBox(height: 16 * scale),
        // Igreja do VINCULO da pessoa, nao um nome fixo.
        _LinkedChurchField(
          scale: scale,
          church: ref.watch(nomeIgrejaEmFocoProvider),
        ),
        SizedBox(height: 18 * scale),
        _DropdownField(
          label: 'Estado civil',
          scale: scale,
          value: _estadoCivil,
          hint: 'Selecione',
          items: const [
            'Solteiro(a)',
            'Casado(a)',
            'Divorciado(a)',
            'Viúvo(a)',
            'Outros',
          ],
          onChanged: (value) => setState(() => _estadoCivil = value),
        ),
        if (_isCasado) ...[
          _FormTextField(
              label: 'Nome do cônjuge',
              scale: scale,
              controller: _conjugeNomeCtrl),
          _RadioField(
            label: 'Cônjuge é cristão?',
            scale: scale,
            value: _conjugeCristao,
            options: _simNao,
            onChanged: (value) => setState(() => _conjugeCristao = value),
          ),
        ],
        _RadioField(
          label: 'Batizado nas águas?',
          scale: scale,
          value: _batizado,
          options: _simNao,
          onChanged: (value) => setState(() => _batizado = value),
        ),
        if (_isBatizado) ...[
          _RadioField(
            label: 'Foi batizado nesta igreja?',
            scale: scale,
            value: _batizadoNestaIgreja,
            options: _simNao,
            onChanged: (value) =>
                setState(() => _batizadoNestaIgreja = value),
          ),
          if (_batizadoFora)
            _FormTextField(
                label: 'Qual igreja?',
                scale: scale,
                controller: _qualIgrejaCtrl),
          _FormTextField(
            label: 'Data de batismo ou quantos anos faz',
            scale: scale,
            hint: 'Ex.: 27 anos',
            controller: _dataBatismoCtrl,
          ),
        ],
        _FormTextField(
          label: 'Quanto tempo no evangelho?',
          scale: scale,
          hint: 'Ex.: 27 anos',
          controller: _tempoEvangelhoCtrl,
        ),
        _FormTextField(
          label: 'Quanto tempo nesta igreja?',
          scale: scale,
          hint: 'Ex.: 3 anos',
          controller: _tempoIgrejaCtrl,
        ),
        _DropdownField(
          label: 'Cargo eclesiástico',
          scale: scale,
          value: _cargo,
          hint: 'Selecione',
          items: const [
            'Membro',
            'Cooperador(a)',
            'Diácono/Diaconisa',
            'Missionário(a)',
            'Evangelista',
            'Presbítero',
            'Pastor(a)',
          ],
          onChanged: (value) => setState(() => _cargo = value),
        ),
        _RadioField(
          label: 'É líder?',
          scale: scale,
          value: _ehLider,
          options: _simNao,
          onChanged: (value) => setState(() => _ehLider = value),
        ),
        if (_isLider)
          _FormTextField(
              label: 'De qual grupo?',
              scale: scale,
              controller: _qualGrupoCtrl),
        SizedBox(height: 12 * scale),

        // ================= Bloco 3: Ocupação =================
        _SectionTitle('Ocupação', scale: scale),
        SizedBox(height: 16 * scale),
        _DropdownField(
          label: 'Situação profissional',
          scale: scale,
          value: _situacaoProfissional,
          hint: 'Selecione',
          items: const [
            'Empregado',
            'Desempregado',
            'Autônomo',
            'Aposentado',
            'Estudante',
          ],
          onChanged: (value) =>
              setState(() => _situacaoProfissional = value),
        ),
        _FormTextField(
            label: 'Profissão', scale: scale, controller: _profissaoCtrl),
        SizedBox(height: 12 * scale),

        // ================= Bloco 4: Endereço =================
        _SectionTitle('Endereço', scale: scale),
        SizedBox(height: 16 * scale),
        _FormTextField(
          label: 'CEP',
          scale: scale,
          hint: '00000-000',
          keyboardType: TextInputType.number,
          controller: _cepController,
          focusNode: _cepFocus,
          inputFormatters: [_MaskTextInputFormatter('#####-###')],
          onChanged: _buscarCep,
        ),
        _FormTextField(
          label: 'Logradouro',
          scale: scale,
          hint: 'Preenchido pelo CEP',
          controller: _logradouroController,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FormTextField(
                label: 'Número',
                scale: scale,
                hint: '000',
                keyboardType: TextInputType.number,
                controller: _numeroCtrl,
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              flex: 2,
              child: _FormTextField(
                label: 'Complemento',
                scale: scale,
                hint: 'Apto, bloco… (opcional)',
                controller: _complementoCtrl,
              ),
            ),
          ],
        ),
        _FormTextField(
          label: 'Bairro',
          scale: scale,
          hint: 'Preenchido pelo CEP',
          controller: _bairroController,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _FormTextField(
                label: 'Cidade',
                scale: scale,
                hint: 'Preenchido pelo CEP',
                controller: _cidadeController,
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: _FormTextField(
                label: 'Estado',
                scale: scale,
                hint: 'UF',
                controller: _estadoController,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Máscara simples baseada em um padrão com `#` para cada dígito.
class _MaskTextInputFormatter extends TextInputFormatter {
  const _MaskTextInputFormatter(this.mask);

  final String mask;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    var digitIndex = 0;

    for (var i = 0; i < mask.length && digitIndex < digits.length; i++) {
      if (mask[i] == '#') {
        buffer.write(digits[digitIndex]);
        digitIndex++;
      } else {
        buffer.write(mask[i]);
      }
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.scale,
    required this.image,
    required this.onTap,
  });

  final double scale;
  final File? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 104 * scale,
        height: 104 * scale,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: _DadosPessoaisScreenState._avatarBg,
          shape: BoxShape.circle,
        ),
        child: image == null
            ? Icon(
                Icons.photo_camera,
                size: 40 * scale,
                color: _DadosPessoaisScreenState._avatarIcon,
              )
            : ClipOval(
                child: Image.file(
                  image!,
                  width: 104 * scale,
                  height: 104 * scale,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}

class _PhonePrefix extends StatelessWidget {
  const _PhonePrefix({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 14 * scale, right: 8 * scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🇧🇷', style: TextStyle(fontSize: 18 * scale)),
          SizedBox(width: 6 * scale),
          Text(
            '+55',
            style: GoogleFonts.inter(
              fontSize: 15 * scale,
              fontWeight: FontWeight.w500,
              color: _DadosPessoaisScreenState._title,
            ),
          ),
        ],
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
      text,
      style: GoogleFonts.montserrat(
        fontSize: 18 * scale,
        fontWeight: FontWeight.w700,
        height: 24 / 18,
        color: _DadosPessoaisScreenState._title,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14 * scale,
          fontWeight: FontWeight.w600,
          height: 20 / 14,
          color: _DadosPessoaisScreenState._title,
        ),
      ),
    );
  }
}

class _FormTextField extends StatelessWidget {
  const _FormTextField({
    required this.label,
    required this.scale,
    this.hint,
    this.keyboardType,
    this.prefixIcon,
    this.prefix,
    this.controller,
    this.focusNode,
    this.inputFormatters,
    this.onChanged,
  });

  final String label;
  final double scale;
  final String? hint;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? prefix;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8 * scale),
      borderSide: const BorderSide(color: _DadosPessoaisScreenState._line),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 18 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label, scale: scale),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            style: GoogleFonts.inter(
              fontSize: 15 * scale,
              fontWeight: FontWeight.w400,
              color: _DadosPessoaisScreenState._title,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 15 * scale,
                fontWeight: FontWeight.w400,
                color: _DadosPessoaisScreenState._muted,
              ),
              prefix: prefix,
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(
                      prefixIcon,
                      size: 20 * scale,
                      color: _DadosPessoaisScreenState._muted,
                    ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14 * scale,
                vertical: 14 * scale,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8 * scale),
                borderSide: const BorderSide(
                  color: _DadosPessoaisScreenState._primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioField extends StatelessWidget {
  const _RadioField({
    required this.label,
    required this.scale,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final double scale;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 18 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label, scale: scale),
          RadioGroup<String>(
            groupValue: value,
            onChanged: (selected) {
              if (selected != null) {
                onChanged(selected);
              }
            },
            child: Row(
              children: [
                for (final option in options)
                  Padding(
                    padding: EdgeInsets.only(right: 24 * scale),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(option),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: option,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            fillColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? _DadosPessoaisScreenState._primary
                                  : _DadosPessoaisScreenState._muted,
                            ),
                          ),
                          SizedBox(width: 6 * scale),
                          Text(
                            option,
                            style: GoogleFonts.inter(
                              fontSize: 15 * scale,
                              fontWeight: FontWeight.w400,
                              color: _DadosPessoaisScreenState._title,
                            ),
                          ),
                        ],
                      ),
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

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.scale,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final double scale;
  final String? value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 18 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label, scale: scale),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14 * scale),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _DadosPessoaisScreenState._line),
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                borderRadius: BorderRadius.circular(8 * scale),
                hint: Text(
                  hint ?? 'Selecione',
                  style: GoogleFonts.inter(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w400,
                    color: _DadosPessoaisScreenState._muted,
                  ),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22 * scale,
                  color: _DadosPessoaisScreenState._muted,
                ),
                padding: EdgeInsets.symmetric(vertical: 6 * scale),
                style: GoogleFonts.inter(
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w400,
                  color: _DadosPessoaisScreenState._title,
                ),
                items: [
                  for (final item in items)
                    DropdownMenuItem<String>(value: item, child: Text(item)),
                ],
                onChanged: (selected) {
                  if (selected != null) {
                    onChanged(selected);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha "Igreja vinculada" — nome à esquerda e botão "Alterar >" à direita.
/// Igreja vinculada — somente leitura na V1 (app exclusivo da Comunidade Nova
/// Aliança; sem troca de igreja). Exibe a igreja sem afordância de toque.
class _LinkedChurchField extends StatelessWidget {
  const _LinkedChurchField({
    required this.scale,
    required this.church,
  });

  final double scale;
  final String church;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Igreja vinculada', scale: scale),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 14 * scale,
            vertical: 14 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _DadosPessoaisScreenState._line),
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          child: Row(
            children: [
              Icon(
                Icons.church_outlined,
                size: 20 * scale,
                color: _DadosPessoaisScreenState._muted,
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Text(
                  church,
                  style: GoogleFonts.inter(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w600,
                    color: _DadosPessoaisScreenState._title,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Barra fixa no rodapé com o botão "Salvar".
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.onSave, this.saving = false});

  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final scale =
        (MediaQuery.sizeOf(context).width /
                _DadosPessoaisScreenState._designWidth)
            .clamp(escalaMinima, 1.0)
            .toDouble();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _DadosPessoaisScreenState._line),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16 * scale,
            12 * scale,
            16 * scale,
            12 * scale,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52 * scale,
            child: ElevatedButton(
              onPressed: saving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _DadosPessoaisScreenState._primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
              ),
              child: saving
                  ? SizedBox(
                      width: 22 * scale,
                      height: 22 * scale,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Salvar',
                      style: GoogleFonts.inter(
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
