import 'package:flutter/material.dart';

import '../models/job_posting.dart';
import '../services/recruitment_repository.dart';
import '../widgets/app_bottom_navigation.dart';

class EmploymentScreen extends StatefulWidget {
  const EmploymentScreen({
    required this.repository,
    required this.onOpenCatalog,
    super.key,
  });

  final RecruitmentRepository repository;
  final VoidCallback onOpenCatalog;

  @override
  State<EmploymentScreen> createState() => _EmploymentScreenState();
}

class _EmploymentScreenState extends State<EmploymentScreen> {
  final _searchController = TextEditingController();
  _JobFilters _filters = const _JobFilters();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters(List<JobPosting> jobs) async {
    final result = await showModalBottomSheet<_JobFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: appBackgroundColor,
      builder: (context) => _FiltersSheet(
        current: _filters,
        cities: _distinct(jobs.map((job) => job.city)),
        areas: _distinct(jobs.map((job) => job.area)),
        modalities: _distinct(jobs.map((job) => job.modality)),
        employmentTypes: _distinct(jobs.map((job) => job.employmentType)),
        experiences: _distinct(jobs.map((job) => job.experience)),
      ),
    );
    if (result != null && mounted) setState(() => _filters = result);
  }

  List<String> _distinct(Iterable<String> values) =>
      values
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  List<JobPosting> _filterJobs(List<JobPosting> jobs) {
    final query = _searchController.text.trim().toLowerCase();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return jobs.where((job) {
      if (job.deadline != null &&
          DateTime(
            job.deadline!.year,
            job.deadline!.month,
            job.deadline!.day,
          ).isBefore(todayDate)) {
        return false;
      }
      if (DateTime(
        job.publicationDate.year,
        job.publicationDate.month,
        job.publicationDate.day,
      ).isAfter(todayDate)) {
        return false;
      }
      final searchable = [
        job.title,
        job.companyName,
        job.description,
        job.responsibilities,
        job.requirements,
        job.area,
      ].join(' ').toLowerCase();
      if (query.isNotEmpty && !searchable.contains(query)) {
        return false;
      }
      if (_filters.city != null && job.city != _filters.city) {
        return false;
      }
      if (_filters.area != null && job.area != _filters.area) {
        return false;
      }
      if (_filters.modality != null && job.modality != _filters.modality) {
        return false;
      }
      if (_filters.employmentType != null &&
          job.employmentType != _filters.employmentType) {
        return false;
      }
      if (_filters.experience != null &&
          job.experience != _filters.experience) {
        return false;
      }
      if (_filters.onlyWithSalary && !job.hasSalary) {
        return false;
      }
      if (_filters.minimumSalary != null) {
        if (!job.hasSalary ||
            (job.salaryMaximum ?? job.salaryMinimum!) <
                _filters.minimumSalary!) {
          return false;
        }
      }
      if (_filters.maximumSalary != null) {
        if (!job.hasSalary ||
            (job.salaryMinimum ?? job.salaryMaximum!) >
                _filters.maximumSalary!) {
          return false;
        }
      }
      if (_filters.daysAgo != null &&
          job.createdAt.isBefore(
            DateTime.now().subtract(Duration(days: _filters.daysAgo!)),
          )) {
        return false;
      }
      return true;
    }).toList();
  }

  int get _activeFilterCount => _filters.activeCount;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JobPosting>>(
      stream: widget.repository.watchPublicJobs(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _JobsLoadError(
            message: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: appPurpleColor),
          );
        }
        final jobs = snapshot.data ?? const <JobPosting>[];
        final filteredJobs = _filterJobs(jobs);
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                children: [
                  const _JobsHeader(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Filtrar por ciudad o localidad',
                            hintStyle: const TextStyle(
                              color: appMutedColor,
                              fontSize: 11,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: appMutedColor,
                            ),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Borrar búsqueda',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color: appMutedColor,
                                    ),
                                  ),
                            filled: true,
                            fillColor: appSurfaceColor,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: appBorderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: appBorderColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _openFilters(jobs),
                        tooltip: 'Filtros',
                        icon: Badge(
                          isLabelVisible: _activeFilterCount > 0,
                          label: Text('$_activeFilterCount'),
                          child: const Icon(Icons.tune),
                        ),
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: appSurfaceColor,
                          side: const BorderSide(color: appBorderColor),
                          fixedSize: const Size(48, 48),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${filteredJobs.length} anuncios encontrados'
                    '${_activeFilterCount > 0 ? ' · $_activeFilterCount filtros' : ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (jobs.isEmpty)
                    const _EmptyJobs()
                  else if (filteredJobs.isEmpty)
                    _NoMatches(
                      onClear: () => setState(() {
                        _filters = const _JobFilters();
                        _searchController.clear();
                      }),
                    )
                  else
                    for (final job in filteredJobs)
                      _PublicJobCard(
                        job: job,
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => JobDetailsScreen(job: job),
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenCatalog,
                    icon: const Icon(Icons.school_outlined),
                    label: const Text('Ver cursos y posgrados'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: appPurpleColor,
                      side: const BorderSide(color: appBorderColor),
                    ),
                  ),
                ],
              ),
            ),
            if (_activeFilterCount > 0 || _searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _filters = const _JobFilters();
                      _searchController.clear();
                    }),
                    child: const Text('Limpiar búsqueda y filtros'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class JobDetailsScreen extends StatelessWidget {
  const JobDetailsScreen({required this.job, super.key});

  final JobPosting job;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: appSurfaceColor,
                    fixedSize: const Size(40, 40),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'DETALLE DE LA OFERTA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB48BF1),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              job.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              job.companyName,
              style: const TextStyle(color: appPurpleColor, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _Tag(Icons.location_on_outlined, job.city),
                _Tag(Icons.business_center_outlined, job.modality),
                _Tag(Icons.schedule, job.employmentType),
                _Tag(Icons.work_outline, job.area),
              ],
            ),
            if (job.salaryConfidential) ...[
              const SizedBox(height: 12),
              const _DetailText(
                title: 'Salario mensual',
                value: 'A convenir / Confidencial',
              ),
            ] else if (job.hasSalary) ...[
              const SizedBox(height: 12),
              _DetailText(title: 'Salario mensual', value: _salaryRange(job)),
            ],
            const SizedBox(height: 20),
            _DetailText(title: 'Descripción', value: job.description),
            if (job.responsibilities.isNotEmpty)
              _DetailText(
                title: 'Funciones y responsabilidades',
                value: job.responsibilities,
              ),
            if (job.requirements.isNotEmpty)
              _DetailText(title: 'Requisitos', value: job.requirements),
            if (job.experience.isNotEmpty)
              _DetailText(title: 'Experiencia', value: job.experience),
            if (job.education.isNotEmpty)
              _DetailText(title: 'Formación', value: job.education),
            if (job.requiredDocuments.isNotEmpty)
              _DetailText(
                title: 'Documentos para postular',
                value: job.requiredDocuments.join(', '),
              ),
            if (job.skills.isNotEmpty)
              _DetailText(title: 'Habilidades', value: job.skills.join(', ')),
            if (job.benefits.isNotEmpty)
              _DetailText(title: 'Beneficios', value: job.benefits.join(', ')),
            _DetailText(
              title: 'Vacantes disponibles',
              value: '${job.vacancyCount}',
            ),
            _DetailText(
              title: 'Postulación',
              value: job.applicationChannel == 'email'
                  ? 'Por correo electrónico'
                  : 'Directa en la app',
            ),
            _DetailText(
              title: 'Publicado',
              value:
                  '${job.createdAt.day}/${job.createdAt.month}/${job.createdAt.year}',
            ),
            if (job.deadline != null)
              _DetailText(
                title: 'Postular hasta',
                value:
                    '${job.deadline!.day}/${job.deadline!.month}/${job.deadline!.year}',
              ),
            const SizedBox(height: 10),
            const Text(
              'INFORMACIÓN PÚBLICA DE LA EMPRESA',
              style: TextStyle(
                color: Color(0xFFB48BF1),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            _DetailText(title: 'Empresa', value: job.companyName),
            if (job.companySector.isNotEmpty)
              _DetailText(title: 'Sector', value: job.companySector),
            if (job.companyAddress.isNotEmpty)
              _DetailText(title: 'Dirección', value: job.companyAddress),
            if (job.companyEmail.isNotEmpty)
              _DetailText(title: 'Correo', value: job.companyEmail),
            if (job.contactEmail.isNotEmpty)
              _DetailText(
                title: 'Correo de talento humano',
                value: job.contactEmail,
              ),
            if (job.whatsApp.isNotEmpty)
              _DetailText(title: 'WhatsApp', value: job.whatsApp),
            if (job.companyPhone.isNotEmpty)
              _DetailText(title: 'Teléfono', value: job.companyPhone),
            if (job.companyWebsite.isNotEmpty)
              _DetailText(title: 'Sitio web', value: job.companyWebsite),
          ],
        ),
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({
    required this.current,
    required this.cities,
    required this.areas,
    required this.modalities,
    required this.employmentTypes,
    required this.experiences,
  });

  final _JobFilters current;
  final List<String> cities;
  final List<String> areas;
  final List<String> modalities;
  final List<String> employmentTypes;
  final List<String> experiences;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String? _city = widget.current.city;
  late String? _area = widget.current.area;
  late String? _modality = widget.current.modality;
  late String? _employmentType = widget.current.employmentType;
  late String? _experience = widget.current.experience;
  late bool _onlyWithSalary = widget.current.onlyWithSalary;
  late final int? _minimumSalary = widget.current.minimumSalary;
  late final int? _maximumSalary = widget.current.maximumSalary;
  late int? _daysAgo = widget.current.daysAgo;
  final _minimumController = TextEditingController();
  final _maximumController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _minimumController.text = _minimumSalary?.toString() ?? '';
    _maximumController.text = _maximumSalary?.toString() ?? '';
  }

  @override
  void dispose() {
    _minimumController.dispose();
    _maximumController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String?>> _items(List<String> values) => [
    const DropdownMenuItem(value: null, child: Text('Todas')),
    for (final value in values)
      DropdownMenuItem(value: value, child: Text(value)),
  ];

  Widget _dropdown(
    String label,
    String? value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) {
    final validValue = value == null || values.contains(value) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String?>(
        initialValue: validValue,
        dropdownColor: appSurfaceColor,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: appMutedColor),
          filled: true,
          fillColor: appSurfaceColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: _items(values),
        onChanged: onChanged,
      ),
    );
  }

  int? _parsed(TextEditingController controller) {
    final value = controller.text.trim();
    if (value.isEmpty) return null;
    final parsed = int.tryParse(value);
    return parsed == null || parsed < 0 ? null : parsed;
  }

  void _apply() {
    final minimumInput = _minimumController.text.trim();
    final maximumInput = _maximumController.text.trim();
    final minimum = _parsed(_minimumController);
    final maximum = _parsed(_maximumController);
    if ((minimumInput.isNotEmpty && minimum == null) ||
        (maximumInput.isNotEmpty && maximum == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un rango salarial válido.')),
      );
      return;
    }
    if (minimum != null && maximum != null && minimum > maximum) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El salario mínimo no puede superar al máximo.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      _JobFilters(
        city: _city,
        area: _area,
        modality: _modality,
        employmentType: _employmentType,
        experience: _experience,
        onlyWithSalary: _onlyWithSalary || minimum != null || maximum != null,
        minimumSalary: minimum,
        maximumSalary: maximum,
        daysAgo: _daysAgo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Filtrar ofertas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _dropdown('Ciudad o ubicación', _city, widget.cities, (value) {
                setState(() => _city = value);
              }),
              _dropdown('Área profesional', _area, widget.areas, (value) {
                setState(() => _area = value);
              }),
              _dropdown('Modalidad', _modality, widget.modalities, (value) {
                setState(() => _modality = value);
              }),
              _dropdown(
                'Tipo de empleo',
                _employmentType,
                widget.employmentTypes,
                (value) => setState(() => _employmentType = value),
              ),
              _dropdown(
                'Experiencia',
                _experience,
                widget.experiences,
                (value) => setState(() => _experience = value),
              ),
              const Text(
                'Rango salarial mensual (BOB)',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SalaryField(
                      controller: _minimumController,
                      hint: 'Mínimo',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SalaryField(
                      controller: _maximumController,
                      hint: 'Máximo',
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _onlyWithSalary,
                onChanged: (value) => setState(() => _onlyWithSalary = value),
                title: const Text(
                  'Solo ofertas con salario publicado',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                activeThumbColor: const Color(0xFF4BD6A0),
              ),
              _dropdown(
                'Fecha de publicación',
                _daysAgo?.toString(),
                const ['7', '30'],
                (value) => setState(
                  () => _daysAgo = value == null ? null : int.parse(value),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(const _JobFilters()),
                      child: const Text('Limpiar filtros'),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: _apply,
                      style: FilledButton.styleFrom(
                        backgroundColor: appOrangeColor,
                      ),
                      child: const Text('Aplicar filtros'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalaryField extends StatelessWidget {
  const _SalaryField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    style: const TextStyle(color: Colors.white, fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: appMutedColor),
      filled: true,
      fillColor: appSurfaceColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class _JobFilters {
  const _JobFilters({
    this.city,
    this.area,
    this.modality,
    this.employmentType,
    this.experience,
    this.onlyWithSalary = false,
    this.minimumSalary,
    this.maximumSalary,
    this.daysAgo,
  });

  final String? city;
  final String? area;
  final String? modality;
  final String? employmentType;
  final String? experience;
  final bool onlyWithSalary;
  final int? minimumSalary;
  final int? maximumSalary;
  final int? daysAgo;

  int get activeCount =>
      [
        city,
        area,
        modality,
        employmentType,
        experience,
        daysAgo,
      ].where((value) => value != null).length +
      (minimumSalary != null || maximumSalary != null
          ? 1
          : onlyWithSalary
          ? 1
          : 0);
}

class _JobsHeader extends StatelessWidget {
  const _JobsHeader();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      SizedBox(width: 40),
      Expanded(
        child: Column(
          children: [
            Text(
              'OPORTUNIDADES PROFESIONALES',
              style: TextStyle(
                color: Color(0xFFB48BF1),
                fontSize: 9,
                letterSpacing: 0.7,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'ANUNCIOS DE EMPLEOS ACTIVOS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      SizedBox(width: 40),
    ],
  );
}

class _PublicJobCard extends StatelessWidget {
  const _PublicJobCard({required this.job, required this.onTap});

  final JobPosting job;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
        decoration: BoxDecoration(
          color: appSurfaceColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: appBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.work_outline, color: appPurpleColor, size: 15),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    job.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: appMutedColor,
                  size: 13,
                ),
              ],
            ),
            const Divider(color: appBorderColor, height: 17),
            Text(
              job.companyName.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _JobMetadata(icon: Icons.layers_outlined, text: job.area),
            _JobMetadata(
              icon: Icons.business_center_outlined,
              text: '${job.modality} · ${job.employmentType}',
            ),
            _JobMetadata(icon: Icons.location_on_outlined, text: job.city),
            _JobMetadata(
              icon: Icons.calendar_month_outlined,
              text:
                  'Publicado el ${job.createdAt.day}/${job.createdAt.month}/${job.createdAt.year}',
            ),
            if (job.salaryConfidential)
              const _JobMetadata(
                icon: Icons.payments_outlined,
                text: 'Salario a convenir',
              )
            else if (job.hasSalary)
              _JobMetadata(
                icon: Icons.payments_outlined,
                text: _salaryRange(job),
              ),
            _JobMetadata(
              icon: Icons.people_outline,
              text: '${job.vacancyCount} vacante(s) disponible(s)',
            ),
          ],
        ),
      ),
    );
  }
}

class _JobMetadata extends StatelessWidget {
  const _JobMetadata({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Icon(icon, color: appPurpleColor, size: 12),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: appMutedColor, fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: appSurfaceColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: appBorderColor),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: appPurpleColor, size: 13),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    ),
  );
}

class _DetailText extends StatelessWidget {
  const _DetailText({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFB48BF1),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            height: 1.4,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(12, 56, 12, 40),
    child: Column(
      children: [
        Icon(Icons.search_off, color: appPurpleColor, size: 38),
        SizedBox(height: 12),
        Text(
          'No hay ofertas activas por ahora',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Vuelve más tarde para consultar nuevas oportunidades.',
          textAlign: TextAlign.center,
          style: TextStyle(color: appMutedColor, fontSize: 12),
        ),
      ],
    ),
  );
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 48, 12, 32),
    child: Column(
      children: [
        const Icon(Icons.filter_alt_off, color: appPurpleColor, size: 34),
        const SizedBox(height: 10),
        const Text(
          'No encontramos coincidencias',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        const Text(
          'Prueba con otros términos o limpia los filtros.',
          textAlign: TextAlign.center,
          style: TextStyle(color: appMutedColor, fontSize: 12),
        ),
        TextButton(onPressed: onClear, child: const Text('Limpiar filtros')),
      ],
    ),
  );
}

class _JobsLoadError extends StatelessWidget {
  const _JobsLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, color: appOrangeColor, size: 32),
          const SizedBox(height: 10),
          const Text(
            'No se pudieron cargar las ofertas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: appMutedColor, fontSize: 11),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

String _formatSalary(int? value) {
  if (value == null) return 'Sin límite';
  final digits = value.toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) output.write('.');
    output.write(digits[index]);
  }
  return output.toString();
}

String _salaryRange(JobPosting job) =>
    '${_formatSalary(job.salaryMinimum)} – '
    '${_formatSalary(job.salaryMaximum)} ${job.currency}';
