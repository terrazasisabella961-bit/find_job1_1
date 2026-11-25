import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/file_upload_mode.dart';
import '../config/simulated_cv.dart';
import '../models/user_profile.dart';
import '../services/auth_error_message.dart';
import '../services/auth_repository.dart';
import '../services/user_profile_repository.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/appearance_settings_card.dart';
import '../widgets/app_feedback.dart';
import 'user_registration_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    required this.authRepository,
    required this.profileRepository,
    required this.onBack,
    super.key,
  });

  final AuthRepository authRepository;
  final UserProfileRepository profileRepository;
  final VoidCallback onBack;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Future<UserProfile?> _profileFuture;
  bool _isSigningOut = false;
  bool _isUpdatingVisibility = false;

  User? get _user => widget.authRepository.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final uid = _user?.uid;
    _profileFuture = uid == null
        ? Future<UserProfile?>.value(null)
        : widget.profileRepository.getProfile(uid);
  }

  Future<void> _editProfile(UserProfile? profile) async {
    final user = _user;
    if (user == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => UserRegistrationScreen(
          authRepository: widget.authRepository,
          profileRepository: widget.profileRepository,
          initialProfile:
              profile ??
              UserProfile(
                uid: user.uid,
                fullName: user.displayName ?? '',
                email: user.email ?? '',
                phone: '',
                city: '',
                areaOfInterest: '',
              ),
          isEditing: true,
        ),
      ),
    );
    if (!mounted) return;
    setState(_loadProfile);
  }

  Future<void> _updateVisibility(UserProfile profile, bool isVisible) async {
    if (_isUpdatingVisibility) return;
    setState(() => _isUpdatingVisibility = true);
    try {
      await widget.profileRepository.updateVisibility(
        uid: profile.uid,
        isVisible: isVisible,
      );
      if (mounted) setState(_loadProfile);
    } on Exception catch (error) {
      if (mounted) {
        _showMessage(authErrorMessage(error), kind: AppMessageKind.error);
      }
    } finally {
      if (mounted) setState(() => _isUpdatingVisibility = false);
    }
  }

  Future<void> _openCv([UserProfile? profile]) async {
    if (simulateFileUploads) {
      await showSimulatedCvScreen(
        context,
        heading: 'Mi currículum',
        detail:
            'Como Storage no guarda archivos, se abre este CV de demostración.',
      );
      return;
    }
    final url = profile?.cvUrl;
    if (url == null || url.isEmpty) {
      _showMessage(
        (profile?.cvFileName ?? '').isEmpty
            ? 'Todavía no has cargado un currículum vitae.'
            : 'El CV "${profile?.cvFileName}" está simulado: no se guardó en Storage, así que no se puede abrir un enlace.',
      );
      return;
    }
    try {
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        if (mounted) _showMessage('No se pudo abrir el currículum vitae.');
      }
    } on Exception catch (error) {
      if (mounted) _showMessage('No se pudo abrir el currículum vitae: $error');
    }
  }

  Future<void> _sendVerification() async {
    final user = _user;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
      await user.reload();
      if (mounted) _showMessage('Se envió el correo de verificación.');
      if (mounted) setState(() {});
    } on Exception catch (error) {
      if (mounted) {
        _showMessage(authErrorMessage(error), kind: AppMessageKind.error);
      }
    }
  }

  Future<void> _changePassword() async {
    final email = _user?.email;
    if (email == null || email.isEmpty) {
      _showMessage('La cuenta no tiene un correo electrónico disponible.');
      return;
    }
    try {
      await widget.authRepository.sendPasswordResetEmail(email);
      if (mounted) {
        _showMessage('Se enviaron instrucciones para cambiar la contraseña.');
      }
    } on Exception catch (error) {
      if (mounted) {
        _showMessage(authErrorMessage(error), kind: AppMessageKind.error);
      }
    }
  }

  Future<void> _editEmail() async {
    final user = _user;
    final email = user?.email;
    if (user == null || email == null) return;
    final supportsPassword = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    if (!supportsPassword) {
      _showMessage(
        'El correo de esta cuenta se gestiona desde su proveedor de acceso.',
      );
      return;
    }

    final emailController = TextEditingController(text: email);
    final passwordController = TextEditingController();
    try {
      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: appSurfaceColor,
          title: Text(
            'Cambiar correo electrónico',
            style: TextStyle(color: appTextColor, fontSize: 14),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: appTextColor, fontSize: 12),
                decoration: InputDecoration(labelText: 'Nuevo correo'),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(color: appTextColor, fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('Continuar'),
            ),
          ],
        ),
      );
      if (shouldUpdate != true || !mounted) return;
      final newEmail = emailController.text.trim();
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(newEmail)) {
        _showMessage('Ingresa un correo electrónico válido.');
        return;
      }
      if (passwordController.text.isEmpty) {
        _showMessage('Ingresa tu contraseña actual para continuar.');
        return;
      }
      await widget.authRepository.updateEmail(
        currentPassword: passwordController.text,
        newEmail: newEmail,
      );
      if (mounted) {
        _showMessage('Confirma el cambio desde el enlace enviado a $newEmail.');
        setState(_loadProfile);
      }
    } on Exception catch (error) {
      if (mounted) {
        _showMessage(authErrorMessage(error), kind: AppMessageKind.error);
      }
    } finally {
      emailController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await widget.authRepository.signOut();
    } on Exception catch (error) {
      if (mounted) {
        _showMessage(authErrorMessage(error), kind: AppMessageKind.error);
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _showMessage(String message, {AppMessageKind kind = AppMessageKind.info}) {
    showAppMessage(context, message, kind: kind);
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return FutureBuilder<UserProfile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: appPurpleColor),
          );
        }
        if (snapshot.hasError) {
          return _AccountError(
            error: snapshot.error!,
            onRetry: () => setState(_loadProfile),
          );
        }

        final profile = snapshot.data;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          children: [
            _AccountHeader(
              onBack: widget.onBack,
              onSettings: () {
                if (profile != null) _editProfile(profile);
              },
            ),
            const SizedBox(height: 8),
            const AppearanceSettingsCard(),
            const SizedBox(height: 10),
            _IdentityCard(
              profile: profile,
              emailVerified: user?.emailVerified ?? false,
              onEdit: () => _editProfile(profile),
              onVerify: _sendVerification,
            ),
            const SizedBox(height: 10),
            _AccountStatusCard(
              isVisible: profile?.isVisible ?? false,
              isUpdating: _isUpdatingVisibility,
              cvFileName: simulateFileUploads
                  ? simulatedCvDisplayName
                  : profile?.cvFileName,
              onVisibilityChanged: profile == null
                  ? null
                  : (value) => _updateVisibility(profile, value),
              onEditCv: () => _editProfile(profile),
              onOpenCv: simulateFileUploads || profile != null
                  ? () => _openCv(profile)
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'DATOS PERSONALES Y PROFESIONALES',
                    style: TextStyle(
                      color: Color(0xFFB48BF1),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _editProfile(profile),
                  icon: Icon(Icons.edit_outlined, size: 10),
                  label: Text('Edición rápida'),
                  style: TextButton.styleFrom(
                    foregroundColor: appOrangeColor,
                    textStyle: TextStyle(fontSize: 7),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            _PersonalInfoTile(
              label: 'Correo electrónico',
              value: user?.email ?? 'No disponible',
              icon: Icons.mail_outline,
              onEdit: _editEmail,
            ),
            _PersonalInfoTile(
              label: 'Fecha de nacimiento',
              value: profile?.birthDate == null
                  ? 'No especificado'
                  : formatBirthDateDisplay(profile!.birthDate!),
              icon: Icons.cake_outlined,
              onEdit: () => _editProfile(profile),
            ),
            _PersonalInfoTile(
              label: 'Teléfono / WhatsApp',
              value: _nonEmpty(profile?.phone),
              icon: Icons.call_outlined,
              onEdit: () => _editProfile(profile),
            ),
            _PersonalInfoTile(
              label: 'Ciudad de residencia',
              value: _nonEmpty(profile?.city),
              icon: Icons.location_on_outlined,
              onEdit: () => _editProfile(profile),
            ),
            _PersonalInfoTile(
              label: 'Área profesional o de interés',
              value: _nonEmpty(profile?.areaOfInterest),
              icon: Icons.work_outline,
              onEdit: () => _editProfile(profile),
            ),
            _PersonalInfoTile(
              label: 'Nivel de estudios',
              value: _nonEmpty(profile?.educationLevel),
              icon: Icons.school_outlined,
              onEdit: () => _editProfile(profile),
            ),
            _PersonalInfoTile(
              label: 'Carrera o título',
              value: _nonEmpty(profile?.careerTitle),
              icon: Icons.badge_outlined,
              onEdit: () => _editProfile(profile),
            ),
            _PersonalInfoTile(
              label: 'Habilidades',
              value: _listOrEmpty(profile?.skills),
              icon: Icons.sell_outlined,
              onEdit: () => _editProfile(profile),
            ),
            _PersonalInfoTile(
              label: 'Idiomas',
              value: _languagesLabel(profile?.languages),
              icon: Icons.translate_outlined,
              onEdit: () => _editProfile(profile),
            ),
            _PersonalInfoTile(
              label: 'Sobre mí',
              value: _nonEmpty(profile?.aboutMe),
              icon: Icons.notes_outlined,
              onEdit: () => _editProfile(profile),
            ),
            _PasswordTile(onChange: _changePassword),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isSigningOut ? null : _signOut,
              icon: _isSigningOut
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : Icon(Icons.logout, size: 12),
              label: Text(
                _isSigningOut ? 'Cerrando sesión...' : 'Cerrar sesión',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: appOrangeColor,
                side: const BorderSide(color: Color(0xFF5D2C43)),
                backgroundColor: appSurfaceColor,
                textStyle: TextStyle(fontSize: 8),
              ),
            ),
          ],
        );
      },
    );
  }

  String _nonEmpty(String? value) {
    return value == null || value.isEmpty ? 'No especificado' : value;
  }

  String _listOrEmpty(List<String>? values) {
    if (values == null || values.isEmpty) return 'No especificado';
    return values.join(', ');
  }

  String _languagesLabel(List<ProfileLanguage>? languages) {
    if (languages == null || languages.isEmpty) return 'No especificado';
    return languages
        .map((language) => '${language.name} (${language.level})')
        .join(', ');
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.onBack, required this.onSettings});

  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Volver',
          onPressed: onBack,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'MI PERFIL',
                style: TextStyle(
                  color: Color(0xFFB48BF1),
                  fontSize: 7,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'MI CUENTA',
                style: TextStyle(
                  color: appTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _RoundIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Editar perfil',
          onPressed: onSettings,
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.profile,
    required this.emailVerified,
    required this.onEdit,
    required this.onVerify,
  });

  final UserProfile? profile;
  final bool emailVerified;
  final VoidCallback onEdit;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final name = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : 'Perfil profesional';
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final role = profile?.areaOfInterest.isNotEmpty == true
        ? profile!.areaOfInterest
        : 'Área profesional no especificada';
    final city = profile?.city.isNotEmpty == true
        ? profile!.city
        : 'Ciudad no especificada';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: appBorderColor),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF6535D4), Color(0xFF9C54DB)],
                  ),
                ),
                child: Text(
                  initials.isEmpty ? '?' : initials,
                  style: TextStyle(
                    color: appTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: appOrangeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit, size: 11, color: appTextColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: appTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                emailVerified ? Icons.verified : Icons.info_outline,
                color: emailVerified ? const Color(0xFF4BD6A0) : appMutedColor,
                size: 12,
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '$role • $city',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: appMutedColor, fontSize: 7),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _StatusChip(
                icon: emailVerified
                    ? Icons.check_circle
                    : Icons.mark_email_unread,
                label: emailVerified
                    ? 'Cuenta Verificada'
                    : 'Verifica tu cuenta',
                color: emailVerified
                    ? const Color(0xFF087D63)
                    : const Color(0xFF725129),
                onTap: emailVerified ? null : onVerify,
              ),
              _StatusChip(
                icon: Icons.edit,
                label: 'Editar perfil',
                color: appOrangeColor,
                onTap: onEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountStatusCard extends StatelessWidget {
  const _AccountStatusCard({
    required this.isVisible,
    required this.isUpdating,
    required this.cvFileName,
    required this.onVisibilityChanged,
    required this.onEditCv,
    required this.onOpenCv,
  });

  final bool isVisible;
  final bool isUpdating;
  final String? cvFileName;
  final ValueChanged<bool>? onVisibilityChanged;
  final VoidCallback onEditCv;
  final VoidCallback? onOpenCv;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: appBorderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ESTADOS DE LA CUENTA',
                  style: TextStyle(
                    color: Color(0xFFB48BF1),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                'Perfil personal',
                style: TextStyle(color: appMutedColor, fontSize: 6),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _StatusMetric(
                  title: 'Perfil en búsqueda',
                  value: isVisible ? 'Activo y visible' : 'Inactivo / oculto',
                  isVisible: isVisible,
                  isUpdating: isUpdating,
                  onChanged: onVisibilityChanged,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MetricCard(
                  title: 'Postulaciones',
                  value: 'Sin datos',
                  icon: Icons.send_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _CvCard(fileName: cvFileName, onEdit: onEditCv, onOpen: onOpenCv),
        ],
      ),
    );
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({
    required this.title,
    required this.value,
    required this.isVisible,
    required this.isUpdating,
    required this.onChanged,
  });

  final String title;
  final String value;
  final bool isVisible;
  final bool isUpdating;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: appBackgroundColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: appMutedColor, fontSize: 6),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isVisible ? const Color(0xFF4BD6A0) : appMutedColor,
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            height: 28,
            child: Center(
              child: isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: Switch(
                        value: isVisible,
                        onChanged: onChanged,
                        activeThumbColor: const Color(0xFF4BD6A0),
                        activeTrackColor: const Color(
                          0xFF4BD6A0,
                        ).withValues(alpha: 0.38),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: appBackgroundColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: appMutedColor, fontSize: 6),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(icon, color: appPurpleColor, size: 9),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(color: appTextColor, fontSize: 7),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CvCard extends StatelessWidget {
  const _CvCard({
    required this.fileName,
    required this.onEdit,
    required this.onOpen,
  });

  final String? fileName;
  final VoidCallback onEdit;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: appBackgroundColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF2D1E47),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.insert_drive_file_outlined,
              color: appPurpleColor,
              size: 14,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName ?? 'No se ha cargado un CV',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: appTextColor,
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    fileName == null
                        ? 'Selecciona Editar perfil para cargar tu CV'
                        : 'Archivo cargado · Toca para abrir',
                    style: TextStyle(color: appMutedColor, fontSize: 6),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, color: appOrangeColor),
            iconSize: 12,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 26, height: 26),
            tooltip: 'Cambiar CV',
          ),
        ],
      ),
    );
  }
}

class _PersonalInfoTile extends StatelessWidget {
  const _PersonalInfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onEdit,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 7, 5, 7),
      decoration: BoxDecoration(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: appBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: appMutedColor, fontSize: 6),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(icon, size: 9, color: appPurpleColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: appTextColor,
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, color: appMutedColor),
            iconSize: 12,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 26, height: 26),
            tooltip: 'Editar $label',
          ),
        ],
      ),
    );
  }
}

class _PasswordTile extends StatelessWidget {
  const _PasswordTile({required this.onChange});

  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 5, 7),
      decoration: BoxDecoration(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: appBorderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 10, color: appPurpleColor),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seguridad / Contraseña',
                  style: TextStyle(color: appMutedColor, fontSize: 6),
                ),
                SizedBox(height: 3),
                Text(
                  '••••••••••••',
                  style: TextStyle(color: appTextColor, fontSize: 8),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onChange,
            icon: Icon(Icons.edit_outlined, size: 9),
            label: Text('Cambiar'),
            style: TextButton.styleFrom(
              foregroundColor: appOrangeColor,
              textStyle: TextStyle(fontSize: 7),
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: appTextColor,
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    return onTap == null ? content : InkWell(onTap: onTap, child: content);
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: appPurpleColor,
      style: IconButton.styleFrom(
        backgroundColor: appSurfaceColor,
        side: BorderSide(color: appBorderColor),
        fixedSize: const Size(32, 32),
      ),
      tooltip: tooltip,
    );
  }
}

class _AccountError extends StatelessWidget {
  const _AccountError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No se pudo cargar el perfil. Tu sesión sigue activa. '
              'Comprueba la conexión y vuelve a intentarlo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: appTextColor, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: appMutedColor, fontSize: 9),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
