import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../config/file_upload_mode.dart';
import '../models/institution.dart';
import '../models/institution_course.dart';
import '../services/auth_error_message.dart';
import '../services/auth_repository.dart';
import '../services/institution_repository.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/app_feedback.dart';
import '../widgets/form_field_label.dart';

class InstitutionPortalScreen extends StatefulWidget {
  const InstitutionPortalScreen({
    required this.authRepository,
    required this.repository,
    this.onInstitutionReady,
    this.accountTab = false,
    super.key,
  });

  final AuthRepository authRepository;
  final InstitutionRepository repository;
  final VoidCallback? onInstitutionReady;
  final bool accountTab;

  @override
  State<InstitutionPortalScreen> createState() =>
      _InstitutionPortalScreenState();
}

class _InstitutionPortalScreenState extends State<InstitutionPortalScreen> {
  bool _showRegistration = true;
  InstitutionCourse? _editingCourse;
  Institution? _editingInstitution;
  bool _creatingCourse = false;
  bool _didAutoOpenInstitution = false;
  bool _registrationInProgress = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: widget.authRepository.authStateChanges,
          initialData: widget.authRepository.currentUser,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _InstitutionError(
                message:
                    'No se pudo comprobar la sesión institucional: ${snapshot.error}',
                onRetry: () => setState(() {}),
              );
            }
            return _buildPortal(snapshot.data);
          },
        ),
      ),
    );
  }

  Widget _buildPortal(User? user) {
    if (user == null) {
      return _showRegistration
          ? InstitutionRegistrationScreen(
              authRepository: widget.authRepository,
              repository: widget.repository,
              onSignIn: () => setState(() => _showRegistration = false),
              onRegistrationStarted: () =>
                  setState(() => _registrationInProgress = true),
            )
          : InstitutionLoginScreen(
              authRepository: widget.authRepository,
              onRegister: () => setState(() => _showRegistration = true),
            );
    }

    return StreamBuilder<Institution?>(
      key: ValueKey(user.uid),
      stream: widget.repository.watchInstitution(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _InstitutionError(
            message: 'No se pudo consultar la institución: ${snapshot.error}',
            onRetry: () => setState(() {}),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: appPurpleColor),
          );
        }
        final institution = snapshot.data;
        if (institution != null && !_didAutoOpenInstitution) {
          _didAutoOpenInstitution = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onInstitutionReady?.call();
          });
        }
        if (_editingInstitution != null) {
          return InstitutionRegistrationScreen(
            authRepository: widget.authRepository,
            repository: widget.repository,
            onSignIn: () {},
            onSaved: () => setState(() => _editingInstitution = null),
            onCancel: () => setState(() => _editingInstitution = null),
            existingUser: user,
            initialInstitution: _editingInstitution,
          );
        }
        if (_creatingCourse && institution != null) {
          return InstitutionCourseFormScreen(
            institution: institution,
            repository: widget.repository,
            initialCourse: _editingCourse,
            onBack: () => setState(() {
              _creatingCourse = false;
              _editingCourse = null;
            }),
          );
        }
        if (institution == null) {
          if (!_registrationInProgress) {
            return _InstitutionAccountMismatch(
              onSignOut: widget.authRepository.signOut,
            );
          }
          return InstitutionRegistrationScreen(
            authRepository: widget.authRepository,
            repository: widget.repository,
            onSignIn: () {},
            existingUser: user,
            onRegistrationStarted: () =>
                setState(() => _registrationInProgress = true),
          );
        }
        return InstitutionDashboardScreen(
          institution: institution,
          authRepository: widget.authRepository,
          repository: widget.repository,
          accountTab: widget.accountTab,
          onPublishCourse: () => setState(() {
            _editingCourse = null;
            _creatingCourse = true;
          }),
          onEditCourse: (course) => setState(() {
            _editingCourse = course;
            _creatingCourse = true;
          }),
          onEditInstitution: () =>
              setState(() => _editingInstitution = institution),
        );
      },
    );
  }
}

class InstitutionLoginScreen extends StatefulWidget {
  const InstitutionLoginScreen({
    required this.authRepository,
    required this.onRegister,
    super.key,
  });

  final AuthRepository authRepository;
  final VoidCallback onRegister;

  @override
  State<InstitutionLoginScreen> createState() => _InstitutionLoginScreenState();
}

class _InstitutionLoginScreenState extends State<InstitutionLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy || !ensureFormValid(context, _formKey)) return;
    setState(() => _busy = true);
    try {
      await widget.authRepository.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on Exception catch (error) {
      if (mounted) {
        _showMessage(
          context,
          authErrorMessage(error),
          kind: AppMessageKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final error = _emailValidator(_email.text);
    if (error != null) {
      _showMessage(
        context,
        'Escribe primero un correo institucional válido.',
        kind: AppMessageKind.error,
      );
      return;
    }
    try {
      await widget.authRepository.sendPasswordResetEmail(_email.text.trim());
      if (mounted) {
        _showMessage(
          context,
          'Si existe una cuenta con ese correo, recibirás instrucciones para restablecer la contraseña.',
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        _showMessage(
          context,
          authErrorMessage(error),
          kind: AppMessageKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
    children: [
      _InstitutionHeader(
        title: 'ACCESO INSTITUCIONAL',
        onBack: Navigator.of(context).canPop()
            ? () => Navigator.of(context).pop()
            : null,
      ),
      const SizedBox(height: 24),
      const Text(
        'Iniciar sesión',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'Accede al tablero de tu institución con las credenciales registradas.',
        style: TextStyle(color: appMutedColor, fontSize: 12, height: 1.45),
      ),
      const SizedBox(height: 20),
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _FormLabel('Correo electrónico institucional', required: true),
            _InstitutionInput(
              controller: _email,
              hint: 'admin@institucion.edu.bo',
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            const SizedBox(height: 14),
            const _FormLabel('Contraseña', required: true),
            _InstitutionInput(
              controller: _password,
              hint: 'Contraseña de acceso',
              obscureText: _obscure,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off,
                  color: appMutedColor,
                  size: 18,
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Ingresa tu contraseña.'
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _resetPassword,
                child: const Text('¿Olvidó su contraseña?'),
              ),
            ),
            const SizedBox(height: 20),
            _PrimaryAction(
              label: _busy ? 'Ingresando...' : 'Iniciar sesión',
              icon: Icons.login,
              busy: _busy,
              onPressed: _busy ? null : _signIn,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: widget.onRegister,
        child: const Text('¿Tu institución aún no tiene cuenta? Regístrala'),
      ),
      if (Navigator.of(context).canPop())
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Volver al inicio de sesión'),
        ),
    ],
  );
}

class InstitutionRegistrationScreen extends StatefulWidget {
  const InstitutionRegistrationScreen({
    required this.authRepository,
    required this.repository,
    required this.onSignIn,
    this.existingUser,
    this.initialInstitution,
    this.onSaved,
    this.onCancel,
    this.onRegistrationStarted,
    super.key,
  });

  final AuthRepository authRepository;
  final InstitutionRepository repository;
  final VoidCallback onSignIn;
  final User? existingUser;
  final Institution? initialInstitution;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;
  final VoidCallback? onRegistrationStarted;

  @override
  State<InstitutionRegistrationScreen> createState() =>
      _InstitutionRegistrationScreenState();
}

class _InstitutionRegistrationScreenState
    extends State<InstitutionRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scroll = ScrollController();
  late final _legalName = _controller('legalName');
  late final _displayName = _controller('displayName');
  late final _taxId = _controller('taxId');
  late final _accreditation = _controller('accreditation');
  late final _address = _controller('address');
  late final _website = _controller('website');
  late final _primaryDomain = _controller(
    'primaryDomain',
    fallback: _emailDomain(widget.existingUser?.email ?? ''),
  );
  late final _secondaryDomains = _controller('secondaryDomains');
  late final _representative = _controller('representativeName');
  late final _representativeRole = _controller('representativeRole');
  late final _phone = _controller('phone');
  late final _contactEmail = _controller('contactEmail');
  late final _adminEmail = TextEditingController(
    text:
        widget.initialInstitution?.adminEmail ??
        widget.existingUser?.email ??
        '',
  );
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  late String _type = widget.initialInstitution?.type ?? 'Universidad';
  late String _country = widget.initialInstitution?.country ?? 'Bolivia';
  String? _city;
  bool _twoFactor = false;
  bool _termsAccepted = false;
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  static const _types = [
    'Universidad',
    'Instituto',
    'Centro de formación',
    'Otro',
  ];
  static const _countries = ['Bolivia'];
  static const _cities = [
    'La Paz',
    'El Alto',
    'Cochabamba',
    'Santa Cruz de la Sierra',
    'Sucre',
    'Oruro',
    'Potosí',
    'Tarija',
    'Trinidad',
    'Cobija',
  ];

  TextEditingController _controller(String key, {String fallback = ''}) =>
      TextEditingController(text: _institutionValue(key) ?? fallback);

  String? _institutionValue(String key) {
    final institution = widget.initialInstitution;
    if (institution == null) return null;
    return switch (key) {
      'legalName' => institution.legalName,
      'displayName' => institution.displayName,
      'taxId' => institution.taxId,
      'accreditation' => institution.accreditation,
      'address' => institution.address,
      'website' => institution.website,
      'primaryDomain' => institution.primaryDomain,
      'secondaryDomains' => institution.secondaryDomains.join(', '),
      'representativeName' => institution.representativeName,
      'representativeRole' => institution.representativeRole,
      'phone' => institution.phone,
      'contactEmail' => institution.contactEmail,
      _ => null,
    };
  }

  @override
  void initState() {
    super.initState();
    _city = widget.initialInstitution?.city;
    _twoFactor = widget.initialInstitution?.twoFactorRequested ?? false;
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final controller in [
      _legalName,
      _displayName,
      _taxId,
      _accreditation,
      _address,
      _website,
      _primaryDomain,
      _secondaryDomains,
      _representative,
      _representativeRole,
      _phone,
      _contactEmail,
      _adminEmail,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label es obligatorio.' : null;

  String? _validateInstitutionEmail(String? value) {
    final error = _emailValidator(value);
    if (error != null) return error;
    final domain = _emailDomain(value!.trim());
    final allowedDomains = [
      _primaryDomain.text,
      ..._secondaryDomains.text.split(','),
    ].map(_normalizeDomain).where((item) => item.isNotEmpty);
    if (!allowedDomains.any(
      (allowed) => domain == allowed || domain.endsWith('.$allowed'),
    )) {
      return 'El correo debe pertenecer a un dominio institucional autorizado.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_busy || !ensureFormValid(context, _formKey)) return;
    if (_city == null) {
      _showMessage(
        context,
        'Selecciona la ciudad de la institución.',
        kind: AppMessageKind.error,
      );
      return;
    }
    if (!_termsAccepted && widget.initialInstitution == null) {
      _showMessage(
        context,
        'Acepta los términos para continuar.',
        kind: AppMessageKind.error,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final existingUser =
          widget.existingUser ?? widget.authRepository.currentUser;
      final adminEmail = _adminEmail.text.trim().toLowerCase();
      if (existingUser == null) widget.onRegistrationStarted?.call();
      final user =
          existingUser ??
          (await widget.authRepository.register(
            email: adminEmail,
            password: _password.text,
          )).user;
      if (user == null) {
        throw StateError('Firebase no devolvió la cuenta institucional.');
      }
      if (user.email?.toLowerCase() != adminEmail) {
        throw StateError(
          'El correo de acceso debe coincidir con la cuenta autenticada.',
        );
      }

      final institution = Institution(
        uid: user.uid,
        legalName: _legalName.text.trim(),
        displayName: _displayName.text.trim(),
        type: _type,
        taxId: _taxId.text.trim(),
        accreditation: _accreditation.text.trim(),
        country: _country,
        city: _city!,
        address: _address.text.trim(),
        website: _website.text.trim(),
        primaryDomain: _normalizeDomain(_primaryDomain.text),
        secondaryDomains: _secondaryDomains.text
            .split(',')
            .map(_normalizeDomain)
            .where((domain) => domain.isNotEmpty)
            .toSet()
            .toList(),
        representativeName: _representative.text.trim(),
        representativeRole: _representativeRole.text.trim(),
        phone: _phone.text.trim(),
        contactEmail: _contactEmail.text.trim().toLowerCase(),
        adminEmail: adminEmail,
        verificationStatus: simulateInstitutionVerification
            ? 'verified'
            : (widget.initialInstitution?.verificationStatus ?? 'pending'),
        twoFactorRequested: _twoFactor,
        createdAt: widget.initialInstitution?.createdAt,
      );
      await widget.repository.saveInstitutionRequest(institution);
      if (mounted) {
        _showMessage(
          context,
          widget.initialInstitution == null
              ? 'Institución guardada. Ya puedes publicar cursos.'
              : 'Los datos de la institución se actualizaron.',
          kind: AppMessageKind.success,
        );
        widget.onSaved?.call();
      }
    } on StateError catch (error) {
      if (mounted) {
        _showMessage(context, error.message, kind: AppMessageKind.error);
      }
    } on Exception catch (error) {
      if (mounted) {
        _showMessage(
          context,
          authErrorMessage(error),
          kind: AppMessageKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingUser =
        widget.existingUser != null ||
        widget.authRepository.currentUser != null;
    final editing = widget.initialInstitution != null;
    VoidCallback? onBack;
    if (editing) {
      onBack = widget.onCancel ?? widget.onSaved;
    } else if (widget.onCancel != null) {
      onBack = widget.onCancel;
    } else if (Navigator.of(context).canPop()) {
      onBack = () => Navigator.of(context).pop();
    } else if (!hasExistingUser) {
      onBack = widget.onSignIn;
    }
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          _InstitutionHeader(
            title: editing
                ? 'ACTUALIZAR INSTITUCIÓN'
                : 'REGISTRO DE INSTITUCIÓN',
            onBack: onBack,
          ),
          const SizedBox(height: 18),
          Text(
            widget.initialInstitution == null
                ? 'Vincular entidad educativa'
                : 'Actualizar institución',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Registra tu universidad, instituto o centro de formación para publicar cursos, diplomados, posgrados y conectar con futuros estudiantes.',
            style: TextStyle(color: appMutedColor, fontSize: 10, height: 1.5),
          ),
          const SizedBox(height: 14),
          const _Notice(
            title: 'INFORMACIÓN INSTITUCIONAL',
            text: 'La validación del dominio educativo garantiza insignia oficial de verificación y acceso a publicaciones ilimitadas.',
          ),
          const SizedBox(height: 8),
          const _Notice(
            title: 'ADVERTENCIA',
            text: 'Los datos declarados están sujetos a validación documental y acreditación ministerial vigente.',
            color: appOrangeColor,
          ),
          const SizedBox(height: 20),
          const _SectionHeading('A. DATOS DE LA INSTITUCIÓN'),
          _textField(
            'Nombre legal completo',
            _legalName,
            hint: 'Ej. Universidad Mayor de San Simón',
            required: true,
            validator: (value) => _required(value, 'El nombre legal'),
          ),
          const _FieldHint(
            'Razón social oficial según personería jurídica o acreditación.',
          ),
          _textField(
            'Nombre comercial o de uso',
            _displayName,
            hint: 'Ej. UMSS / Tech Institute',
            required: true,
            validator: (value) => _required(value, 'El nombre comercial'),
          ),
          const _FieldHint(
            'Nombre abreviado o público tal como se mostrará en la app.',
          ),
          const _FormLabel('Tipo de institución', required: true),
          _dropdown(_type, _types, (value) => setState(() => _type = value)),
          const _FieldHint(
            'Define la categoría principal para tus programas de estudio.',
          ),
          _textField(
            'NIT / RUC / Identificación tributaria',
            _taxId,
            hint: 'Ej. 1028493021',
            required: true,
            validator: (value) => _required(value, 'El NIT / RUC'),
          ),
          const _FieldHint(
            'Número de identificación tributaria para facturación y validación legal.',
          ),
          _textField(
            'Resolución ministerial / Código de acreditación',
            _accreditation,
            hint: 'Ej. R.M. N° 0428/2018',
            required: true,
            validator: (value) => _required(value, 'La acreditación'),
          ),
          const _FieldHint(
            'Acreditación oficial ante el Ministerio de Educación.',
          ),
          const _FormLabel('País', required: true),
          _dropdown(
            _country,
            _countries,
            (value) => setState(() => _country = value),
          ),
          const _FieldHint('País sede o de constitución principal.'),
          const _FormLabel('Ciudad / Departamento', required: true),
          _dropdown(
            _city,
            _cities,
            (value) => setState(() => _city = value),
            hint: 'Selecciona tu ciudad o departamento',
          ),
          const _FieldHint(
            'Ubicación del campus central o sede administrativa.',
          ),
          _textField(
            'Dirección de la sede',
            _address,
            hint: 'Ej. Av. Ballivián esq. Reza N° 591, Campus Central',
            required: true,
            validator: (value) => _required(value, 'La dirección'),
          ),
          const _FieldHint(
            'Dirección física accesible para estudiantes y postulantes.',
          ),
          _textField(
            'Sitio web oficial',
            _website,
            hint: 'https://www.umss.edu.bo',
            required: true,
            keyboardType: TextInputType.url,
            validator: _websiteValidator,
          ),
          const _FieldHint(
            'Portal institucional con información de carreras y reglamentos.',
          ),
          _textField(
            'Dominio institucional principal',
            _primaryDomain,
            hint: 'umss.edu.bo',
            required: true,
            validator: _domainValidator,
          ),
          const _FieldHint(
            'Dominio corporativo/educativo principal (ej. umss.edu.bo).',
          ),
          _textField(
            'Dominios secundarios autorizados',
            _secondaryDomains,
            hint: 'posgrado.umss.edu.bo, fc y t.umss.edu.bo',
          ),
          const _FieldHint(
            'Separados por comas. Se validan durante la verificación.',
          ),
          const SizedBox(height: 16),
          const _SectionHeading('B. CONTACTO Y REPRESENTANTE LEGAL'),
          _textField(
            'Nombre del representante o responsable institucional',
            _representative,
            hint: 'Ej. Dra. María Elena Vargas',
            required: true,
            validator: (value) => _required(value, 'El representante'),
          ),
          const _FieldHint(
            'Persona autorizada legal o administrativamente ante la institución.',
          ),
          _textField(
            'Cargo o función',
            _representativeRole,
            hint: 'Ej. Director Académico, Rector, Decano',
            required: true,
            validator: (value) => _required(value, 'El cargo'),
          ),
          _textField(
            'Teléfono / WhatsApp institucional de contacto',
            _phone,
            hint: '+591 7XXXXXXX',
            required: true,
            keyboardType: TextInputType.phone,
            validator: (value) => _required(value, 'El teléfono'),
          ),
          const _FieldHint(
            'Línea directa para validación y soporte de cuenta.',
          ),
          _textField(
            'Correo electrónico oficial de contacto',
            _contactEmail,
            hint: 'contacto@umss.edu.bo',
            required: true,
            keyboardType: TextInputType.emailAddress,
            validator: _validateInstitutionEmail,
          ),
          const _FieldHint(
            'Buzón formal donde se enviarán comunicaciones institucionales.',
          ),
          const SizedBox(height: 16),
          const _SectionHeading(
            'C. CREDENCIALES DE ACCESO (LOGIN INSTITUCIONAL)',
          ),
          const _FieldHint(
            'Datos del administrador para iniciar sesión y gestionar la institución.',
          ),
          _textField(
            'Correo electrónico de inicio de sesión (Administrador)',
            _adminEmail,
            hint: 'admin.posgrado@umss.edu.bo',
            required: true,
            keyboardType: TextInputType.emailAddress,
            readOnly: hasExistingUser,
            validator: _validateInstitutionEmail,
          ),
          const _FieldHint(
            'Debe pertenecer al dominio institucional verificado.',
          ),
          if (!hasExistingUser) ...[
            _textField(
              'Contraseña de acceso',
              _password,
              hint: 'Mínimo 8 caracteres',
              required: true,
              obscureText: _obscurePassword,
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off,
                  color: appMutedColor,
                  size: 17,
                ),
              ),
              validator: (value) {
                if (value == null || value.length < 8) {
                  return 'Usa al menos 8 caracteres.';
                }
                return null;
              },
            ),
            const _FieldHint(
              'Combina mayúsculas, minúsculas, números y caracteres especiales.',
            ),
            _textField(
              'Confirmar contraseña',
              _confirmPassword,
              hint: 'Repite la contraseña ingresada',
              required: true,
              obscureText: _obscureConfirmation,
              suffix: IconButton(
                onPressed: () => setState(
                  () => _obscureConfirmation = !_obscureConfirmation,
                ),
                icon: Icon(
                  _obscureConfirmation
                      ? Icons.visibility_outlined
                      : Icons.visibility_off,
                  color: appMutedColor,
                  size: 17,
                ),
              ),
              validator: (value) => value != _password.text
                  ? 'Las contraseñas no coinciden.'
                  : null,
            ),
          ],
          SwitchListTile(
            value: _twoFactor,
            onChanged: (value) => setState(() => _twoFactor = value),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            activeThumbColor: appOrangeColor,
            title: const Text(
              'Solicitar verificación en dos pasos (2FA)',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
            subtitle: const Text(
              'La activación requiere configurar un segundo factor en Firebase Authentication.',
              style: TextStyle(color: appMutedColor, fontSize: 9),
            ),
            tileColor: appSurfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: appBorderColor),
            ),
          ),
          const SizedBox(height: 10),
          if (widget.initialInstitution == null)
            CheckboxListTile(
              value: _termsAccepted,
              onChanged: (value) =>
                  setState(() => _termsAccepted = value ?? false),
              contentPadding: EdgeInsets.zero,
              activeColor: appOrangeColor,
              title: Wrap(
                children: [
                  const Text(
                    'Acepto los ',
                    style: TextStyle(color: appMutedColor, fontSize: 9),
                  ),
                  InkWell(
                    onTap: () => showSimulatedLegalDialog(
                      context,
                      title: 'Términos y Condiciones',
                      body: simulatedTermsBody,
                    ),
                    child: const Text(
                      'Términos y Condiciones para Instituciones',
                      style: TextStyle(
                        color: appPurpleColor,
                        fontSize: 9,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text(
                    ' y la ',
                    style: TextStyle(color: appMutedColor, fontSize: 9),
                  ),
                  InkWell(
                    onTap: () => showSimulatedLegalDialog(
                      context,
                      title: 'Política de Privacidad',
                      body: simulatedPrivacyBody,
                    ),
                    child: const Text(
                      'Política de Privacidad de Datos Institucionales',
                      style: TextStyle(
                        color: appPurpleColor,
                        fontSize: 9,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text(
                    '.',
                    style: TextStyle(color: appMutedColor, fontSize: 9),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          _PrimaryAction(
            label: _busy
                ? 'Guardando institución...'
                : widget.initialInstitution == null
                ? 'Guardar Institución'
                : 'Guardar cambios',
            icon: Icons.check,
            busy: _busy,
            onPressed: _busy ? null : _save,
          ),
          if (!hasExistingUser && widget.initialInstitution == null) ...[
            TextButton(
              onPressed: widget.onSignIn,
              child: const Text(
                '¿Ya tienes una cuenta institucional? Iniciar sesión',
              ),
            ),
            if (Navigator.of(context).canPop())
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Volver al inicio de sesión'),
              ),
          ],
          if (editing && onBack != null)
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Volver al tablero'),
            ),
        ],
        ),
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    required String hint,
    bool required = false,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(label, required: required),
        _InstitutionInput(
          controller: controller,
          hint: hint,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          suffix: suffix,
          validator: validator,
        ),
      ],
    );
  }

  Widget _dropdown(
    String? value,
    List<String> options,
    ValueChanged<String> onChanged, {
    String? hint,
  }) {
    final uniqueOptions = options.toSet().toList();
    final selectedValue = value != null && uniqueOptions.contains(value)
        ? value
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        dropdownColor: appSurfaceColor,
        style: const TextStyle(color: Colors.white, fontSize: 11),
        decoration: _inputDecoration(hint ?? 'Selecciona una opción'),
        items: [
          for (final option in uniqueOptions)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        validator: (next) => next == null ? 'Selecciona una opción.' : null,
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }
}

class InstitutionDashboardScreen extends StatelessWidget {
  const InstitutionDashboardScreen({
    required this.institution,
    required this.authRepository,
    required this.repository,
    required this.onPublishCourse,
    required this.onEditCourse,
    required this.onEditInstitution,
    this.accountTab = false,
    super.key,
  });

  final Institution institution;
  final AuthRepository authRepository;
  final InstitutionRepository repository;
  final VoidCallback onPublishCourse;
  final ValueChanged<InstitutionCourse> onEditCourse;
  final VoidCallback onEditInstitution;
  final bool accountTab;

  Future<void> _retireCourse(
    BuildContext context,
    InstitutionCourse course,
  ) async {
    final shouldRetire = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appSurfaceColor,
        title: const Text('Retirar publicación'),
        content: Text(
          'El curso "${course.title}" dejará de aparecer en el catálogo público.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: appOrangeColor),
            child: const Text('Retirar curso'),
          ),
        ],
      ),
    );
    if (shouldRetire != true || !context.mounted) return;
    try {
      await repository.retireCourse(
        courseId: course.id,
        ownerUid: institution.uid,
      );
      if (context.mounted) {
        _showMessage(
          context,
          'El curso fue retirado del catálogo.',
          kind: AppMessageKind.success,
        );
      }
    } on StateError catch (error) {
      if (context.mounted) {
        _showMessage(context, error.message, kind: AppMessageKind.error);
      }
    } on Exception catch (error) {
      if (context.mounted) {
        _showMessage(
          context,
          authErrorMessage(error),
          kind: AppMessageKind.error,
        );
      }
    }
  }

  Future<void> _publishCourse(
    BuildContext context,
    InstitutionCourse course,
  ) async {
    final shouldPublish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appSurfaceColor,
        title: const Text('Publicar curso'),
        content: Text(
          'El borrador "${course.title}" pasará al catálogo público de CochaConecta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: appOrangeColor),
            child: const Text('Publicar ahora'),
          ),
        ],
      ),
    );
    if (shouldPublish != true || !context.mounted) return;
    try {
      await repository.publishCourse(
        courseId: course.id,
        ownerUid: institution.uid,
      );
      if (context.mounted) {
        _showMessage(
          context,
          'El curso se publicó en el catálogo.',
          kind: AppMessageKind.success,
        );
      }
    } on StateError catch (error) {
      if (context.mounted) {
        _showMessage(context, error.message, kind: AppMessageKind.error);
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(
          context,
          authErrorMessage(error),
          kind: AppMessageKind.error,
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await authRepository.signOut();
    } on Exception catch (error) {
      if (context.mounted) {
        _showMessage(
          context,
          authErrorMessage(error),
          kind: AppMessageKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final verified = institution.isVerified;
    return StreamBuilder<List<InstitutionCourse>>(
      stream: repository.watchInstitutionCourses(institution.uid),
      builder: (context, snapshot) {
        final courses = snapshot.data ?? const <InstitutionCourse>[];
        final drafts = courses
            .where((course) => course.status == 'draft')
            .toList();
        final publishedCourses = courses
            .where((course) => course.status == 'published')
            .toList();
        final retiredCourses = courses
            .where((course) => course.status == 'retired')
            .toList();
        final published = publishedCourses.length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            _InstitutionHeader(
              title: accountTab ? 'MI CUENTA' : 'MI INSTITUCIÓN',
              onBack: null,
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onEditInstitution,
                    icon: const Icon(Icons.settings_outlined),
                    color: appMutedColor,
                    tooltip: 'Editar perfil institucional',
                  ),
                  IconButton(
                    onPressed: () => _signOut(context),
                    icon: const Icon(Icons.logout),
                    color: Color(0xFFFF647C),
                    tooltip: 'Cerrar sesión',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _panelDecoration(),
              child: Column(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: appPurpleColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: appPurpleColor,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    institution.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${institution.city}, ${institution.country} · NIT: ${institution.taxId}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: appMutedColor, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  _VerificationBadge(verified: verified),
                  const Divider(color: appBorderColor, height: 28),
                  Row(
                    children: [
                      const Icon(
                        Icons.language,
                        color: appMutedColor,
                        size: 15,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Dominio institucional:',
                          style: TextStyle(color: appMutedColor, fontSize: 11),
                        ),
                      ),
                      Text(
                        institution.primaryDomain,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _signOut(context),
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Cerrar sesión'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF647C),
                        side: const BorderSide(color: appBorderColor),
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!accountTab) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: onPublishCourse,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Publicar nuevo curso o posgrado'),
                style: FilledButton.styleFrom(
                  backgroundColor: appOrangeColor,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (!verified) ...[
              const SizedBox(height: 10),
              const _Notice(
                title: 'VERIFICACIÓN PENDIENTE',
                text: 'Puedes preparar y guardar borradores. La publicación pública se habilitará cuando el dominio y la institución sean verificados por el servicio institucional.',
                color: appOrangeColor,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: _panelDecoration(),
              child: Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Cursos activos',
                      value: '$published',
                      detail: 'En oferta',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Metric(
                      label: 'Borradores',
                      value:
                          '${courses.where((c) => c.status == 'draft').length}',
                      detail: 'Privados',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'PROGRAMAS DE LA INSTITUCIÓN',
                    style: TextStyle(
                      color: Color(0xFFB48BF1),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  '${courses.length} total',
                  style: const TextStyle(color: appMutedColor, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 9),
            if (snapshot.hasError)
              _InlineNotice('No se pudieron cargar los cursos.')
            else if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: CircularProgressIndicator(color: appPurpleColor),
                ),
              )
            else if (courses.isEmpty)
              const _InlineNotice(
                'Aún no hay programas. Crea un curso para comenzar.',
              )
            else ...[
              if (drafts.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    'BORRADORES',
                    style: TextStyle(
                      color: appOrangeColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      fontSize: 11,
                    ),
                  ),
                ),
                for (final course in drafts)
                  _InstitutionCourseCard(
                    course: course,
                    onEdit: () => onEditCourse(course),
                    onPublish: () => _publishCourse(context, course),
                  ),
              ],
              if (publishedCourses.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    'PUBLICADOS EN EL CATÁLOGO',
                    style: TextStyle(
                      color: Color(0xFF4BD6A0),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      fontSize: 11,
                    ),
                  ),
                ),
                for (final course in publishedCourses)
                  _InstitutionCourseCard(
                    course: course,
                    onEdit: () => onEditCourse(course),
                    onRetire: () => _retireCourse(context, course),
                  ),
              ],
              if (retiredCourses.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    'RETIRADOS',
                    style: TextStyle(
                      color: appMutedColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      fontSize: 11,
                    ),
                  ),
                ),
                for (final course in retiredCourses)
                  _InstitutionCourseCard(
                    course: course,
                    onEdit: () => onEditCourse(course),
                  ),
              ],
            ],
            ],
          ],
        );
      },
    );
  }
}

class InstitutionCourseFormScreen extends StatefulWidget {
  const InstitutionCourseFormScreen({
    required this.institution,
    required this.repository,
    required this.onBack,
    this.initialCourse,
    super.key,
  });

  final Institution institution;
  final InstitutionRepository repository;
  final VoidCallback onBack;
  final InstitutionCourse? initialCourse;

  @override
  State<InstitutionCourseFormScreen> createState() =>
      _InstitutionCourseFormScreenState();
}

class _InstitutionCourseFormScreenState
    extends State<InstitutionCourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = _text('title');
  late final _duration = _text('duration');
  late final _description = _text('description');
  late final _seats = _text('totalSeats', fallback: '25');
  late final _totalCost = _text('totalCost');
  late final _paymentPlan = _text('paymentPlan');
  late final _discount = _text('earlyDiscount');
  late final _whatsApp = _text('whatsApp', fallback: widget.institution.phone);
  late final _admissionsEmail = _text(
    'admissionsEmail',
    fallback: widget.institution.contactEmail,
  );
  late String _programType = widget.initialCourse?.programType ?? 'Diplomado';
  late String _studyArea =
      widget.initialCourse?.studyArea ?? 'Tecnología y Software';
  late String _modality =
      widget.initialCourse?.modality ?? 'Online / Virtual (En vivo)';
  late String _minimumLevel =
      widget.initialCourse?.minimumLevel ?? 'Licenciatura / Grado';
  late String _currency = widget.initialCourse?.currency ?? 'BOB (Bs.)';
  late DateTime _publicationDate =
      widget.initialCourse?.publicationDate ?? DateTime.now();
  late DateTime _deadline =
      widget.initialCourse?.applicationDeadline ??
      DateTime.now().add(const Duration(days: 30));
  late DateTime _startDate =
      widget.initialCourse?.startDate ??
      DateTime.now().add(const Duration(days: 60));
  late final Set<String> _documents = {
    ...?widget.initialCourse?.requiredDocuments,
  };
  late bool _certification =
      widget.initialCourse?.includesCertification ?? false;
  PlatformFile? _brochure;
  bool _busy = false;

  static const _programTypes = [
    'Diplomado',
    'Maestría',
    'Curso continuo',
    'Curso corto',
    'Especialidad',
  ];
  static const _areas = [
    'Tecnología y Software',
    'Ciencias de la Salud',
    'Administración y Negocios',
    'Ingeniería',
    'Educación',
    'Derecho',
    'Idiomas',
    'Otro',
  ];
  static const _modalities = [
    'Online / Virtual (En vivo)',
    'Virtual (Asincrónico)',
    'Presencial',
    'Semipresencial',
  ];
  static const _levels = [
    'Bachillerato',
    'Técnico',
    'Licenciatura / Grado',
    'Posgrado',
    'No requiere',
  ];
  static const _currencies = ['BOB (Bs.)', 'USD (\$)'];
  static const _documentOptions = [
    'Currículum / CV',
    'Título en Provisión',
    'Cédula de Identidad',
    'Carta de Motivación',
  ];

  TextEditingController _text(String key, {String fallback = ''}) {
    final course = widget.initialCourse;
    final value = switch (key) {
      'title' => course?.title,
      'duration' => course?.duration,
      'description' => course?.description,
      'totalSeats' => course?.totalSeats.toString(),
      'totalCost' =>
        course?.totalCost == null ? null : _decimal(course!.totalCost),
      'paymentPlan' => course?.paymentPlan,
      'earlyDiscount' => course?.earlyDiscount,
      'whatsApp' => course?.whatsApp,
      'admissionsEmail' => course?.admissionsEmail,
      _ => null,
    };
    return TextEditingController(text: value ?? fallback);
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _duration,
      _description,
      _seats,
      _totalCost,
      _paymentPlan,
      _discount,
      _whatsApp,
      _admissionsEmail,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label es obligatorio.' : null;

  Future<void> _selectBrochure() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (!mounted || result.isEmpty) return;
      final file = result.single;
      final fileSize = await file.length();
      if (!mounted) return;
      if (fileSize != null && fileSize > 15 * 1024 * 1024) {
        _showMessage(
          context,
          'El PDF supera el límite de 15 MB.',
          kind: AppMessageKind.error,
        );
        return;
      }
      setState(() => _brochure = file);
    } on Exception catch (error) {
      if (mounted) {
        _showMessage(
          context,
          'No se pudo seleccionar el PDF. Inténtalo otra vez.',
          kind: AppMessageKind.error,
        );
      }
    }
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial.isBefore(DateTime.now()) ? DateTime.now() : initial,
    firstDate: DateTime(2020),
    lastDate: DateTime.now().add(const Duration(days: 3650)),
  );

  Future<void> _save({required bool publish}) async {
    if (_busy || !ensureFormValid(context, _formKey)) return;
    if (_deadline.isBefore(_publicationDate)) {
      _showMessage(
        context,
        'La fecha límite debe ser posterior a la publicación.',
        kind: AppMessageKind.error,
      );
      return;
    }
    if (_startDate.isBefore(_publicationDate)) {
      _showMessage(
        context,
        'El inicio de clases debe ser posterior a la publicación.',
        kind: AppMessageKind.error,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      if (publish && !simulateInstitutionVerification) {
        final user = FirebaseAuth.instance.currentUser;
        final claims = await user?.getIdTokenResult(true);
        if (!mounted) return;
        if (claims?.claims?['institution'] != true ||
            !widget.institution.isVerified) {
          _showMessage(
            context,
            'La institución debe verificar su dominio antes de publicar. Puedes guardar este curso como borrador.',
            kind: AppMessageKind.error,
          );
          return;
        }
      }

      final courseId =
          widget.initialCourse?.id ??
          FirebaseFirestore.instance.collection('courses').doc().id;
      String? brochureUrl = widget.initialCourse?.brochureUrl;
      if (_brochure != null && !simulateFileUploads) {
        final bytes = await _brochure!.readAsBytes();
        await FirebaseAuth.instance.currentUser?.getIdToken(true);
        final reference = FirebaseStorage.instance.ref().child(
          'institutions/${widget.institution.uid}/courses/$courseId/brochure.pdf',
        );
        final task = await reference.putData(
          bytes,
          SettableMetadata(contentType: 'application/pdf'),
        );
        brochureUrl = await task.ref.getDownloadURL();
      }
      final amount = double.tryParse(_totalCost.text.trim().replaceAll(',', '.'));
      final seats = int.tryParse(_seats.text.trim());
      if (amount == null || amount < 0) {
        _showMessage(
          context,
          'Indica un costo total numérico válido.',
          kind: AppMessageKind.error,
        );
        return;
      }
      if (seats == null || seats < 1) {
        _showMessage(
          context,
          'Indica una cantidad válida de cupos.',
          kind: AppMessageKind.error,
        );
        return;
      }
      final course = InstitutionCourse(
        id: courseId,
        ownerUid: widget.institution.uid,
        institutionName: widget.institution.displayName,
        institutionLocation:
            '${widget.institution.city}, ${widget.institution.country}',
        title: _title.text.trim(),
        programType: _programType,
        studyArea: _studyArea,
        modality: _modality,
        duration: _duration.text.trim(),
        description: _description.text.trim(),
        totalSeats: seats,
        minimumLevel: _minimumLevel,
        requiredDocuments: _documents.toList(),
        currency: _currency,
        totalCost: amount,
        paymentPlan: _paymentPlan.text.trim(),
        earlyDiscount: _discount.text.trim(),
        includesCertification: _certification,
        publicationDate: _publicationDate,
        applicationDeadline: _deadline,
        startDate: _startDate,
        whatsApp: _whatsApp.text.trim(),
        admissionsEmail: _admissionsEmail.text.trim(),
        brochureUrl: brochureUrl,
        status: publish ? 'published' : 'draft',
        createdAt: widget.initialCourse?.createdAt,
      );
      await widget.repository.saveCourse(course);
      if (!mounted) return;
      _showMessage(
        context,
        [
          if (publish)
            'Curso publicado correctamente.'
          else
            'Borrador guardado correctamente.',
          if (_brochure != null && simulateFileUploads)
            'El folleto se simuló y no se subió a Storage.',
        ].join(' '),
        kind: AppMessageKind.success,
      );
      widget.onBack();
    } on StateError catch (error) {
      if (mounted) {
        _showMessage(context, error.message, kind: AppMessageKind.error);
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          context,
          authErrorMessage(error),
          kind: AppMessageKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        _InstitutionHeader(
          title: 'PUBLICAR CURSO O PROGRAMA',
          onBack: widget.onBack,
        ),
        const SizedBox(height: 12),
        _InstitutionMiniCard(institution: widget.institution),
        const SizedBox(height: 16),
        const _SectionHeading('A. DATOS GENERALES DEL PROGRAMA'),
        _courseField(
          'Título o Nombre del Programa',
          _title,
          hint: 'Ej. Diplomado en Inteligencia Artificial y Machine Learning',
          required: true,
          validator: (value) {
            final required = _required(value, 'El título');
            if (required != null) return required;
            if (value!.trim().length > 100) {
              return 'Máximo 100 caracteres.';
            }
            return null;
          },
        ),
        Row(
          children: [
            Expanded(
              child: _choiceField(
                'Tipo de Programa',
                _programType,
                _programTypes,
                (value) => setState(() => _programType = value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _choiceField(
                'Área de Estudio',
                _studyArea,
                _areas,
                (value) => setState(() => _studyArea = value),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _choiceField(
                'Modalidad',
                _modality,
                _modalities,
                (value) => setState(() => _modality = value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _courseField(
                'Carga Horaria / Duración',
                _duration,
                hint: 'Ej. 180 horas (4 meses)',
                required: true,
                validator: (value) => _required(value, 'La duración'),
              ),
            ),
          ],
        ),
        _courseField(
          'Descripción y Temario Resumido',
          _description,
          hint: 'Describe los módulos principales, habilidades a desarrollar y a quién va dirigido este curso...',
          required: true,
          maxLines: 4,
          validator: (value) => _required(value, 'La descripción'),
        ),
        const Divider(color: appBorderColor, height: 28),
        const _SectionHeading('B. REQUISITOS Y CUPOS DE POSTULACIÓN'),
        Row(
          children: [
            Expanded(
              child: _courseField(
                'Cupos Totales',
                _seats,
                hint: '25 alumnos',
                required: true,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final seats = int.tryParse(value ?? '');
                  return seats == null || seats < 1
                      ? 'Indica un cupo válido.'
                      : null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _choiceField(
                'Nivel Mínimo',
                _minimumLevel,
                _levels,
                (value) => setState(() => _minimumLevel = value),
              ),
            ),
          ],
        ),
        const _FormLabel(
          'Documentos requeridos al postulante',
          required: false,
        ),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final document in _documentOptions)
              FilterChip(
                label: Text(document),
                selected: _documents.contains(document),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _documents.add(document);
                  } else {
                    _documents.remove(document);
                  }
                }),
                selectedColor: appOrangeColor.withValues(alpha: 0.24),
                checkmarkColor: appOrangeColor,
                labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
                backgroundColor: appSurfaceColor,
                side: const BorderSide(color: appBorderColor),
              ),
          ],
        ),
        const Divider(color: appBorderColor, height: 28),
        Row(
          children: [
            const Expanded(child: _SectionHeading('C. COSTO E INVERSIÓN')),
            const Text(
              'Transparente para alumnos',
              style: TextStyle(color: appMutedColor, fontSize: 8),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _choiceField(
                'Moneda',
                _currency,
                _currencies,
                (value) => setState(() => _currency = value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _courseField(
                'Monto de Inversión Total',
                _totalCost,
                hint: '2500',
                required: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  return amount == null || amount < 0
                      ? 'Ingresa un costo válido.'
                      : null;
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _courseField(
                'Planes de Pago',
                _paymentPlan,
                hint: 'Ej. Cuota inicial + 3 pagos',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _courseField(
                'Descuento Pronto Pago',
                _discount,
                hint: 'Ej. 10% hasta fin de mes',
              ),
            ),
          ],
        ),
        SwitchListTile(
          value: _certification,
          onChanged: (value) => setState(() => _certification = value),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          activeThumbColor: appOrangeColor,
          title: const Text(
            'Certificación Universitaria Incluida',
            style: TextStyle(color: Colors.white, fontSize: 11),
          ),
          subtitle: const Text(
            'Acreditado con resolución ministerial válida',
            style: TextStyle(color: appMutedColor, fontSize: 9),
          ),
          tileColor: appSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: appBorderColor),
          ),
        ),
        const Divider(color: appBorderColor, height: 28),
        const _SectionHeading('D. CRONOGRAMA Y VIGENCIA'),
        _DateField(
          label: 'Fecha de Publicación en la App',
          value: _publicationDate,
          onTap: () async {
            final value = await _pickDate(_publicationDate);
            if (value != null && mounted) {
              setState(() => _publicationDate = value);
            }
          },
        ),
        const _FieldHint(
          'A partir de esta fecha será visible en el catálogo de Cursos y Posgrados.',
        ),
        _DateField(
          label: 'Fecha de Expiración / Cierre de Convocatoria',
          value: _deadline,
          onTap: () async {
            final value = await _pickDate(_deadline);
            if (value != null && mounted) setState(() => _deadline = value);
          },
        ),
        const _FieldHint(
          'Al llegar esta fecha, el curso dejará de aceptar postulaciones automáticamente.',
        ),
        _DateField(
          label: 'Fecha de Inicio de Clases',
          value: _startDate,
          onTap: () async {
            final value = await _pickDate(_startDate);
            if (value != null && mounted) setState(() => _startDate = value);
          },
        ),
        const Divider(color: appBorderColor, height: 28),
        const _SectionHeading('E. SOPORTE Y CONSULTAS ACADÉMICAS'),
        Row(
          children: [
            Expanded(
              child: _courseField(
                'WhatsApp de Consultas',
                _whatsApp,
                hint: '+591 71234567',
                required: true,
                keyboardType: TextInputType.phone,
                validator: (value) => _required(value, 'El WhatsApp'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _courseField(
                'Correo de Admisiones',
                _admissionsEmail,
                hint: 'posgrado@umss.edu.bo',
                required: true,
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
            ),
          ],
        ),
        const _FormLabel(
          'Brochure o Programa Académico (PDF)',
          required: false,
        ),
        OutlinedButton.icon(
          onPressed: _selectBrochure,
          icon: const Icon(Icons.cloud_upload_outlined, color: appOrangeColor),
          label: Text(
            _brochure?.name ??
                'Subir convocatoria o plan de estudios · Máx. 15 MB',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(18),
            side: const BorderSide(color: appPurpleColor),
          ),
        ),
        const SizedBox(height: 16),
        const _Notice(
          title: 'PUBLICACIÓN',
          text: 'Los borradores quedan privados en tu tablero. Al publicar, el curso aparece en el catálogo de CochaConecta.',
        ),
        const SizedBox(height: 16),
        _PrimaryAction(
          label: _busy
              ? 'Guardando...'
              : widget.initialCourse == null
              ? 'Publicar Convocatoria Ahora'
              : 'Guardar cambios y publicar',
          icon: Icons.check,
          busy: _busy,
          onPressed: _busy ? null : () => _save(publish: true),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _save(publish: false),
          icon: const Icon(Icons.save_outlined, size: 17),
          label: const Text('Guardar como Borrador'),
          style: OutlinedButton.styleFrom(
            foregroundColor: appMutedColor,
            backgroundColor: appSurfaceColor,
            minimumSize: const Size.fromHeight(44),
            side: const BorderSide(color: appBorderColor),
          ),
        ),
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Volver al tablero'),
        ),
        ],
      ),
    ),
  );

  Widget _courseField(
    String label,
    TextEditingController controller, {
    required String hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FormLabel(label, required: required),
      _InstitutionInput(
        controller: controller,
        hint: hint,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
      ),
    ],
  );

  Widget _choiceField(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    final uniqueOptions = options.toSet().toList();
    final safeValue = uniqueOptions.contains(value)
        ? value
        : uniqueOptions.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(label, required: true),
        DropdownButtonFormField<String>(
          initialValue: safeValue,
          dropdownColor: appSurfaceColor,
          style: const TextStyle(color: Colors.white, fontSize: 10),
          decoration: _inputDecoration('Selecciona una opción'),
          items: [
            for (final option in uniqueOptions)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ],
    );
  }
}

class _InstitutionCourseCard extends StatelessWidget {
  const _InstitutionCourseCard({
    required this.course,
    required this.onEdit,
    this.onRetire,
    this.onPublish,
  });

  final InstitutionCourse course;
  final VoidCallback onEdit;
  final VoidCallback? onRetire;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    final isDraft = course.status == 'draft';
    final status = switch (course.status) {
      'published' => 'Publicado',
      'retired' => 'Retirado',
      _ => 'Borrador',
    };
    final statusColor = switch (course.status) {
      'published' => const Color(0xFF4BD6A0),
      'retired' => appMutedColor,
      _ => appOrangeColor,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDraft ? appOrangeColor.withValues(alpha: 0.55) : appBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  course.programType.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFB48BF1),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            course.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${course.modality} · ${course.totalSeats} cupos · ${course.currency} ${_decimal(course.totalCost)}',
            style: const TextStyle(color: appMutedColor, fontSize: 10),
          ),
          if (course.description.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              course.description.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: appMutedColor,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ],
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Editar'),
              ),
              if (onPublish != null)
                TextButton.icon(
                  onPressed: onPublish,
                  icon: const Icon(Icons.publish_outlined, size: 15),
                  label: const Text('Publicar'),
                  style: TextButton.styleFrom(foregroundColor: appOrangeColor),
                ),
              if (onRetire != null)
                TextButton.icon(
                  onPressed: onRetire,
                  icon: const Icon(Icons.remove_circle_outline, size: 15),
                  label: const Text('Retirar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InstitutionMiniCard extends StatelessWidget {
  const _InstitutionMiniCard({required this.institution});

  final Institution institution;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: _panelDecoration(),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: appBackgroundColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: appBorderColor),
          ),
          child: const Icon(Icons.school, color: appOrangeColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                institution.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                institution.isVerified
                    ? 'Institución verificada'
                    : 'Verificación pendiente',
                style: const TextStyle(color: appMutedColor, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InstitutionHeader extends StatelessWidget {
  const _InstitutionHeader({
    required this.title,
    required this.onBack,
    this.action,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (onBack != null)
        IconButton(
          onPressed: onBack,
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: appSurfaceColor,
            side: const BorderSide(color: appBorderColor),
            fixedSize: const Size(36, 36),
          ),
        )
      else
        const SizedBox(width: 36),
      Expanded(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFB48BF1),
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ),
      action ??
          SizedBox(
            width: 36,
            child: Icon(Icons.school_outlined, color: appPurpleColor, size: 19),
          ),
    ],
  );
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified ? const Color(0xFF23C990) : appOrangeColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        verified ? 'Institución Acreditada' : 'Verificación pendiente',
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
    decoration: BoxDecoration(
      color: appBackgroundColor.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: appBorderColor),
    ),
    child: Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: appMutedColor, fontSize: 9),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          detail,
          style: const TextStyle(color: Color(0xFF23C990), fontSize: 9),
        ),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.title,
    required this.text,
    this.color = appPurpleColor,
  });

  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: appSurfaceColor,
      borderRadius: BorderRadius.circular(11),
      border: Border(left: BorderSide(color: color, width: 3)),
    ),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: appMutedColor, fontSize: 9, height: 1.45),
        children: [
          TextSpan(
            text: '$title: ',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text),
        ],
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: appOrangeColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.label, {this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) => FormFieldLabel(
    label,
    required: required,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    ),
    padding: const EdgeInsets.only(top: 10, bottom: 5),
  );
}

class _FieldHint extends StatelessWidget {
  const _FieldHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 5),
    child: Text(
      text,
      style: const TextStyle(color: appMutedColor, fontSize: 8, height: 1.4),
    ),
  );
}

class _InstitutionInput extends StatelessWidget {
  const _InstitutionInput({
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      maxLines: obscureText ? 1 : maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 11),
      decoration: _inputDecoration(hint).copyWith(suffixIcon: suffix),
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FormLabel(label, required: true),
      OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.calendar_month_outlined, size: 15),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text('${value.month}/${value.day}/${value.year}'),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          side: const BorderSide(color: appBorderColor),
          backgroundColor: appSurfaceColor,
        ),
      ),
    ],
  );
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.busy,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: busy
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: appOrangeColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _InstitutionAccountMismatch extends StatelessWidget {
  const _InstitutionAccountMismatch({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_outlined,
            color: appOrangeColor,
            size: 36,
          ),
          const SizedBox(height: 12),
          const Text(
            'Esta cuenta no está registrada como institución.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Inicia sesión con una cuenta institucional independiente para '
            'evitar mezclar perfiles.',
            textAlign: TextAlign.center,
            style: TextStyle(color: appMutedColor, fontSize: 11),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              try {
                await onSignOut();
              } on Exception catch (error) {
                if (context.mounted) {
                  _showMessage(
                    context,
                    authErrorMessage(error),
                    kind: AppMessageKind.error,
                  );
                }
              }
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    ),
  );
}

class _InstitutionError extends StatelessWidget {
  const _InstitutionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: _panelDecoration(),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: appMutedColor, fontSize: 10),
    ),
  );
}

BoxDecoration _panelDecoration() => BoxDecoration(
  color: appSurfaceColor,
  borderRadius: BorderRadius.circular(15),
  border: Border.all(color: appBorderColor),
);

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: appMutedColor, fontSize: 10),
  filled: true,
  fillColor: appSurfaceColor,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: appBorderColor),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: appBorderColor),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: appPurpleColor),
  ),
);

String? _emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'El correo es obligatorio.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
    return 'Ingresa un correo válido.';
  }
  return null;
}

String? _websiteValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El sitio web es obligatorio.';
  }
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      !uri.hasAuthority ||
      !const ['http', 'https'].contains(uri.scheme)) {
    return 'Ingresa una URL completa con https://.';
  }
  return null;
}

String? _domainValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El dominio es obligatorio.';
  }
  final domain = _normalizeDomain(value);
  if (!RegExp(r'^(?=.{4,253}$)[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$')
          .hasMatch(domain) ||
      !domain.contains('.')) {
    return 'Ingresa un dominio válido, sin @ ni https://.';
  }
  return null;
}

String _normalizeDomain(String domain) => domain
    .trim()
    .toLowerCase()
    .replaceFirst(RegExp(r'^https?://'), '')
    .replaceAll(RegExp(r'/+$'), '');

String _emailDomain(String email) {
  final at = email.lastIndexOf('@');
  return at < 0 ? '' : _normalizeDomain(email.substring(at + 1));
}

String _decimal(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

void _showMessage(
  BuildContext context,
  String message, {
  AppMessageKind kind = AppMessageKind.info,
}) {
  showAppMessage(context, message, kind: kind);
}
