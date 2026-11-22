import 'package:flutter/material.dart';

import '../config/file_upload_mode.dart';
import '../config/simulated_cv.dart';
import '../models/job_application.dart';
import '../models/job_posting.dart';
import '../models/user_profile.dart';
import '../services/auth_error_message.dart';
import '../services/job_application_repository.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/app_feedback.dart';

class JobApplicationFormScreen extends StatefulWidget {
  const JobApplicationFormScreen({
    required this.job,
    required this.profile,
    required this.repository,
    super.key,
  });

  final JobPosting job;
  final UserProfile profile;
  final JobApplicationRepository repository;

  @override
  State<JobApplicationFormScreen> createState() =>
      _JobApplicationFormScreenState();
}

class _JobApplicationFormScreenState extends State<JobApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: widget.profile.phone);
  final _message = TextEditingController();
  String _availability = 'Inmediata';
  bool _busy = false;

  static const _availabilityOptions = [
    'Inmediata',
    'En 15 días',
    'En 1 mes',
    'A convenir',
  ];

  @override
  void dispose() {
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !ensureFormValid(context, _formKey)) return;
    setState(() => _busy = true);
    try {
      final profile = widget.profile;
      await widget.repository.submitApplication(
        JobApplication(
          id: '${widget.job.id}_${profile.uid}',
          jobId: widget.job.id,
          companyId: widget.job.companyId,
          applicantUid: profile.uid,
          jobTitle: widget.job.title,
          companyName: widget.job.companyName,
          fullName: profile.fullName.trim(),
          email: profile.email.trim(),
          phone: _phone.text.trim(),
          city: profile.city.trim(),
          areaOfInterest: profile.areaOfInterest.trim(),
          educationLevel: profile.educationLevel.trim(),
          careerTitle: profile.careerTitle.trim(),
          skills: profile.skills,
          languages: [
            for (final language in profile.languages)
              if (language.name.trim().isNotEmpty)
                '${language.name.trim()} (${language.level})',
          ],
          aboutMe: profile.aboutMe.trim(),
          message: _message.text.trim(),
          availability: _availability,
          status: 'received',
          cvFileName: simulateFileUploads
              ? simulatedCvDisplayName
              : profile.cvFileName,
        ),
      );
      if (!mounted) return;
      showAppMessage(
        context,
        'Tu postulación se envió. La empresa ya puede ver tu ficha y CV.',
        kind: AppMessageKind.success,
      );
      if (simulateFileUploads) {
        await showSimulatedCvScreen(
          context,
          heading: 'Postulación enviada',
          detail:
              'Se ancló tu perfil y este currículum de demostración a '
              '"${widget.job.title}" en ${widget.job.companyName}.',
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on StateError catch (error) {
      if (mounted) {
        showAppMessage(context, error.message, kind: AppMessageKind.error);
      }
    } catch (error) {
      if (mounted) {
        showAppMessage(
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
    final profile = widget.profile;
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'POSTULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                widget.job.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.job.companyName,
                style: const TextStyle(color: appPurpleColor, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: appSurfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: appBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DATOS DE TU REGISTRO',
                      style: TextStyle(
                        color: Color(0xFFB48BF1),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Fact(label: 'Nombre', value: profile.fullName),
                    _Fact(label: 'Correo', value: profile.email),
                    _Fact(label: 'Ciudad', value: profile.city),
                    _Fact(label: 'Área', value: profile.areaOfInterest),
                    if (profile.educationLevel.isNotEmpty)
                      _Fact(label: 'Estudios', value: profile.educationLevel),
                    if (profile.careerTitle.isNotEmpty)
                      _Fact(label: 'Carrera', value: profile.careerTitle),
                    if (profile.skills.isNotEmpty)
                      _Fact(label: 'Habilidades', value: profile.skills.join(', ')),
                    if (profile.aboutMe.isNotEmpty)
                      _Fact(label: 'Sobre mí', value: profile.aboutMe),
                    _Fact(
                      label: 'CV',
                      value: simulateFileUploads
                          ? simulatedCvDisplayName
                          : (profile.cvFileName ?? 'Sin archivo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Teléfono de contacto',
                style: TextStyle(color: appMutedColor, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('Ej. +591 70000000'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'El teléfono es obligatorio.'
                    : null,
              ),
              const SizedBox(height: 12),
              const Text(
                'Disponibilidad',
                style: TextStyle(color: appMutedColor, fontSize: 12),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _availability,
                dropdownColor: appSurfaceColor,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: _decoration('Elige una opción'),
                items: [
                  for (final option in _availabilityOptions)
                    DropdownMenuItem(value: option, child: Text(option)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _availability = value);
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Mensaje para la empresa',
                style: TextStyle(color: appMutedColor, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _message,
                maxLines: 4,
                maxLength: 400,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration(
                  'Cuéntales por qué te interesa el puesto.',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 12) {
                    return 'Escribe al menos 12 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: const Icon(Icons.send_outlined),
                label: Text(_busy ? 'Enviando...' : 'Enviar postulación'),
                style: FilledButton.styleFrom(
                  backgroundColor: appOrangeColor,
                  foregroundColor: const Color(0xFF171323),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: appMutedColor, fontSize: 12),
    filled: true,
    fillColor: appSurfaceColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: appBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: appBorderColor),
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: appMutedColor, fontSize: 12),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
