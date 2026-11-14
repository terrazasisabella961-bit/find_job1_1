import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/company.dart';
import '../models/job_posting.dart';
import '../services/auth_error_message.dart';
import '../services/auth_repository.dart';
import '../services/recruitment_repository.dart';
import '../widgets/app_bottom_navigation.dart';

class CompanyPortalScreen extends StatefulWidget {
  const CompanyPortalScreen({
    required this.authRepository,
    required this.repository,
    super.key,
  });

  final AuthRepository authRepository;
  final RecruitmentRepository repository;

  @override
  State<CompanyPortalScreen> createState() => _CompanyPortalScreenState();
}

class _CompanyPortalScreenState extends State<CompanyPortalScreen> {
  bool _registering = false;
  bool _registrationInProgress = false;
  bool _didReturnToShell = false;
  String? _profileOwnerUid;
  String? _registrationError;

  @override
  Widget build(BuildContext context) {
    if (_profileOwnerUid != null) {
      final ownerUid = _profileOwnerUid!;
      return Scaffold(
        backgroundColor: appBackgroundColor,
        body: SafeArea(
          child: CompanyFormScreen(
            ownerUid: ownerUid,
            repository: widget.repository,
            authRepository: widget.authRepository,
            onCancel: () => setState(() => _profileOwnerUid = null),
            onSaved: (_) => setState(() => _profileOwnerUid = null),
          ),
        ),
      );
    }
    if (_registering || _registrationInProgress) {
      return Scaffold(
        backgroundColor: appBackgroundColor,
        body: SafeArea(
          child: CompanyFormScreen(
            repository: widget.repository,
            authRepository: widget.authRepository,
            onCancel: () => setState(() {
              _registering = false;
              _registrationError = null;
            }),
            onSaved: (_) => setState(() {
              _registering = false;
              _registrationInProgress = false;
              _registrationError = null;
            }),
            onRegistrationStarted: () =>
                setState(() => _registrationInProgress = true),
            onRegistrationFailed: (message) => setState(() {
              _registrationInProgress = false;
              _registering = widget.authRepository.currentUser != null;
              _registrationError = message;
            }),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: StreamBuilder(
          stream: widget.authRepository.authStateChanges,
          initialData: widget.authRepository.currentUser,
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              return _RecruitmentMessage(
                message:
                    'No se pudo comprobar la sesión: ${userSnapshot.error}',
              );
            }
            final user = userSnapshot.data;
            if (user == null) {
              return _CompanyLoginScreen(
                authRepository: widget.authRepository,
                errorMessage: _registrationError,
                onRegister: () => setState(() {
                  _registrationError = null;
                  _registering = true;
                }),
              );
            }
            return StreamBuilder<Company?>(
              stream: widget.repository.watchCompany(user.uid),
              builder: (context, companySnapshot) {
                if (companySnapshot.hasError) {
                  return _RecruitmentMessage(
                    message:
                        'No se pudo consultar la empresa: '
                        '${companySnapshot.error}',
                  );
                }
                if (companySnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: appPurpleColor),
                  );
                }
                if (companySnapshot.data == null) {
                  return _CompanyAccountMessage(
                    authRepository: widget.authRepository,
                    message: _registrationError ??
                        'La sesión se inició correctamente, pero no encontramos '
                            'un perfil de empresa vinculado a esta cuenta. '
                            'Completa el perfil para continuar.',
                    onCompleteProfile: () => setState(
                      () => _profileOwnerUid = user.uid,
                    ),
                  );
                }
                if (!_didReturnToShell) {
                  _didReturnToShell = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  });
                }
                return RecruitmentScreen(
                  ownerUid: user.uid,
                  repository: widget.repository,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CompanyLoginScreen extends StatefulWidget {
  const _CompanyLoginScreen({
    required this.authRepository,
    required this.errorMessage,
    required this.onRegister,
  });

  final AuthRepository authRepository;
  final String? errorMessage;
  final VoidCallback onRegister;

  @override
  State<_CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends State<_CompanyLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _taxId = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  bool _remember = false;

  @override
  void dispose() {
    _email.dispose();
    _taxId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.authRepository.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe primero un correo válido.')),
      );
      return;
    }
    try {
      await widget.authRepository.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Si existe una cuenta con ese correo, recibirás instrucciones para restablecer la contraseña.',
            ),
          ),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: [
      _PageHeader(
        eyebrow: 'CENTRO DE RECLUTAMIENTO',
        title: 'INICIAR SESIÓN EMPRESA',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      if (widget.errorMessage != null) ...[
        const SizedBox(height: 12),
        _NoticeCard(color: appOrangeColor, text: widget.errorMessage!),
      ],
      const SizedBox(height: 22),
      const _NoticeCard(
        color: appOrangeColor,
        text:
            'Acceso Corporativo y Reclutamiento. Ingresa con las credenciales '
            'de tu empresa para gestionar ofertas laborales y talentos.',
      ),
      const SizedBox(height: 10),
      const _NoticeCard(
        color: appOrangeColor,
        text: 'Acceso para reclutadores y empresas registradas.',
      ),
      const SizedBox(height: 20),
      Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionLabel('Correo electrónico corporativo / del reclutador'),
            _FormInput(
              controller: _email,
              hint: 'reclutamiento@empresa.bo',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null ||
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value.trim())) {
                  return 'Ingresa un correo corporativo válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 13),
            _SectionLabel('NIT o N° de Identificación Tributaria (Opcional)'),
            _FormInput(controller: _taxId, hint: 'Ej. 1023456028'),
            const SizedBox(height: 13),
            _SectionLabel('Contraseña corporativa'),
            _FormInput(
              controller: _password,
              hint: 'Contraseña',
              obscureText: _obscure,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off,
                  color: appMutedColor,
                  size: 17,
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Ingresa tu contraseña.'
                  : null,
            ),
            Row(
              children: [
                Checkbox(
                  value: _remember,
                  onChanged: (value) =>
                      setState(() => _remember = value ?? false),
                  activeColor: appOrangeColor,
                ),
                const Expanded(
                  child: Text(
                    'Recordar esta terminal',
                    style: TextStyle(color: appMutedColor, fontSize: 10),
                  ),
                ),
                TextButton(
                  onPressed: _resetPassword,
                  child: const Text('¿Olvidó su contraseña?'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _busy ? null : _signIn,
              style: FilledButton.styleFrom(
                backgroundColor: appOrangeColor,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(
                _busy ? 'Ingresando...' : 'Iniciar Sesión Corporativa  →',
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'O VERIFICAR ACCESO MEDIANTE',
                style: TextStyle(color: appMutedColor, fontSize: 10),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.business, size: 16),
              label: const Text(
                'Validar con Dominio Corporativo / SSO Empresarial',
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                onPressed: widget.onRegister,
                child: const Text('Registrar nueva empresa  ›'),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CompanyAccountMessage extends StatelessWidget {
  const _CompanyAccountMessage({
    required this.authRepository,
    required this.message,
    required this.onCompleteProfile,
  });

  final AuthRepository authRepository;
  final String message;
  final VoidCallback onCompleteProfile;

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
            style: const TextStyle(color: appMutedColor),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onCompleteProfile,
            child: const Text('Completar perfil de empresa'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              try {
                await authRepository.signOut();
              } on Exception catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(authErrorMessage(error))),
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

class RecruitmentScreen extends StatefulWidget {
  const RecruitmentScreen({
    required this.ownerUid,
    required this.repository,
    super.key,
  });

  final String ownerUid;
  final RecruitmentRepository repository;

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen> {
  Company? _companySavedThisSession;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Company?>(
      stream: widget.repository.watchCompany(widget.ownerUid),
      builder: (context, snapshot) {
        if (snapshot.hasError && _companySavedThisSession == null) {
          return _RecruitmentMessage(
            message: 'No se pudo consultar la empresa: ${snapshot.error}',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            _companySavedThisSession == null) {
          return const Center(
            child: CircularProgressIndicator(color: appPurpleColor),
          );
        }
        final company = snapshot.data ?? _companySavedThisSession;
        if (company == null) {
          return CompanyFormScreen(
            ownerUid: widget.ownerUid,
            repository: widget.repository,
            onSaved: (savedCompany) {
              if (mounted) {
                setState(() => _companySavedThisSession = savedCompany);
              }
            },
          );
        }
        if (company.ownerUid != widget.ownerUid) {
          return const _RecruitmentMessage(
            message: 'No tienes permiso para administrar esta empresa.',
          );
        }
        return _CompanyDashboard(
          company: company,
          repository: widget.repository,
        );
      },
    );
  }
}

class _CompanyDashboard extends StatelessWidget {
  const _CompanyDashboard({required this.company, required this.repository});

  final Company company;
  final RecruitmentRepository repository;

  Future<void> _editCompany(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: appBackgroundColor,
          body: SafeArea(
            child: CompanyFormScreen(
              ownerUid: company.ownerUid,
              repository: repository,
              initialCompany: company,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    String jobId,
    String status,
  ) async {
    try {
      await repository.updateJobStatus(jobId, status);
    } on Exception catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authErrorMessage(error)),
            backgroundColor: appSurfaceColor,
          ),
        );
      }
    }
  }

  Future<void> _openJobForm(BuildContext context, {JobPosting? job}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => JobFormScreen(
          company: company,
          repository: repository,
          initialJob: job,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JobPosting>>(
      stream: repository.watchCompanyJobs(company.ownerUid),
      builder: (context, snapshot) {
        final jobs = snapshot.data ?? const <JobPosting>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            const _PageHeader(
              eyebrow: 'CENTRO DE RECLUTAMIENTO',
              title: 'MI EMPRESA',
              onBack: null,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appSurfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: appBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: appBackgroundColor,
                        border: Border.all(color: appPurpleColor, width: 2),
                      ),
                      child: Text(
                        company.name.isEmpty
                            ? 'EMP'
                            : company.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: appPurpleColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      company.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Center(
                    child: Text(
                      '${company.city}, Bolivia · NIT: ${company.taxId}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: appMutedColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      const _CompanyStatusBadge(
                        label: 'Empresa registrada',
                        color: Color(0xFF23C990),
                      ),
                      TextButton.icon(
                        onPressed: () => _editCompany(context),
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text('Editar perfil'),
                      ),
                    ],
                  ),
                  const Divider(color: appBorderColor, height: 24),
                  Row(
                    children: [
                      const Icon(
                        Icons.language,
                        color: appMutedColor,
                        size: 15,
                      ),
                      const SizedBox(width: 7),
                      const Expanded(
                        child: Text(
                          'Sitio web:',
                          style: TextStyle(color: appMutedColor, fontSize: 10),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          company.website.isEmpty
                              ? 'No especificado'
                              : company.website,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openJobForm(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Publicar nuevo empleo o vacante'),
                      style: FilledButton.styleFrom(
                        backgroundColor: appOrangeColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'TUS OFERTAS LABORALES',
                    style: TextStyle(
                      color: Color(0xFFB48BF1),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  '${jobs.where((job) => job.status == 'published').length} activas',
                  style: const TextStyle(color: appMutedColor, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (snapshot.hasError)
              _InlineError(message: 'No se pudieron cargar las ofertas.')
            else if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: CircularProgressIndicator(color: appPurpleColor),
                ),
              )
            else if (jobs.isEmpty)
              _EmptyPanel(
                icon: Icons.work_outline,
                title: 'Aún no publicaste ofertas',
                message:
                    'Crea tu primera publicación para encontrar candidatos.',
                actionLabel: 'Crear primera oferta',
                onAction: () => _openJobForm(context),
              )
            else
              for (final job in jobs)
                _CompanyJobCard(
                  job: job,
                  onEdit: () => _openJobForm(context, job: job),
                  onStatusChanged: (status) =>
                      _changeStatus(context, job.id, status),
                ),
          ],
        );
      },
    );
  }
}

class CompanyFormScreen extends StatefulWidget {
  const CompanyFormScreen({
    required this.repository,
    this.ownerUid,
    this.authRepository,
    this.initialCompany,
    this.onSaved,
    this.onCancel,
    this.onRegistrationStarted,
    this.onRegistrationFailed,
    super.key,
  });

  final String? ownerUid;
  final RecruitmentRepository repository;
  final AuthRepository? authRepository;
  final Company? initialCompany;
  final ValueChanged<Company>? onSaved;
  final VoidCallback? onCancel;
  final VoidCallback? onRegistrationStarted;
  final ValueChanged<String>? onRegistrationFailed;

  @override
  State<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends State<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialCompany?.name);
  late final _taxId = TextEditingController(text: widget.initialCompany?.taxId);
  late final _sector = TextEditingController(
    text: widget.initialCompany?.sector,
  );
  late final _email = TextEditingController(
    text:
        widget.initialCompany?.email ??
        widget.authRepository?.currentUser?.email ??
        '',
  );
  late final _password = TextEditingController();
  late String _city = _cities.contains(widget.initialCompany?.city)
      ? widget.initialCompany!.city
      : 'Santa Cruz de la Sierra';
  late String _zone = _zones.contains(widget.initialCompany?.address)
      ? widget.initialCompany!.address
      : '';
  late final _website = TextEditingController(
    text: widget.initialCompany?.website,
  );
  bool _obscurePassword = true;
  bool _saving = false;

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
  static const _zones = [
    'Zona Norte',
    'Zona Sur',
    'Centro',
    'Zona Este',
    'Zona Oeste',
    'Otra',
  ];

  @override
  void dispose() {
    _name.dispose();
    _taxId.dispose();
    _sector.dispose();
    _email.dispose();
    _password.dispose();
    _website.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label es obligatorio.' : null;

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final auth = widget.authRepository;
      var ownerUid = widget.ownerUid;
      if (ownerUid == null) {
        final registrationAuth = auth;
        if (registrationAuth == null) {
          throw StateError('No se configuró la autenticación de empresas.');
        }
        widget.onRegistrationStarted?.call();
        final user =
            registrationAuth.currentUser ??
            (await registrationAuth.register(
              email: _email.text.trim(),
              password: _password.text,
            )).user;
        if (user == null) {
          throw StateError('Firebase no devolvió la cuenta de empresa.');
        }
        ownerUid = user.uid;
        if (user.email?.toLowerCase() != _email.text.trim().toLowerCase()) {
          throw StateError(
            'El correo de la empresa debe coincidir con la cuenta autenticada.',
          );
        }
      }
      final authenticatedUid = auth?.currentUser?.uid;
      if (authenticatedUid != null && authenticatedUid != ownerUid) {
        throw StateError(
          'La sesión actual no corresponde al UID de esta empresa.',
        );
      }
      final company = Company(
        id: ownerUid,
        ownerUid: ownerUid,
        name: _name.text.trim(),
        taxId: _taxId.text.trim(),
        sector: _sector.text.trim(),
        description: '',
        email: _email.text.trim(),
        phone: '',
        city: _city,
        address: _zone,
        website: _website.text.trim(),
      );
      await widget.repository.saveCompany(company);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La empresa se guardó correctamente.'),
            backgroundColor: appSurfaceColor,
          ),
        );
        if (widget.initialCompany == null) {
          widget.onSaved?.call(company);
        }
      }
    } on StateError catch (error) {
      if (widget.ownerUid == null) {
        widget.onRegistrationFailed?.call(error.message);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on Exception catch (error) {
      if (widget.ownerUid == null) {
        widget.onRegistrationFailed?.call(_companySaveErrorMessage(error));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_companySaveErrorMessage(error)),
            backgroundColor: appSurfaceColor,
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Company registration failed: $error\n$stackTrace');
      final message = _companySaveErrorMessage(error);
      if (widget.ownerUid == null) {
        widget.onRegistrationFailed?.call(message);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: appSurfaceColor),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _companySaveErrorMessage(Object error) {
    if (error is TimeoutException ||
        (error is FirebaseException && error.code == 'deadline-exceeded')) {
      return 'Firestore tardó demasiado en responder. Comprueba tu conexión e inténtalo de nuevo.';
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Firestore rechazó el perfil de empresa. Verifica la sesión y las reglas de companies/{uid}.';
    }
    return authErrorMessage(error);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialCompany != null;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          _PageHeader(
            eyebrow: 'CENTRO DE RECLUTAMIENTO',
            title: editing ? 'EDITAR EMPRESA' : 'REGISTRO DE EMPRESA',
            onBack: editing
                ? () => Navigator.of(context).pop()
                : widget.onCancel,
          ),
          const SizedBox(height: 18),
          Text(
            editing ? 'Actualizar empresa o entidad' : 'Registrar empresa',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Asocia tu empresa a tu perfil para publicar ofertas de empleo y buscar talento en tu región. Solo necesitas registrarla una vez.',
            style: TextStyle(color: appMutedColor, fontSize: 12, height: 1.45),
          ),
          const SizedBox(height: 16),
          _NoticeCard(
            color: appPurpleColor,
            text:
                'ADVERTENCIA: Si cambiaste de país o editaste tu perfil, '
                'actualiza los datos de tu empresa.',
          ),
          const SizedBox(height: 10),
          _NoticeCard(
            color: appOrangeColor,
            text:
                'ADVERTENCIA: Los datos ingresados están sujetos a '
                'verificación y deben ser legítimos.',
          ),
          const SizedBox(height: 18),
          _SectionLabel('Empresa o entidad'),
          _FormInput(
            controller: _name,
            hint: 'Empresa o entidad del puesto',
            validator: (value) => _required(value, 'El nombre de empresa'),
          ),
          const SizedBox(height: 12),
          _SectionLabel('Enlace del sitio web de empresa o entidad (Opcional)'),
          _FormInput(
            controller: _website,
            hint: 'https://...',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          _SectionLabel('Tu puesto o rol en la empresa'),
          _FormInput(
            controller: _sector,
            hint: 'Ej. Reclutador',
            validator: (value) => _required(value, 'El puesto o rol'),
          ),
          const _RecruitmentHint('Cargo o función en la empresa obligatorio.'),
          const SizedBox(height: 12),
          _SectionLabel('NIT de la empresa o No. de carnet de la entidad'),
          _FormInput(
            controller: _taxId,
            hint: 'NIT de la empresa o No. de carnet de la entidad',
            validator: (value) => _required(value, 'El NIT'),
          ),
          const _RecruitmentHint('Número de NIT o cédula jurídica válido.'),
          const SizedBox(height: 12),
          _SectionLabel('Ciudad de la empresa'),
          _DropdownField(
            value: _city,
            options: _cities,
            onChanged: (value) => setState(() => _city = value),
          ),
          const _RecruitmentHint(
            'Selecciona la ciudad donde reside la empresa.',
          ),
          const SizedBox(height: 12),
          _SectionLabel('Zona de la empresa'),
          _DropdownField(
            value: _zones.contains(_zone) ? _zone : _zones.first,
            options: _zones,
            onChanged: (value) => setState(() => _zone = value),
          ),
          const _RecruitmentHint(
            'Selecciona la zona o déjala como no especificada.',
          ),
          if (widget.ownerUid == null) ...[
            const SizedBox(height: 18),
            const _SectionLabel('Correo de acceso corporativo'),
            _FormInput(
              controller: _email,
              hint: 'reclutamiento@empresa.bo',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null ||
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value.trim())) {
                  return 'Ingresa un correo válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            const _SectionLabel('Contraseña corporativa'),
            _FormInput(
              controller: _password,
              hint: 'Mínimo 8 caracteres',
              obscureText: _obscurePassword,
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off,
                  color: appMutedColor,
                ),
              ),
              validator: (value) => value == null || value.length < 8
                  ? 'Usa al menos 8 caracteres.'
                  : null,
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(
              _saving
                  ? 'Guardando...'
                  : editing
                  ? 'Guardar cambios'
                  : 'Guardar',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: appOrangeColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          if (widget.ownerUid == null)
            Center(
              child: TextButton(
                onPressed: widget.onCancel,
                child: const Text('¿Ya registraste tu empresa? Iniciar sesión'),
              ),
            ),
        ],
      ),
    );
  }
}

class JobFormScreen extends StatefulWidget {
  const JobFormScreen({
    required this.company,
    required this.repository,
    this.initialJob,
    super.key,
  });

  final Company company;
  final RecruitmentRepository repository;
  final JobPosting? initialJob;

  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initialJob?.title);
  late final _description = TextEditingController(
    text: widget.initialJob?.description,
  );
  late final _area = TextEditingController(
    text: widget.initialJob?.area ?? 'Tecnología y Software',
  );
  late final _zone = TextEditingController(text: widget.initialJob?.zone);
  late final _city = TextEditingController(
    text: widget.initialJob?.city ?? widget.company.city,
  );
  late final _education = TextEditingController(
    text: widget.initialJob?.education ?? 'Licenciatura / Egresado',
  );
  late final _salaryMinimum = TextEditingController(
    text: widget.initialJob?.salaryMinimum?.toString(),
  );
  late final _salaryMaximum = TextEditingController(
    text: widget.initialJob?.salaryMaximum?.toString(),
  );
  late final _vacancies = TextEditingController(
    text: widget.initialJob?.vacancyCount.toString() ?? '1',
  );
  late final _skills = TextEditingController(
    text: widget.initialJob?.skills.join(', '),
  );
  late final _contactEmail = TextEditingController(
    text: widget.initialJob?.contactEmail ?? widget.company.email,
  );
  late final _whatsApp = TextEditingController(
    text: widget.initialJob?.whatsApp ?? widget.company.phone,
  );
  late String _modality = widget.initialJob?.modality ?? 'Presencial';
  late String _employmentType =
      widget.initialJob?.employmentType ?? 'Tiempo completo';
  late String _experience =
      widget.initialJob?.experience ?? 'Semi Senior (3-5 años)';
  late String _currency = widget.initialJob?.currency == 'USD'
      ? 'USD (\$)'
      : 'BOB (Bs.)';
  late String _applicationChannel =
      widget.initialJob?.applicationChannel ?? 'app';
  late DateTime? _deadline = widget.initialJob?.deadline;
  late DateTime _publicationDate =
      widget.initialJob?.publicationDate ?? DateTime.now();
  late final Set<String> _requiredDocuments =
      widget.initialJob?.requiredDocuments.toSet() ??
      {
        'Currículum Vitae (CV) actualizado',
        'Pretensión Salarial (Obligatoria)',
      };
  late final Set<String> _benefits =
      widget.initialJob?.benefits.toSet() ??
      {'Seguro de Salud Privado', 'Horario Flexible', 'Capacitación Pagada'};
  late bool _salaryConfidential =
      widget.initialJob?.salaryConfidential ?? false;
  bool _saving = false;

  static const _modalities = ['Presencial', 'Híbrida', 'Remota'];
  static const _employmentTypes = [
    'Tiempo completo',
    'Medio tiempo',
    'Temporal',
    'Prácticas',
    'Contrato',
  ];
  static const _experiences = [
    'Sin experiencia',
    'Junior (0-2 años)',
    'Semi Senior (3-5 años)',
    'Senior (+5 años)',
  ];
  static const _areas = [
    'Tecnología y Software',
    'Administración y Negocios',
    'Ingeniería',
    'Marketing y Comunicación',
    'Salud',
    'Educación',
    'Ventas',
    'Otra área',
  ];
  static const _educationLevels = [
    'Bachillerato',
    'Técnico',
    'Licenciatura / Egresado',
    'Postgrado',
  ];
  static const _documentOptions = [
    'Currículum Vitae (CV) actualizado',
    'Pretensión Salarial (Obligatoria)',
    'Título o Certificados académicos',
    'Portafolio de proyectos / Enlace GitHub',
    'Carta de presentación o motivación',
  ];
  static const _benefitOptions = [
    'Seguro de Salud Privado',
    'Horario Flexible',
    'Bono de Alimentación',
    'Capacitación Pagada',
  ];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _area.dispose();
    _zone.dispose();
    _city.dispose();
    _education.dispose();
    _salaryMinimum.dispose();
    _salaryMaximum.dispose();
    _vacancies.dispose();
    _skills.dispose();
    _contactEmail.dispose();
    _whatsApp.dispose();
    super.dispose();
  }

  Future<void> _choosePublicationDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _publicationDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null && mounted) {
      setState(() => _publicationDate = selected);
    }
  }

  Future<void> _chooseDeadline() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null && mounted) setState(() => _deadline = selected);
  }

  Future<void> _save({required bool publish}) async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final minimum = _parseSalary(_salaryMinimum.text);
    final maximum = _parseSalary(_salaryMaximum.text);
    if (minimum != null && maximum != null && minimum > maximum) {
      _showMessage('El salario mínimo no puede superar al máximo.');
      return;
    }
    if (_deadline != null &&
        _dateOnly(_deadline!).isBefore(_dateOnly(_publicationDate))) {
      _showMessage('La fecha límite debe ser posterior a la publicación.');
      return;
    }
    final vacancies = int.tryParse(_vacancies.text.trim());
    if (vacancies == null || vacancies < 1) {
      _showMessage('Indica una cantidad válida de vacantes.');
      return;
    }
    setState(() => _saving = true);
    try {
      final previous = widget.initialJob;
      await widget.repository.saveJob(
        JobPosting(
          id: previous?.id ?? '',
          companyId: widget.company.id,
          ownerUid: widget.company.ownerUid,
          companyName: widget.company.name,
          companySector: widget.company.sector,
          companyEmail: widget.company.email,
          companyPhone: widget.company.phone,
          companyWebsite: widget.company.website,
          companyAddress: '${widget.company.city}, ${_zone.text.trim()}',
          title: _title.text.trim(),
          description: _description.text.trim(),
          responsibilities: '',
          requirements: _requiredDocuments.join(', '),
          area: _area.text.trim(),
          city: _city.text.trim(),
          modality: _modality,
          employmentType: _employmentType,
          experience: _experience,
          education: _education.text.trim(),
          salaryMinimum: minimum,
          salaryMaximum: maximum,
          currency: _currency.startsWith('USD') ? 'USD' : 'BOB',
          createdAt: previous?.createdAt ?? DateTime.now(),
          deadline: _deadline,
          status: publish ? 'published' : 'draft',
          zone: _zone.text.trim(),
          requiredDocuments: _requiredDocuments.toList(),
          skills: _skills.text
              .split(',')
              .map((skill) => skill.trim())
              .where((skill) => skill.isNotEmpty)
              .toList(),
          salaryConfidential: _salaryConfidential,
          benefits: _benefits.toList(),
          publicationDate: _publicationDate,
          vacancyCount: vacancies,
          applicationChannel: _applicationChannel,
          contactEmail: _contactEmail.text.trim(),
          whatsApp: _whatsApp.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            publish
                ? previous == null
                      ? 'La oferta se publicó correctamente.'
                      : 'La oferta se actualizó correctamente.'
                : 'Borrador guardado correctamente.',
          ),
          backgroundColor: appSurfaceColor,
        ),
      );
      Navigator.of(context).pop();
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authErrorMessage(error)),
            backgroundColor: appSurfaceColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
    final editing = widget.initialJob != null;
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              _PageHeader(
                eyebrow: widget.company.name,
                title: editing
                    ? 'EDITAR EMPLEO O VACANTE'
                    : 'PUBLICAR EMPLEO O VACANTE',
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 12),
              _CompanyMiniCard(company: widget.company),
              const SizedBox(height: 12),
              const _NoticeCard(
                color: appOrangeColor,
                text:
                    'AVISO DE PUBLICACIÓN: Las ofertas registradas serán '
                    'indexadas de forma instantánea y notificadas a los '
                    'talentos postulantes compatibles según su perfil laboral.',
              ),
              const SizedBox(height: 14),
              const _FormSection('A. DATOS GENERALES DEL PUESTO'),
              _SectionLabel('Título del Puesto / Vacante'),
              _FormInput(
                controller: _title,
                hint: 'Ej. Desarrollador Full Stack Senior',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio.';
                  }
                  return value.trim().length > 80
                      ? 'Máximo 80 caracteres.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              _SectionLabel('Área o Departamento'),
              _DropdownField(
                value: _areas.contains(_area.text) ? _area.text : _areas.first,
                options: _areas,
                onChanged: (value) {
                  _area.text = value;
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              _SectionLabel('Tipo de Contrato'),
              _DropdownField(
                value: _employmentType,
                options: _employmentTypes,
                onChanged: (value) => setState(() => _employmentType = value),
              ),
              const SizedBox(height: 12),
              _SectionLabel('Modalidad de Trabajo'),
              _DropdownField(
                value: _modality,
                options: _modalities,
                onChanged: (value) => setState(() => _modality = value),
              ),
              const SizedBox(height: 12),
              _SectionLabel('Ciudad Sede'),
              _FormInput(
                controller: _city,
                hint: widget.company.city,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'La ciudad sede es obligatoria.'
                    : null,
              ),
              const SizedBox(height: 12),
              _SectionLabel('Zona o Dirección'),
              _FormInput(
                controller: _zone,
                hint: 'Ej. Equipetrol Norte, 4to anillo',
              ),
              const SizedBox(height: 12),
              _SectionLabel('Descripción y Responsabilidades'),
              _FormInput(
                controller: _description,
                hint: 'Detalla el objetivo principal del puesto, responsabilidades claves, funciones diarias y desafíos del rol...',
                maxLines: 5,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'La descripción es obligatoria.'
                    : null,
              ),
              const SizedBox(height: 16),
              const _FormSection('B. PERFIL Y REQUISITOS'),
              _SectionLabel('Nivel de Experiencia'),
              _DropdownField(
                value: _experiences.contains(_experience)
                    ? _experience
                    : _experiences.first,
                options: _experiences,
                onChanged: (value) => setState(() => _experience = value),
              ),
              const SizedBox(height: 12),
              _SectionLabel('Nivel Educativo Mínimo'),
              _DropdownField(
                value: _educationLevels.contains(_education.text)
                    ? _education.text
                    : _educationLevels.first,
                options: _educationLevels,
                onChanged: (value) {
                  _education.text = value;
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              const _SectionLabel('Requisitos Obligatorios al Postular'),
              for (final option in _documentOptions)
                _CheckOption(
                  label: option,
                  selected: _requiredDocuments.contains(option),
                  onChanged: (selected) => setState(() {
                    if (selected) {
                      _requiredDocuments.add(option);
                    } else {
                      _requiredDocuments.remove(option);
                    }
                  }),
                ),
              const SizedBox(height: 12),
              _SectionLabel('Habilidades / Skills Clave'),
              _FormInput(
                controller: _skills,
                hint: 'React.js, Node.js, TypeScript, PostgreSQL',
              ),
              const SizedBox(height: 16),
              const _FormSection('C. SALARIO Y BENEFICIOS'),
              const _SectionLabel('Rango Salarial Ofrecido'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DropdownField(
                      value: _currency,
                      options: const ['BOB (Bs.)', 'USD (\$)'],
                      onChanged: (value) => setState(() => _currency = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FormInput(
                      controller: _salaryMinimum,
                      hint: 'Min: 7.000',
                      keyboardType: TextInputType.number,
                      validator: _validateSalary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FormInput(
                      controller: _salaryMaximum,
                      hint: 'Max: 10.500',
                      keyboardType: TextInputType.number,
                      validator: _validateSalary,
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                value: _salaryConfidential,
                onChanged: (value) =>
                    setState(() => _salaryConfidential = value ?? false),
                contentPadding: EdgeInsets.zero,
                activeColor: appOrangeColor,
                title: const Text(
                  'Mantener remuneración como “A convenir / Confidencial”',
                  style: TextStyle(color: appMutedColor, fontSize: 10),
                ),
              ),
              const _SectionLabel('Beneficios Adicionales'),
              for (final option in _benefitOptions)
                _CheckOption(
                  label: option,
                  selected: _benefits.contains(option),
                  onChanged: (selected) => setState(() {
                    if (selected) {
                      _benefits.add(option);
                    } else {
                      _benefits.remove(option);
                    }
                  }),
                ),
              const SizedBox(height: 16),
              const _FormSection('D. CRONOGRAMA Y VACANTES'),
              const _SectionLabel('Fecha de Publicación'),
              OutlinedButton.icon(
                onPressed: _choosePublicationDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(_formatDate(_publicationDate)),
              ),
              const SizedBox(height: 12),
              const _SectionLabel('Cierre de Postulaciones'),
              OutlinedButton.icon(
                onPressed: _chooseDeadline,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  _deadline == null
                      ? 'Seleccionar fecha límite'
                      : _formatDate(_deadline!),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(14),
                  side: const BorderSide(color: appBorderColor),
                ),
              ),
              const SizedBox(height: 12),
              _SectionLabel('Cantidad de Vacantes Disponibles'),
              _FormInput(
                controller: _vacancies,
                hint: '2',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final count = int.tryParse(value ?? '');
                  return count == null || count < 1
                      ? 'Indica una cantidad válida.'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              const _FormSection('E. RECEPCIÓN DE POSTULACIONES'),
              const _SectionLabel('Canal Principal de Selección'),
              _RadioOption(
                label: 'Recepción Directa en la App',
                selected: _applicationChannel == 'app',
                onTap: () => setState(() => _applicationChannel = 'app'),
              ),
              _RadioOption(
                label: 'Postulación por Correo Electrónico',
                selected: _applicationChannel == 'email',
                onTap: () => setState(() => _applicationChannel = 'email'),
              ),
              const SizedBox(height: 10),
              _SectionLabel('Correo Electrónico de Talento Humano'),
              _FormInput(
                controller: _contactEmail,
                hint: 'talento@empresa.bo',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value.trim())) {
                    return 'Ingresa un correo de contacto válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _SectionLabel('WhatsApp para consultas rápidas (Opcional)'),
              _FormInput(
                controller: _whatsApp,
                hint: '+591 77012345',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : () => _save(publish: true),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _saving
                      ? 'Publicando...'
                      : editing
                      ? 'Actualizar convocatoria laboral'
                      : 'Publicar Convocatoria Laboral',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: appOrangeColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saving ? null : () => _save(publish: false),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar como Borrador'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String? _validateSalary(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (_parseSalary(value) == null || _parseSalary(value)! < 0) {
      return 'Ingresa un monto válido.';
    }
    return null;
  }

  int? _parseSalary(String value) =>
      int.tryParse(value.trim().replaceAll(RegExp(r'[.,\s]'), ''));

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class _CompanyJobCard extends StatelessWidget {
  const _CompanyJobCard({
    required this.job,
    required this.onEdit,
    required this.onStatusChanged,
  });

  final JobPosting job;
  final VoidCallback onEdit;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (job.status) {
      'published' => 'Publicada',
      'closed' => 'Cerrada',
      'draft' => 'Borrador',
      _ => 'Pausada',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: appBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(
                  color: job.status == 'published'
                      ? const Color(0xFF4BD6A0)
                      : appMutedColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${job.city} · ${job.modality} · ${job.employmentType}',
            style: const TextStyle(color: appMutedColor, fontSize: 11),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar'),
              ),
              if (job.status != 'closed')
                TextButton.icon(
                  onPressed: () => onStatusChanged(
                    job.status == 'published' ? 'paused' : 'published',
                  ),
                  icon: Icon(
                    job.status == 'published'
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    size: 16,
                  ),
                  label: Text(
                    job.status == 'published' ? 'Pausar' : 'Publicar',
                  ),
                ),
              if (job.status != 'closed')
                TextButton.icon(
                  onPressed: () => onStatusChanged('closed'),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cerrar'),
                  style: TextButton.styleFrom(foregroundColor: appOrangeColor),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.eyebrow,
    required this.title,
    required this.onBack,
  });

  final String eyebrow;
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: appSurfaceColor,
              fixedSize: const Size(40, 40),
            ),
          )
        else
          const SizedBox(width: 40),
        Expanded(
          child: Column(
            children: [
              Text(
                eyebrow.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB48BF1),
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
      ),
    );
  }
}

class _RecruitmentHint extends StatelessWidget {
  const _RecruitmentHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(color: appMutedColor, fontSize: 9),
    ),
  );
}

class _FormSection extends StatelessWidget {
  const _FormSection(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 15,
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
              color: appOrangeColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CompanyMiniCard extends StatelessWidget {
  const _CompanyMiniCard({required this.company});

  final Company company;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: appSurfaceColor,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: appBorderColor),
    ),
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
          child: Text(
            company.name.isEmpty ? 'EMP' : company.name.substring(0, 1),
            style: const TextStyle(
              color: appOrangeColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Publicando como ${company.sector}',
                style: const TextStyle(color: appMutedColor, fontSize: 9),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle, color: Color(0xFF23C990), size: 15),
      ],
    ),
  );
}

class _CompanyStatusBadge extends StatelessWidget {
  const _CompanyStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.55)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600),
    ),
  );
}

class _CheckOption extends StatelessWidget {
  const _CheckOption({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: selected,
    onChanged: (value) => onChanged(value ?? false),
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
    activeColor: appOrangeColor,
    title: Text(
      label,
      style: const TextStyle(color: appMutedColor, fontSize: 10),
    ),
    tileColor: appSurfaceColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9),
      side: const BorderSide(color: appBorderColor),
    ),
  );
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: selected ? appOrangeColor : appBorderColor),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? appOrangeColor : appMutedColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _FormInput extends StatelessWidget {
  const _FormInput({
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    maxLines: maxLines,
    obscureText: obscureText,
    style: const TextStyle(color: Colors.white, fontSize: 12),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: appMutedColor, fontSize: 11),
      filled: true,
      fillColor: appSurfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      suffixIcon: suffix,
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
    ),
  );
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    dropdownColor: appSurfaceColor,
    style: const TextStyle(color: Colors.white, fontSize: 12),
    decoration: InputDecoration(
      filled: true,
      fillColor: appSurfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: appBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: appBorderColor),
      ),
    ),
    items: [
      for (var index = 0; index < options.length; index++)
        DropdownMenuItem(value: options[index], child: Text(options[index])),
    ],
    onChanged: (next) {
      if (next != null) onChanged(next);
    },
  );
}

class _RecruitmentMessage extends StatelessWidget {
  const _RecruitmentMessage({required this.message});

  final String message;

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
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: appSurfaceColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: appBorderColor),
    ),
    child: Column(
      children: [
        Icon(icon, color: appPurpleColor, size: 32),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: appMutedColor, fontSize: 12),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Text(message, style: const TextStyle(color: appOrangeColor)),
  );
}
