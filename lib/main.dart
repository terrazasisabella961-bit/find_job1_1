import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'src/screens/app_shell.dart';
import 'src/screens/institution_portal_screen.dart';
import 'src/screens/recruitment_screen.dart';
import 'src/screens/user_registration_screen.dart';
import 'src/services/auth_error_message.dart';
import 'src/services/auth_repository.dart';
import 'src/services/institution_repository.dart';
import 'src/services/recruitment_repository.dart';
import 'src/services/user_profile_repository.dart';
import 'src/widgets/app_bottom_navigation.dart';
import 'src/widgets/cocha_conecta_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    } on FirebaseException {
      // Keep the default persistence if the browser blocks IndexedDB.
    }
    runApp(const MyApp());
  } on FirebaseException catch (error) {
    runApp(_FirebaseStartupError(message: error.message ?? error.code));
  } on UnsupportedError catch (error) {
    runApp(_FirebaseStartupError(message: error.message ?? error.toString()));
  } on Exception catch (error) {
    runApp(_FirebaseStartupError(message: error.toString()));
  }
}

const _backgroundColor = Color(0xFF151226);
const _surfaceColor = Color(0xFF1A172F);
const _borderColor = Color(0xFF302B49);
const _mutedColor = Color(0xFFAAA6BE);
const _purpleColor = Color(0xFF8950F5);

class MyApp extends StatelessWidget {
  const MyApp({
    this.authRepository,
    this.profileRepository,
    this.recruitmentRepository,
    this.institutionRepository,
    super.key,
  });

  final AuthRepository? authRepository;
  final UserProfileRepository? profileRepository;
  final RecruitmentRepository? recruitmentRepository;
  final InstitutionRepository? institutionRepository;

  @override
  Widget build(BuildContext context) {
    final auth = authRepository ?? FirebaseAuthRepository();
    final profiles = profileRepository ?? FirebaseUserProfileRepository();
    final recruitment =
        recruitmentRepository ?? FirebaseRecruitmentRepository();
    final institutions =
        institutionRepository ?? FirebaseInstitutionRepository();
    return MaterialApp(
      title: 'CochaConecta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _purpleColor,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: _AuthGate(
        authRepository: auth,
        profileRepository: profiles,
        recruitmentRepository: recruitment,
        institutionRepository: institutions,
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({
    required this.authRepository,
    required this.profileRepository,
    required this.recruitmentRepository,
    required this.institutionRepository,
  });

  final AuthRepository authRepository;
  final UserProfileRepository profileRepository;
  final RecruitmentRepository recruitmentRepository;
  final InstitutionRepository institutionRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authRepository.authStateChanges,
      initialData: authRepository.currentUser,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _FirebaseStartupError(
            message: 'No se pudo comprobar la sesión: ${snapshot.error}',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: _purpleColor)),
          );
        }
        if (snapshot.data == null) {
          return LoginScreen(
            authRepository: authRepository,
            profileRepository: profileRepository,
            institutionRepository: institutionRepository,
            recruitmentRepository: recruitmentRepository,
          );
        }
        final user = snapshot.data!;
        return _AuthenticatedGate(
          user: user,
          authRepository: authRepository,
          profileRepository: profileRepository,
          recruitmentRepository: recruitmentRepository,
          institutionRepository: institutionRepository,
        );
      },
    );
  }
}

class _AuthenticatedGate extends StatelessWidget {
  const _AuthenticatedGate({
    required this.user,
    required this.authRepository,
    required this.profileRepository,
    required this.recruitmentRepository,
    required this.institutionRepository,
  });

  final User user;
  final AuthRepository authRepository;
  final UserProfileRepository profileRepository;
  final RecruitmentRepository recruitmentRepository;
  final InstitutionRepository institutionRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: recruitmentRepository.watchCompany(user.uid),
      builder: (context, companySnapshot) {
        if (companySnapshot.hasError &&
            !isRecoverableFirebaseAccessError(companySnapshot.error)) {
          return _FirebaseStartupError(
            message:
                'No se pudo comprobar la cuenta de empresa: '
                '${companySnapshot.error}',
          );
        }
        if (companySnapshot.connectionState == ConnectionState.waiting &&
            !companySnapshot.hasError) {
          return const _SessionLoading();
        }
        final company = companySnapshot.hasError ? null : companySnapshot.data;
        if (company != null) {
          return AppShell(
            authRepository: authRepository,
            profileRepository: profileRepository,
            recruitmentRepository: recruitmentRepository,
            institutionRepository: institutionRepository,
            initialSelectedIndex: 3,
            accountType: 'company',
          );
        }
        return StreamBuilder(
          stream: institutionRepository.watchInstitution(user.uid),
          builder: (context, institutionSnapshot) {
            if (institutionSnapshot.hasError &&
                !isRecoverableFirebaseAccessError(institutionSnapshot.error)) {
              return _FirebaseStartupError(
                message:
                    'No se pudo comprobar la cuenta institucional: '
                    '${institutionSnapshot.error}',
              );
            }
            if (institutionSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !institutionSnapshot.hasError) {
              return const _SessionLoading();
            }
            if (!institutionSnapshot.hasError &&
                institutionSnapshot.data != null) {
              return AppShell(
                authRepository: authRepository,
                profileRepository: profileRepository,
                recruitmentRepository: recruitmentRepository,
                institutionRepository: institutionRepository,
                initialSelectedIndex: 2,
                accountType: 'institution',
              );
            }
            return AppShell(
              authRepository: authRepository,
              profileRepository: profileRepository,
              recruitmentRepository: recruitmentRepository,
              institutionRepository: institutionRepository,
              initialSelectedIndex: 0,
              accountType: 'student',
            );
          },
        );
      },
    );
  }
}

class _SessionLoading extends StatelessWidget {
  const _SessionLoading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator(color: _purpleColor)),
  );
}

class _FirebaseStartupError extends StatelessWidget {
  const _FirebaseStartupError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo iniciar Firebase.\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.authRepository,
    required this.profileRepository,
    required this.institutionRepository,
    required this.recruitmentRepository,
    super.key,
  });

  final AuthRepository authRepository;
  final UserProfileRepository profileRepository;
  final InstitutionRepository institutionRepository;
  final RecruitmentRepository recruitmentRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showDemoMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: _surfaceColor),
      );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu correo electrónico.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.authRepository.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on Object catch (error) {
      if (mounted) _showDemoMessage(authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.authRepository.signInWithGoogle();
    } on Object catch (error) {
      if (mounted) _showDemoMessage(authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_validateEmail(_emailController.text) != null) {
      _showDemoMessage(
        'Escribe un correo válido para recuperar tu contraseña.',
      );
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.authRepository.sendPasswordResetEmail(_emailController.text);
      if (mounted) {
        _showDemoMessage(
          'Si existe una cuenta para ese correo, recibirás instrucciones para restablecer tu contraseña.',
        );
      }
    } on Exception catch (error) {
      if (mounted) _showDemoMessage(authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openRegistration() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UserRegistrationScreen(
          authRepository: widget.authRepository,
          profileRepository: widget.profileRepository,
        ),
      ),
    );
  }

  void _openInstitutions() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (pageContext) => InstitutionPortalScreen(
          authRepository: widget.authRepository,
          repository: widget.institutionRepository,
          onInstitutionReady: () {
            if (pageContext.mounted && Navigator.of(pageContext).canPop()) {
              Navigator.of(pageContext).pop();
            }
          },
        ),
      ),
    );
  }

  void _openCompanyPortal() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CompanyPortalScreen(
          authRepository: widget.authRepository,
          repository: widget.recruitmentRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CochaConectaLogo(height: 120),
                      const SizedBox(height: 8),
                      const Text(
                        'Empleo y formación en Cochabamba',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _mutedColor,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 22),
                      LoginTextField(
                        controller: _emailController,
                        hintText: 'Correo electrónico',
                        icon: Icons.mail,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 10),
                      LoginTextField(
                        controller: _passwordController,
                        hintText: 'Contraseña',
                        icon: Icons.lock,
                        obscureText: _obscurePassword,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Ingresa tu contraseña.'
                            : null,
                        onToggleVisibility: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: SizedBox(
                          width: 180,
                          height: 42,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _signIn,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF7845),
                              foregroundColor: const Color(0xFF171323),
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF171323),
                                    ),
                                  )
                                : const Text('Iniciar sesión'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: _mutedColor,
                            fontSize: 9,
                            height: 1.55,
                          ),
                          children: [
                            TextSpan(
                              text: 'Consejos: ',
                              style: TextStyle(
                                color: Color(0xFFFF7845),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'El correo electrónico debe ser una '
                                  'dirección de correo electrónico válida. '
                                  'El campo de contraseña no puede estar vacío.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: _borderColor, height: 1),
                      const SizedBox(height: 16),
                      const Text(
                        'O utilice las siguientes opciones para iniciar sesión o '
                        'registrarte con correo electrónico o restablecer la '
                        'contraseña de tu cuenta actual.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _mutedColor,
                          fontSize: 9,
                          height: 1.55,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isSubmitting ? null : _resetPassword,
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(color: _mutedColor, fontSize: 9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _signInWithGoogle,
                          icon: const Icon(Icons.android, size: 16),
                          label: const Text('Iniciar sesión con Android'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _purpleColor,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isSubmitting ? null : _openRegistration,
                        child: const Text(
                          '¿No tienes cuenta? Regístrate',
                          style: TextStyle(color: _mutedColor, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AppBottomNavigation(
              selectedIndex: 3,
              onSelected: (index) {
                if (index == 1) {
                  _openCompanyPortal();
                  return;
                }
                if (index == 2) {
                  _openInstitutions();
                } else {
                  _showDemoMessage(
                    'Inicia sesión para acceder a esta sección.',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onToggleVisibility,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(color: Colors.white, fontSize: 11),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: _mutedColor, fontSize: 10),
          prefixIcon: Icon(icon, color: _purpleColor, size: 16),
          suffixIcon: onToggleVisibility == null
              ? null
              : IconButton(
                  onPressed: onToggleVisibility,
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: _purpleColor,
                    size: 16,
                  ),
                  tooltip: obscureText
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                ),
          filled: true,
          fillColor: _surfaceColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          errorStyle: const TextStyle(fontSize: 8, height: 1.1),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: _borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: _purpleColor),
          ),
        ),
      ),
    );
  }
}
