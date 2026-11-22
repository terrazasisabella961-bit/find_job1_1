
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_error_message.dart';
import '../services/auth_repository.dart';
import '../services/user_profile_repository.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/cocha_conecta_logo.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({
    required this.authRepository,
    required this.profileRepository,
    this.initialProfile,
    this.isEditing = false,
    this.isProfileCompletion = false,
    this.onProfileSaved,
    super.key,
  });

  final AuthRepository authRepository;
  final UserProfileRepository profileRepository;
  final UserProfile? initialProfile;
  final bool isEditing;
  final bool isProfileCompletion;
  final ValueChanged<UserProfile>? onProfileSaved;

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late final _nameController = TextEditingController(
    text: widget.initialProfile?.fullName ?? '',
  );
  late final _emailController = TextEditingController(
    text:
        widget.initialProfile?.email ??
        widget.authRepository.currentUser?.email ??
        '',
  );
  late final _phoneController = TextEditingController(
    text: widget.initialProfile?.phone ?? '',
  );
  late final _areaController = TextEditingController(
    text: widget.initialProfile?.areaOfInterest ?? '',
  );
  late final _careerController = TextEditingController(
    text: widget.initialProfile?.careerTitle ?? '',
  );
  late final _aboutController = TextEditingController(
    text: widget.initialProfile?.aboutMe ?? '',
  );
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static const _cities = [
    'La Paz',
    'Santa Cruz de la Sierra',
    'Cochabamba',
    'Sucre',
    'Oruro',
    'Potosí',
    'Tarija',
    'Trinidad',
    'Cobija',
    'El Alto',
  ];

  String? _city;
  String? _educationLevel;
  List<String> _skills = [];
  List<ProfileLanguage> _languages = [];
  PlatformFile? _cvFile;
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final savedCity = widget.initialProfile?.city;
    _city = savedCity == null || savedCity.isEmpty ? null : savedCity;
    final savedEducation = widget.initialProfile?.educationLevel ?? '';
    _educationLevel = savedEducation.isEmpty ? null : savedEducation;
    _skills = List<String>.from(widget.initialProfile?.skills ?? const []);
    _languages = List<ProfileLanguage>.from(
      widget.initialProfile?.languages ?? const [],
    );
  }

  List<String> get _availableCities {
    final cities = _cities.toSet();
    if (_city != null) cities.add(_city!);
    return cities.toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _areaController.dispose();
    _careerController.dispose();
    _aboutController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label es obligatorio.';
    return null;
  }

  String? _validateEmail(String? value) {
    final requiredError = _required(value, 'El correo electrónico');
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  Future<void> _selectCv() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'docx'],
      );
      if (!mounted || result.isEmpty) return;

      final selected = result.single;
      final fileSize = await selected.length();
      if (!mounted) return;
      if (fileSize != null && fileSize > 10 * 1024 * 1024) {
        _showMessage('El archivo supera el límite de 10 MB.');
        return;
      }
      setState(() => _cvFile = selected);
    } on Exception catch (error) {
      if (mounted) _showMessage('No se pudo seleccionar el CV: $error');
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final requiresConsent =
        !widget.isEditing || widget.initialProfile?.acceptedTerms != true;
    if (requiresConsent && !_acceptedTerms) {
      _showMessage(
        'Debes aceptar los Términos y Condiciones y la Política de Privacidad.',
      );
      return;
    }
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final email = _emailController.text.trim();
      final currentUser = widget.authRepository.currentUser;
      final user = widget.isEditing
          ? currentUser
          : currentUser != null &&
                currentUser.email?.toLowerCase() == email.toLowerCase()
          ? currentUser
          : (await widget.authRepository.register(
              email: email,
              password: _passwordController.text,
            )).user;

      if (user == null) {
        throw Exception('Firebase no devolvió el usuario recién creado.');
      }
      final fullName = _nameController.text.trim();

      final profile = _profileFromForm(
        uid: user.uid,
        email: email,
        acceptedTerms:
            requiresConsent || widget.initialProfile?.acceptedTerms == true,
        isVisible: widget.initialProfile?.isVisible ?? false,
        cvUrl: widget.initialProfile?.cvUrl,
        cvFileName: _cvFile?.name ?? widget.initialProfile?.cvFileName,
      );
      final saveOperations = <Future<void>>[
        widget.profileRepository.saveProfile(
          profile: profile,
          cvFile: _cvFile,
        ),
        if (user.displayName != fullName) user.updateDisplayName(fullName),
      ];
      await Future.wait(saveOperations);

      if (!mounted) return;
      _showMessage(
        _cvFile == null
            ? 'Tu perfil se guardó correctamente.'
            : 'Tu perfil se guardó. El CV quedó adjunto en la app (simulación; no se sube a Storage).',
      );
      if (widget.onProfileSaved != null) {
        widget.onProfileSaved!(profile);
      } else {
        Navigator.of(context).pop();
      }
    } on StorageUploadException catch (error) {
      if (!mounted) return;
      _showMessage(
        'La cuenta quedó creada, pero el CV no se subió. ${authErrorMessage(error)}',
      );
      if (widget.onProfileSaved != null) {
        widget.onProfileSaved!(
          _profileFromForm(
            uid: widget.authRepository.currentUser?.uid ?? '',
            email: _emailController.text.trim(),
            acceptedTerms: true,
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    } on Exception catch (error) {
      if (mounted) _showMessage(authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  UserProfile _profileFromForm({
    required String uid,
    required String email,
    required bool acceptedTerms,
    bool isVisible = false,
    String? cvUrl,
    String? cvFileName,
  }) {
    return UserProfile(
      uid: uid,
      fullName: _nameController.text.trim(),
      email: email,
      phone: _phoneController.text.trim(),
      city: _city ?? '',
      areaOfInterest: _areaController.text.trim(),
      educationLevel: _educationLevel ?? '',
      careerTitle: _careerController.text.trim(),
      skills: List<String>.from(_skills),
      languages: List<ProfileLanguage>.from(_languages),
      aboutMe: _aboutController.text.trim(),
      acceptedTerms: acceptedTerms,
      isVisible: isVisible,
      cvUrl: cvUrl,
      cvFileName: cvFileName,
    );
  }

  void _toggleSkill(String skill, bool selected) {
    setState(() {
      if (selected) {
        if (!_skills.contains(skill)) _skills.add(skill);
      } else {
        _skills.remove(skill);
      }
    });
  }

  void _toggleLanguage(String name, bool selected) {
    setState(() {
      if (selected) {
        if (_languages.every((language) => language.name != name)) {
          _languages.add(ProfileLanguage(name: name));
        }
      } else {
        _languages.removeWhere((language) => language.name == name);
      }
    });
  }

  void _setLanguageLevel(String name, String level) {
    setState(() {
      _languages = [
        for (final language in _languages)
          if (language.name == name)
            ProfileLanguage(name: name, level: level)
          else
            language,
      ];
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: appSurfaceColor),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RegistrationHeader(
                        onBack: () {
                          if (widget.isProfileCompletion) {
                            widget.authRepository.signOut();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        isEditing: widget.isEditing,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.isEditing
                            ? 'Actualizar tu perfil profesional'
                            : 'Crear tu perfil profesional',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Regístrate para postularte a las ofertas de empleo y '
                        'acceder a los cursos y diplomados disponibles.',
                        style: TextStyle(
                          color: appMutedColor,
                          fontSize: 9,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _NoticeCard(
                        text:
                            'INFORMACIÓN: TU INFORMACIÓN PERSONAL Y '
                            'CURRICULAR SOLO SERÁN VISIBLES PARA LAS '
                            'EMPRESAS E INSTITUCIONES A LAS QUE DECIDAS '
                            'POSTULARTE.',
                      ),
                      const SizedBox(height: 14),
                      _RegistrationField(
                        label: 'Nombre y apellidos',
                        hint: 'Ej. Alejandra Morales',
                        controller: _nameController,
                        validator: (value) => _required(value, 'El nombre'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const _FieldHint(
                        'Tu nombre completo tal como aparece en tu documento.',
                      ),
                      _RegistrationField(
                        label: 'Correo electrónico',
                        hint: 'correo@ejemplo.com',
                        controller: _emailController,
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: widget.isEditing,
                      ),
                      const _FieldHint('Será tu usuario para iniciar sesión.'),
                      _RegistrationField(
                        label: 'Teléfono / WhatsApp',
                        hint: '+591 7XXXXXXX',
                        controller: _phoneController,
                        validator: (value) => _required(value, 'El teléfono'),
                        keyboardType: TextInputType.phone,
                      ),
                      const _FieldHint(
                        'Para recibir notificaciones y contacto directo de empleadores.',
                      ),
                      _CityField(
                        value: _city,
                        cities: _availableCities,
                        onChanged: (value) => setState(() => _city = value),
                        validator: (value) =>
                            value == null ? 'Selecciona tu ciudad.' : null,
                      ),
                      const _FieldHint(
                        'Selecciona la ciudad donde resides actualmente.',
                      ),
                      _RegistrationField(
                        label: 'Área profesional o de interés',
                        hint: 'Ej. Tecnología, Administración, Ventas, etc.',
                        controller: _areaController,
                        validator: (value) =>
                            _required(value, 'El área profesional'),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const _FieldHint(
                        'Tu especialidad principal o rubro laboral deseado.',
                      ),
                      _EducationField(
                        value: _educationLevel,
                        options: [
                          ...profileEducationLevels,
                          if (_educationLevel != null &&
                              _educationLevel!.isNotEmpty &&
                              !profileEducationLevels.contains(
                                _educationLevel,
                              ))
                            _educationLevel!,
                        ],
                        onChanged: (value) =>
                            setState(() => _educationLevel = value),
                      ),
                      const _FieldHint('Opcional. Nivel de estudios alcanzado.'),
                      _RegistrationField(
                        label: 'Carrera o título',
                        hint: 'Ej. Ingeniería Ambiental, Administración...',
                        controller: _careerController,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const _FieldHint('Opcional. Nombre de tu carrera o título.'),
                      _TagSection(
                        label: 'Habilidades',
                        hint: 'Opcional. Elige las que te describen.',
                        options: profileSkillTags,
                        selected: _skills,
                        onToggle: _toggleSkill,
                      ),
                      _LanguageSection(
                        selected: _languages,
                        onToggle: _toggleLanguage,
                        onLevelChanged: _setLanguageLevel,
                      ),
                      _RegistrationField(
                        label: 'Sobre mí',
                        hint: 'Dos o tres líneas sobre tu perfil profesional.',
                        controller: _aboutController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        maxLength: 240,
                      ),
                      const _FieldHint('Opcional. No es obligatorio para registrarte.'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Currículum Vitae (CV)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _selectCv,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Recomendado',
                              style: TextStyle(
                                color: appPurpleColor,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sube tu CV para que los reclutadores evalúen tu perfil.',
                        style: TextStyle(color: appMutedColor, fontSize: 8),
                      ),
                      const SizedBox(height: 8),
                      _CvPicker(
                        file: _cvFile,
                        existingFileName: widget.initialProfile?.cvFileName,
                        onTap: _selectCv,
                        onRemove: () => setState(() => _cvFile = null),
                      ),
                      const _FieldHint(
                        'Formatos admitidos: PDF, DOCX (Máx. 10 MB)',
                      ),
                      const SizedBox(height: 10),
                      if (!widget.isEditing)
                        _PasswordField(
                          label: 'Contraseña',
                          hint: 'Crea una contraseña segura',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          validator: (value) {
                            final error = _required(value, 'La contraseña');
                            if (error != null) return error;
                            if (value!.length < 8) {
                              return 'Mínimo 8 caracteres.';
                            }
                            return null;
                          },
                        ),
                      if (!widget.isEditing)
                        const _FieldHint('Mínimo 8 caracteres.'),
                      if (!widget.isEditing)
                        _PasswordField(
                          label: 'Confirmar contraseña',
                          hint: 'Repite tu contraseña',
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmation,
                          onToggleVisibility: () => setState(
                            () => _obscureConfirmation = !_obscureConfirmation,
                          ),
                          validator: (value) {
                            final error = _required(value, 'La confirmación');
                            if (error != null) return error;
                            if (value != _passwordController.text) {
                              return 'Las contraseñas no coinciden.';
                            }
                            return null;
                          },
                        ),
                      if (!widget.isEditing)
                        const _FieldHint(
                          'Asegúrate de que ambas contraseñas coincidan.',
                        ),
                      if (!widget.isEditing ||
                          widget.initialProfile?.acceptedTerms != true) ...[
                        const SizedBox(height: 10),
                        _TermsCheckbox(
                          value: _acceptedTerms,
                          onChanged: (value) =>
                              setState(() => _acceptedTerms = value ?? false),
                          onOpenTerms: () => showSimulatedLegalDialog(
                            context,
                            title: 'Términos y Condiciones',
                            body: simulatedTermsBody,
                          ),
                          onOpenPrivacy: () => showSimulatedLegalDialog(
                            context,
                            title: 'Política de Privacidad',
                            body: simulatedPrivacyBody,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const DevelopedByCredit(),
            _RegistrationActions(
              isSubmitting: _isSubmitting,
              isEditing: widget.isEditing,
              onSubmit: _submit,
              onSignIn: () => Navigator.of(context).pop(),
              onScrollTop: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationHeader extends StatelessWidget {
  const _RegistrationHeader({required this.onBack, required this.isEditing});

  final VoidCallback onBack;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CochaConectaLogo(height: 88),
        const SizedBox(height: 8),
        Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          color: appPurpleColor,
          style: IconButton.styleFrom(
            backgroundColor: appSurfaceColor,
            side: const BorderSide(color: appBorderColor),
            fixedSize: const Size(34, 34),
          ),
          tooltip: 'Volver',
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'MI CUENTA',
                style: const TextStyle(
                  color: appMutedColor,
                  fontSize: 11,
                  letterSpacing: 0.7,
                ),
              ),
              Text(
                isEditing ? 'ACTUALIZAR PERFIL' : 'REGISTRO DE USUARIO',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: appSurfaceColor,
            shape: BoxShape.circle,
            border: Border.all(color: appBorderColor),
          ),
          child: const Icon(
            Icons.person_outline,
            color: appPurpleColor,
            size: 16,
          ),
        ),
      ],
        ),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: appPurpleColor, width: 3)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 7, height: 1.45),
      ),
    );
  }
}

class _RegistrationField extends StatelessWidget {
  const _RegistrationField({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            readOnly: readOnly,
            maxLines: maxLines,
            maxLength: maxLength,
            style: const TextStyle(color: Colors.white, fontSize: 9),
            decoration: _fieldDecoration(hint),
          ),
        ],
      ),
    );
  }
}

class _EducationField extends StatelessWidget {
  const _EducationField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nivel de estudios',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<String?>(
            initialValue: value,
            onChanged: onChanged,
            dropdownColor: appSurfaceColor,
            iconEnabledColor: appMutedColor,
            style: const TextStyle(color: Colors.white, fontSize: 9),
            decoration: _fieldDecoration('Opcional'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No especificar'),
              ),
              for (final option in options)
                DropdownMenuItem<String?>(value: option, child: Text(option)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagSection extends StatelessWidget {
  const _TagSection({
    required this.label,
    required this.hint,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final String hint;
  final List<String> options;
  final List<String> selected;
  final void Function(String skill, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(hint, style: const TextStyle(color: appMutedColor, fontSize: 7)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(option),
                  selected: selected.contains(option),
                  onSelected: (value) => onToggle(option, value),
                  selectedColor: appPurpleColor.withValues(alpha: 0.35),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected.contains(option)
                        ? Colors.white
                        : appMutedColor,
                    fontSize: 8,
                  ),
                  backgroundColor: appSurfaceColor,
                  side: const BorderSide(color: appBorderColor),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection({
    required this.selected,
    required this.onToggle,
    required this.onLevelChanged,
  });

  final List<ProfileLanguage> selected;
  final void Function(String name, bool selected) onToggle;
  final void Function(String name, String level) onLevelChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Idiomas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Opcional. En Cochabamba, el quechua puede marcar diferencia.',
            style: TextStyle(color: appMutedColor, fontSize: 7),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final name in profileLanguageNames)
                FilterChip(
                  label: Text(name),
                  selected: selected.any((language) => language.name == name),
                  onSelected: (value) => onToggle(name, value),
                  selectedColor: appOrangeColor.withValues(alpha: 0.35),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected.any((language) => language.name == name)
                        ? Colors.white
                        : appMutedColor,
                    fontSize: 8,
                  ),
                  backgroundColor: appSurfaceColor,
                  side: const BorderSide(color: appBorderColor),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
          for (final language in selected) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    language.name,
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ),
                DropdownButton<String>(
                  value: language.level,
                  dropdownColor: appSurfaceColor,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                  items: [
                    for (final level in profileLanguageLevels)
                      DropdownMenuItem(value: level, child: Text(level)),
                  ],
                  onChanged: (value) {
                    if (value != null) onLevelChanged(language.name, value);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CityField extends StatelessWidget {
  const _CityField({
    required this.value,
    required this.cities,
    required this.onChanged,
    required this.validator,
  });

  final String? value;
  final List<String> cities;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ciudad de residencia',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            initialValue: value,
            validator: validator,
            onChanged: onChanged,
            dropdownColor: appSurfaceColor,
            iconEnabledColor: appMutedColor,
            style: const TextStyle(color: Colors.white, fontSize: 9),
            decoration: _fieldDecoration('Selecciona tu ciudad'),
            items: [
              for (final city in cities)
                DropdownMenuItem(value: city, child: Text(city)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CvPicker extends StatelessWidget {
  const _CvPicker({
    required this.file,
    required this.existingFileName,
    required this.onTap,
    required this.onRemove,
  });

  final PlatformFile? file;
  final String? existingFileName;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: appBorderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF281D2C),
              shape: BoxShape.circle,
              border: Border.all(color: appOrangeColor.withValues(alpha: 0.5)),
            ),
            child: const Icon(
              Icons.upload_file_outlined,
              color: appOrangeColor,
              size: 16,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            file?.name ??
                existingFileName ??
                'Toca aquí para seleccionar tu CV',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'PDF o DOCX, máx. 10 MB. El archivo se simula y no se sube a la nube.',
            textAlign: TextAlign.center,
            style: TextStyle(color: appMutedColor, fontSize: 7),
          ),
          const SizedBox(height: 5),
          if (file == null)
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.attach_file, size: 12),
              label: Text(
                existingFileName == null ? 'Elegir archivo' : 'Cambiar CV',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: appPurpleColor,
                minimumSize: const Size(110, 26),
                textStyle: const TextStyle(fontSize: 8),
                side: const BorderSide(color: appBorderColor),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            )
          else
            TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, size: 12),
              label: const Text('Quitar archivo'),
              style: TextButton.styleFrom(
                foregroundColor: appOrangeColor,
                textStyle: const TextStyle(fontSize: 8),
              ),
            ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            validator: validator,
            obscureText: obscureText,
            style: const TextStyle(color: Colors.white, fontSize: 9),
            decoration: _fieldDecoration(hint).copyWith(
              prefixIcon: const Icon(Icons.lock_outline, size: 14),
              suffixIcon: IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  size: 14,
                  color: appPurpleColor,
                ),
                tooltip: obscureText
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldHint extends StatelessWidget {
  const _FieldHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(color: appMutedColor, fontSize: 7, height: 1.3),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: appPurpleColor,
            side: const BorderSide(color: appMutedColor),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              children: [
                const Text(
                  'Acepto los ',
                  style: TextStyle(color: appMutedColor, fontSize: 8),
                ),
                _TermsLink(text: 'Términos y Condiciones', onTap: onOpenTerms),
                const Text(
                  ' y la ',
                  style: TextStyle(color: appMutedColor, fontSize: 8),
                ),
                _TermsLink(
                  text: 'Política de Privacidad',
                  onTap: onOpenPrivacy,
                ),
                const Text(
                  '.',
                  style: TextStyle(color: appMutedColor, fontSize: 8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsLink extends StatelessWidget {
  const _TermsLink({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: appPurpleColor,
          fontSize: 8,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _RegistrationActions extends StatelessWidget {
  const _RegistrationActions({
    required this.isSubmitting,
    required this.isEditing,
    required this.onSubmit,
    required this.onSignIn,
    required this.onScrollTop,
  });

  final bool isSubmitting;
  final bool isEditing;
  final VoidCallback onSubmit;
  final VoidCallback onSignIn;
  final VoidCallback onScrollTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
      decoration: const BoxDecoration(
        color: appBackgroundColor,
        border: Border(top: BorderSide(color: appBorderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: FilledButton.icon(
                    onPressed: isSubmitting ? null : onSubmit,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 15),
                    label: Text(
                      isSubmitting
                          ? 'Guardando...'
                          : isEditing
                          ? 'Guardar cambios'
                          : 'Registrarme',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: appOrangeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: onScrollTop,
                icon: const Icon(Icons.arrow_upward, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: appSurfaceColor,
                  foregroundColor: appMutedColor,
                  fixedSize: const Size(40, 40),
                ),
                tooltip: 'Volver arriba',
              ),
            ],
          ),
          const SizedBox(height: 5),
          if (!isEditing)
            TextButton(
              onPressed: onSignIn,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '¿Ya tienes una cuenta? Inicia sesión',
                style: TextStyle(color: appMutedColor, fontSize: 8),
              ),
            ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF77748A), fontSize: 9),
    filled: true,
    fillColor: appSurfaceColor,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    errorStyle: const TextStyle(fontSize: 8, height: 1.2),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: appBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: appPurpleColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: appOrangeColor),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: appOrangeColor),
    ),
  );
}
