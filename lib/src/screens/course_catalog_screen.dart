import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/institution_course.dart';
import '../services/institution_repository.dart';
import '../widgets/app_bottom_navigation.dart';

class CourseCatalogScreen extends StatefulWidget {
  const CourseCatalogScreen({
    required this.onOpenAccount,
    this.courseRepository,
    super.key,
  });

  final VoidCallback onOpenAccount;
  final InstitutionRepository? courseRepository;

  @override
  State<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'Todas';
  String _searchText = '';
  final Set<String> _savedPrograms = {};
  late final InstitutionRepository _courseRepository =
      widget.courseRepository ?? FirebaseInstitutionRepository();

  static const _categories = ['Todas', 'Diplomados', 'Maestrías', 'Cursos'];

  List<StudyProgram> _visiblePrograms(List<StudyProgram> available) {
    final query = _searchText.trim().toLowerCase();
    return available.where((program) {
      final matchesCategory =
          _selectedCategory == 'Todas' || program.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          program.title.toLowerCase().contains(query) ||
          program.institution.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSaved(StudyProgram program) {
    setState(() {
      if (!_savedPrograms.add(program.id)) {
        _savedPrograms.remove(program.id);
      }
    });
  }

  void _openProgram(StudyProgram program) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _ProgramDetailScreen(
          program: program,
          isSaved: _savedPrograms.contains(program.id),
          onToggleSaved: () => _toggleSaved(program),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InstitutionCourse>>(
      stream: _courseRepository.watchPublishedCourses(),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final livePrograms = (snapshot.data ?? const <InstitutionCourse>[])
            .where(
              (course) =>
                  course.status == 'published' &&
                  !DateTime(
                    course.publicationDate.year,
                    course.publicationDate.month,
                    course.publicationDate.day,
                  ).isAfter(today) &&
                  !DateTime(
                    course.applicationDeadline.year,
                    course.applicationDeadline.month,
                    course.applicationDeadline.day,
                  ).isBefore(today),
            )
            .map(_toStudyProgram)
            .toList();
        final programs = _visiblePrograms(livePrograms);
        return Column(
          children: [
            Expanded(
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _CatalogHeader(onOpenAccount: widget.onOpenAccount),
                        const SizedBox(height: 20),
                        _SearchField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _searchText = value),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _searchText = '');
                          },
                        ),
                        const SizedBox(height: 10),
                        _CategoryDropdown(
                          categories: _categories,
                          value: _selectedCategory,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCategory = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${programs.length} programas encontrados',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.info_outline,
                              color: appPurpleColor,
                              size: 13,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (snapshot.hasError)
                          const _CatalogLoadError()
                        else if (programs.isEmpty)
                          const _EmptyResults()
                        else
                          for (final program in programs) ...[
                            _ProgramCard(
                              program: program,
                              isSaved: _savedPrograms.contains(program.id),
                              onTap: () => _openProgram(program),
                              onSave: () => _toggleSaved(program),
                            ),
                            const SizedBox(height: 14),
                          ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  StudyProgram _toStudyProgram(InstitutionCourse course) {
    final category = switch (course.programType) {
      'Diplomado' || 'Especialidad' => 'Diplomados',
      'Maestría' => 'Maestrías',
      _ => 'Cursos',
    };
    final currency = course.currency.startsWith('USD') ? 'USD \$' : 'Bs.';
    return StudyProgram(
      id: course.id,
      title: course.title.toUpperCase(),
      institution: course.institutionName.toUpperCase(),
      category: category,
      modality: course.modality,
      duration: course.duration,
      location: course.institutionLocation,
      credential: course.includesCertification
          ? 'Certificación universitaria'
          : null,
      enrollment:
          'Inscripciones hasta el ${_formatDate(course.applicationDeadline)} · $currency ${course.totalCost}',
      description: course.description,
      totalSeats: course.totalSeats,
      investment: '$currency ${course.totalCost}',
      requiredDocuments: course.requiredDocuments,
      admissionsPhone: course.whatsApp,
      admissionsEmail: course.admissionsEmail,
      brochureUrl: course.brochureUrl,
    );
  }

  String _formatDate(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';
}

class _CatalogLoadError extends StatelessWidget {
  const _CatalogLoadError();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Text(
      'No se pudo actualizar la lista de cursos publicados. Inténtalo nuevamente más tarde.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white70, fontSize: 11),
    ),
  );
}

class StudyProgram {
  const StudyProgram({
    required this.id,
    required this.title,
    required this.institution,
    required this.category,
    required this.modality,
    required this.duration,
    required this.location,
    required this.enrollment,
    this.credential,
    this.description,
    this.totalSeats,
    this.investment,
    this.requiredDocuments = const [],
    this.admissionsPhone,
    this.admissionsEmail,
    this.brochureUrl,
  });

  final String id;
  final String title;
  final String institution;
  final String category;
  final String modality;
  final String duration;
  final String location;
  final String enrollment;
  final String? credential;
  final String? description;
  final int? totalSeats;
  final String? investment;
  final List<String> requiredDocuments;
  final String? admissionsPhone;
  final String? admissionsEmail;
  final String? brochureUrl;
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({required this.onOpenAccount});

  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: appSurfaceColor,
            shape: BoxShape.circle,
            border: Border.all(color: appBorderColor),
          ),
          child: Icon(
            Icons.school_outlined,
            color: appPurpleColor,
            size: 18,
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'CATÁLOGO DE',
                style: TextStyle(
                  color: appMutedColor,
                  fontSize: 9,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                'CURSOS Y POSGRADOS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB48BF1),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onOpenAccount,
          icon: Icon(Icons.person_outline),
          color: appPurpleColor,
          style: IconButton.styleFrom(
            backgroundColor: appSurfaceColor,
            side: BorderSide(color: appBorderColor),
            fixedSize: const Size(38, 38),
          ),
          tooltip: 'Abrir cuenta',
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: appTextColor, fontSize: 11),
        decoration: InputDecoration(
          hintText: 'Filtrar por categoría o institución',
          hintStyle: TextStyle(color: appMutedColor, fontSize: 10),
          prefixIcon: Icon(Icons.search, color: appPurpleColor, size: 17),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: Icon(Icons.close, size: 16),
                  tooltip: 'Limpiar búsqueda',
                ),
          filled: true,
          fillColor: appSurfaceColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: appBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: appPurpleColor),
          ),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<String> categories;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        onChanged: onChanged,
        dropdownColor: appSurfaceColor,
        iconEnabledColor: appPurpleColor,
        style: TextStyle(color: appTextColor, fontSize: 11),
        decoration: InputDecoration(
          labelText: 'Elige un área de estudio',
          labelStyle: TextStyle(color: appMutedColor, fontSize: 9),
          filled: true,
          fillColor: appSurfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 8,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: appBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: appPurpleColor),
          ),
        ),
        items: [
          for (final category in categories)
            DropdownMenuItem(value: category, child: Text(category)),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.isSaved,
    required this.onTap,
    required this.onSave,
  });

  final StudyProgram program;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: appSurfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: appBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProgramIcon(category: program.category),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      program.title,
                      style: TextStyle(
                        color: appTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onSave,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 30,
                      height: 30,
                    ),
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? appPurpleColor : appMutedColor,
                      size: 18,
                    ),
                    tooltip: isSaved
                        ? 'Quitar de guardados'
                        : 'Guardar programa',
                  ),
                ],
              ),
              const SizedBox(height: 9),
              _ProgramInfoRow(
                icon: Icons.account_balance_outlined,
                text: program.institution,
                color: const Color(0xFFE5E1EF),
                bold: true,
              ),
              const SizedBox(height: 6),
              _ProgramInfoRow(
                icon: Icons.desktop_windows_outlined,
                text: '${program.modality} • ${program.duration}',
                color: appMutedColor,
              ),
              if (program.credential != null) ...[
                const SizedBox(height: 6),
                _ProgramInfoRow(
                  icon: Icons.location_on_outlined,
                  text: '${program.credential} • ${program.location}',
                  color: appMutedColor,
                  iconColor: const Color(0xFFFF8C52),
                ),
              ] else ...[
                const SizedBox(height: 6),
                _ProgramInfoRow(
                  icon: Icons.location_on_outlined,
                  text: program.location,
                  color: appMutedColor,
                  iconColor: const Color(0xFFFF8C52),
                ),
              ],
              const SizedBox(height: 6),
              _ProgramInfoRow(
                icon: Icons.calendar_month_outlined,
                text: program.enrollment,
                color: program.category == 'Cursos'
                    ? const Color(0xFF4BD6A0)
                    : appMutedColor,
                iconColor: const Color(0xFF76A9FF),
              ),
              if (program.investment != null || program.totalSeats != null) ...[
                const SizedBox(height: 6),
                _ProgramInfoRow(
                  icon: Icons.payments_outlined,
                  text: [
                    if (program.investment != null) program.investment!,
                    if (program.totalSeats != null)
                      '${program.totalSeats} cupos',
                  ].join(' · '),
                  color: appMutedColor,
                ),
              ],
              const SizedBox(height: 9),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: appOrangeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: appTextColor,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramIcon extends StatelessWidget {
  const _ProgramIcon({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final icon = switch (category) {
      'Diplomados' => Icons.school_outlined,
      'Maestrías' => Icons.verified_user_outlined,
      _ => Icons.language,
    };
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: appBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorderColor),
      ),
      child: Icon(icon, color: appPurpleColor, size: 15),
    );
  }
}

class _ProgramInfoRow extends StatelessWidget {
  const _ProgramInfoRow({
    required this.icon,
    required this.text,
    required this.color,
    this.iconColor,
    this.bold = false,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color? iconColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor ?? appPurpleColor, size: 13),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              height: 1.35,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Icon(Icons.search_off, color: appMutedColor, size: 34),
          const SizedBox(height: 12),
          Text(
            'No hay cursos publicados que coincidan con tu búsqueda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: appMutedColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ProgramDetailScreen extends StatefulWidget {
  const _ProgramDetailScreen({
    required this.program,
    required this.isSaved,
    required this.onToggleSaved,
  });

  final StudyProgram program;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  @override
  State<_ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<_ProgramDetailScreen> {
  late bool _isSaved = widget.isSaved;

  void _toggleSaved() {
    widget.onToggleSaved();
    setState(() => _isSaved = !_isSaved);
  }

  Future<void> _openBrochure(String url) async {
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el folleto PDF.')),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el folleto PDF: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBackgroundColor,
        foregroundColor: Colors.white,
        title: Text(
          'DETALLE DEL PROGRAMA',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          IconButton(
            onPressed: _toggleSaved,
            tooltip: _isSaved ? 'Quitar de guardados' : 'Guardar programa',
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: appPurpleColor,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              program.title,
              style: TextStyle(
                color: appTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              program.institution,
              style: TextStyle(
                color: Color(0xFFB48BF1),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _DetailRow(label: 'Categoría', value: program.category),
            _DetailRow(
              label: 'Modalidad',
              value: '${program.modality} • ${program.duration}',
            ),
            _DetailRow(label: 'Ubicación', value: program.location),
            if (program.credential != null)
              _DetailRow(label: 'Certificación', value: program.credential!),
            _DetailRow(
              label: 'Inscripciones / inicio',
              value: program.enrollment,
            ),
            if (program.investment != null)
              _DetailRow(label: 'Inversión total', value: program.investment!),
            if (program.totalSeats != null)
              _DetailRow(
                label: 'Cupos disponibles',
                value: '${program.totalSeats}',
              ),
            if (program.description != null)
              _DetailRow(label: 'Descripción', value: program.description!),
            if (program.requiredDocuments.isNotEmpty)
              _DetailRow(
                label: 'Documentos requeridos',
                value: program.requiredDocuments.join(', '),
              ),
            if (program.admissionsPhone?.isNotEmpty == true)
              _DetailRow(
                label: 'WhatsApp de admisiones',
                value: program.admissionsPhone!,
              ),
            if (program.admissionsEmail?.isNotEmpty == true)
              _DetailRow(
                label: 'Correo de admisiones',
                value: program.admissionsEmail!,
              ),
            if (program.brochureUrl?.isNotEmpty == true)
              OutlinedButton.icon(
                onPressed: () => _openBrochure(program.brochureUrl!),
                icon: Icon(Icons.picture_as_pdf_outlined),
                label: Text('Abrir folleto PDF'),
              ),
            const SizedBox(height: 18),
            Text(
              'La información mostrada corresponde a los datos de la publicación institucional.',
              style: TextStyle(color: appMutedColor, fontSize: 11, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: appMutedColor, fontSize: 10),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(color: appTextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
