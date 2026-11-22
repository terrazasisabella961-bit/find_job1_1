import '../models/institution_course.dart';
import '../models/job_posting.dart';

final _published = DateTime(2026, 11, 10);
final _deadline = DateTime(2027, 2, 28);
final _start = DateTime(2027, 3, 9);

List<JobPosting> withDemoJobs(List<JobPosting> remote) {
  final ids = {for (final job in remote) job.id};
  return [
    ...remote,
    ...demoPublishedJobs.where((job) => !ids.contains(job.id)),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

List<InstitutionCourse> withDemoCourses(List<InstitutionCourse> remote) {
  final ids = {for (final course in remote) course.id};
  return [
    ...remote,
    ...demoPublishedCourses.where((course) => !ids.contains(course.id)),
  ]..sort((a, b) {
    final aDate = a.createdAt ?? DateTime(1970);
    final bDate = b.createdAt ?? DateTime(1970);
    return bDate.compareTo(aDate);
  });
}

final demoPublishedCourses = [
  InstitutionCourse(
    id: 'demo-course-fullstack',
    ownerUid: 'demo-institute-digital',
    institutionName: 'Instituto Digital Cochabamba',
    institutionLocation: 'Cochabamba, Bolivia',
    title: 'Desarrollo Web Full Stack',
    programType: 'Especialidad',
    studyArea: 'Tecnología y Software',
    modality: 'Online / Virtual (En vivo)',
    duration: '160 horas',
    description:
        'Formación práctica orientada al desarrollo de aplicaciones web modernas, utilizando tecnologías frontend y backend.\n\n'
        'Módulos:\n'
        '1. Fundamentos de HTML5, CSS3 y JavaScript.\n'
        '2. Desarrollo frontend con React.\n'
        '3. Programación backend con Node.js.\n'
        '4. Diseño y administración de bases de datos con PostgreSQL.\n'
        '5. Desarrollo de APIs REST.\n'
        '6. Despliegue de aplicaciones web.\n'
        '7. Proyecto integrador: desarrollo de una aplicación web.',
    totalSeats: 28,
    minimumLevel: 'Técnico',
    requiredDocuments: const [
      'Currículum / CV',
      'Cédula de identidad',
    ],
    currency: 'BOB (Bs.)',
    totalCost: 2800,
    paymentPlan: 'Contado o 3 cuotas',
    earlyDiscount: '10% hasta fin de mes',
    includesCertification: true,
    publicationDate: _published,
    applicationDeadline: _deadline,
    startDate: _start,
    whatsApp: '+591 70111222',
    admissionsEmail: 'admisiones@digitalcocha.edu.bo',
    brochureUrl: null,
    status: 'published',
    createdAt: _published,
  ),
  InstitutionCourse(
    id: 'demo-course-python-datos',
    ownerUid: 'demo-institute-datos',
    institutionName: 'Academia de Datos Andes',
    institutionLocation: 'Cochabamba, Bolivia',
    title: 'Análisis de Datos con Python',
    programType: 'Especialidad',
    studyArea: 'Tecnología y Software',
    modality: 'Online / Virtual (En vivo)',
    duration: '120 horas',
    description:
        'Curso orientado al análisis, procesamiento y visualización de datos mediante herramientas de programación, dirigido a estudiantes y profesionales interesados en la ciencia de datos.\n\n'
        'Módulos:\n'
        '1. Introducción a Python.\n'
        '2. Manipulación de datos con NumPy y Pandas.\n'
        '3. Limpieza y preparación de datos.\n'
        '4. Visualización con Matplotlib y Seaborn.\n'
        '5. Análisis estadístico descriptivo.\n'
        '6. Introducción al Machine Learning.\n'
        '7. Proyecto práctico de análisis de datos.',
    totalSeats: 24,
    minimumLevel: 'Técnico',
    requiredDocuments: const [
      'Currículum / CV',
      'Cédula de identidad',
    ],
    currency: 'BOB (Bs.)',
    totalCost: 2200,
    paymentPlan: 'Contado o 2 cuotas',
    earlyDiscount: '8% por pago anticipado',
    includesCertification: true,
    publicationDate: _published,
    applicationDeadline: _deadline,
    startDate: _start,
    whatsApp: '+591 70111333',
    admissionsEmail: 'admisiones@datosandes.edu.bo',
    brochureUrl: null,
    status: 'published',
    createdAt: _published.add(const Duration(hours: 2)),
  ),
  InstitutionCourse(
    id: 'demo-course-ambiental',
    ownerUid: 'demo-institute-tunari',
    institutionName: 'Centro de Estudios Ambientales Tunari',
    institutionLocation: 'Cochabamba, Bolivia',
    title: 'Gestión Ambiental y Desarrollo Sostenible',
    programType: 'Curso continuo',
    studyArea: 'Ingeniería',
    modality: 'Presencial',
    duration: '100 horas',
    description:
        'Programa enfocado en la gestión responsable de los recursos naturales, prevención de la contaminación y aplicación de estrategias de sostenibilidad ambiental.\n\n'
        'Módulos:\n'
        '1. Fundamentos del desarrollo sostenible.\n'
        '2. Legislación ambiental boliviana.\n'
        '3. Gestión integral de residuos sólidos.\n'
        '4. Evaluación de impacto ambiental.\n'
        '5. Gestión y conservación de recursos hídricos.\n'
        '6. Educación y responsabilidad ambiental.\n'
        '7. Elaboración de un plan de gestión ambiental.',
    totalSeats: 30,
    minimumLevel: 'Licenciatura / Grado',
    requiredDocuments: const [
      'Currículum / CV',
      'Título en Provisión',
      'Cédula de identidad',
    ],
    currency: 'BOB (Bs.)',
    totalCost: 1500,
    paymentPlan: 'Contado',
    earlyDiscount: '',
    includesCertification: true,
    publicationDate: _published,
    applicationDeadline: _deadline,
    startDate: _start,
    whatsApp: '+591 70111444',
    admissionsEmail: 'admisiones@tunariambiental.edu.bo',
    brochureUrl: null,
    status: 'published',
    createdAt: _published.add(const Duration(hours: 4)),
  ),
  InstitutionCourse(
    id: 'demo-course-uxui',
    ownerUid: 'demo-institute-diseno',
    institutionName: 'Escuela de Diseño Interactivo',
    institutionLocation: 'Cochabamba, Bolivia',
    title: 'Diseño UX/UI y Prototipado Digital',
    programType: 'Especialidad',
    studyArea: 'Tecnología y Software',
    modality: 'Online / Virtual (En vivo)',
    duration: '90 horas',
    description:
        'Formación enfocada en el diseño de experiencias digitales, investigación de usuarios y creación de interfaces intuitivas para aplicaciones web y móviles.\n\n'
        'Módulos:\n'
        '1. Introducción al diseño UX/UI.\n'
        '2. Investigación y análisis de usuarios.\n'
        '3. Arquitectura de información.\n'
        '4. Wireframes y prototipado.\n'
        '5. Diseño de interfaces en Figma.\n'
        '6. Sistemas de diseño y componentes.\n'
        '7. Pruebas de usabilidad y validación.',
    totalSeats: 22,
    minimumLevel: 'Bachillerato',
    requiredDocuments: const [
      'Currículum / CV',
      'Portafolio',
    ],
    currency: 'BOB (Bs.)',
    totalCost: 1800,
    paymentPlan: 'Contado o 2 cuotas',
    earlyDiscount: '10% hasta fin de mes',
    includesCertification: true,
    publicationDate: _published,
    applicationDeadline: _deadline,
    startDate: _start,
    whatsApp: '+591 70111555',
    admissionsEmail: 'admisiones@disenointeractivo.edu.bo',
    brochureUrl: null,
    status: 'published',
    createdAt: _published.add(const Duration(hours: 6)),
  ),
  InstitutionCourse(
    id: 'demo-course-marketing',
    ownerUid: 'demo-institute-negocios',
    institutionName: 'Instituto de Negocios del Valle',
    institutionLocation: 'Cochabamba, Bolivia',
    title: 'Marketing Digital y Comercio Electrónico',
    programType: 'Diplomado',
    studyArea: 'Administración y Negocios',
    modality: 'Online / Virtual (En vivo)',
    duration: '200 horas',
    description:
        'Programa orientado al desarrollo de estrategias digitales para promocionar productos, gestionar marcas y mejorar la presencia comercial de empresas en plataformas digitales.\n\n'
        'Módulos:\n'
        '1. Fundamentos del marketing digital.\n'
        '2. Gestión de redes sociales.\n'
        '3. Creación de contenido digital.\n'
        '4. Publicidad en Meta Ads y Google Ads.\n'
        '5. Posicionamiento SEO y SEM.\n'
        '6. Comercio electrónico y ventas online.\n'
        '7. Analítica digital e indicadores de rendimiento.\n'
        '8. Proyecto integrador de marketing.',
    totalSeats: 35,
    minimumLevel: 'Licenciatura / Grado',
    requiredDocuments: const [
      'Currículum / CV',
      'Cédula de identidad',
      'Carta de motivación',
    ],
    currency: 'BOB (Bs.)',
    totalCost: 3500,
    paymentPlan: 'Cuota inicial + 3 pagos',
    earlyDiscount: '12% por pronto pago',
    includesCertification: true,
    publicationDate: _published,
    applicationDeadline: _deadline,
    startDate: _start,
    whatsApp: '+591 70111666',
    admissionsEmail: 'admisiones@negociosvalle.edu.bo',
    brochureUrl: null,
    status: 'published',
    createdAt: _published.add(const Duration(hours: 8)),
  ),
];

final demoPublishedJobs = [
  _job(
    id: 'demo-job-ambiental',
    companyId: 'demo-company-ecoandes',
    companyName: 'EcoAndes Consultores',
    companySector: 'Consultoría ambiental',
    companyEmail: 'empleos@ecoandes.bo',
    companyPhone: '+591 4441122',
    companyWebsite: 'https://ecoandes.bo',
    companyAddress: 'Av. Heroínas 1420, Cochabamba',
    title: 'Ingeniero/a Ambiental',
    description:
        'Empresa consultora busca un Ingeniero Ambiental para participar en proyectos de gestión ambiental, evaluación de impactos y seguimiento de medidas de mitigación.',
    responsibilities:
        '- Elaborar informes de evaluación ambiental.\n'
        '- Realizar monitoreos de agua, aire y suelo.\n'
        '- Supervisar planes de gestión ambiental.\n'
        '- Gestionar residuos sólidos.\n'
        '- Verificar el cumplimiento de normativa ambiental.',
    requirements:
        '- Licenciatura en Ingeniería Ambiental.\n'
        '- Experiencia mínima de 1 año.\n'
        '- Conocimientos de legislación ambiental.\n'
        '- Manejo de Excel y QGIS.',
    area: 'Ingeniería',
    modality: 'Presencial',
    employmentType: 'Tiempo completo',
    experience: 'Junior (0-2 años)',
    education: 'Licenciatura / Egresado',
    salaryMinimum: 4500,
    salaryMaximum: 5500,
    skills: const ['QGIS', 'Excel', 'Legislación ambiental'],
    hours: 1,
  ),
  _job(
    id: 'demo-job-backend',
    companyId: 'demo-company-nexotech',
    companyName: 'NexoTech Solutions',
    companySector: 'Tecnología',
    companyEmail: 'talento@nexotech.bo',
    companyPhone: '+591 4442233',
    companyWebsite: 'https://nexotech.bo',
    companyAddress: 'Calle España 312, Cochabamba',
    title: 'Desarrollador Backend Junior',
    description:
        'Empresa tecnológica busca un desarrollador backend para formar parte de su equipo de desarrollo de aplicaciones y servicios digitales.',
    responsibilities:
        '- Desarrollar servicios y APIs REST.\n'
        '- Implementar lógica de negocio.\n'
        '- Diseñar y mantener bases de datos.\n'
        '- Corregir errores y optimizar código.\n'
        '- Documentar funcionalidades desarrolladas.',
    requirements:
        '- Formación en Ingeniería de Sistemas o Informática.\n'
        '- Conocimientos de Node.js y JavaScript.\n'
        '- Manejo de PostgreSQL.\n'
        '- Conocimientos de Git y GitHub.\n'
        '- Experiencia mínima de 6 meses (deseable).',
    area: 'Tecnología y Software',
    modality: 'Híbrida',
    employmentType: 'Tiempo completo',
    experience: 'Junior (0-2 años)',
    education: 'Licenciatura / Egresado',
    salaryMinimum: 3500,
    salaryMaximum: 4500,
    skills: const ['Node.js', 'JavaScript', 'PostgreSQL', 'Git'],
    requiredDocuments: const [
      'Currículum Vitae (CV) actualizado',
      'Portafolio de proyectos / Enlace GitHub',
    ],
    hours: 2,
  ),
  _job(
    id: 'demo-job-datos',
    companyId: 'demo-company-datavision',
    companyName: 'DataVision Bolivia',
    companySector: 'Analítica y software',
    companyEmail: 'rrhh@datavision.bo',
    companyPhone: '+591 4443344',
    companyWebsite: 'https://datavision.bo',
    companyAddress: 'Av. Blanco Galindo km 2, Cochabamba',
    title: 'Analista de Datos',
    description:
        'Se requiere un profesional encargado de analizar información empresarial, generar indicadores y elaborar reportes que faciliten la toma de decisiones.',
    responsibilities:
        '- Recopilar y procesar conjuntos de datos.\n'
        '- Elaborar dashboards e informes.\n'
        '- Identificar tendencias y patrones.\n'
        '- Automatizar reportes.\n'
        '- Presentar resultados a diferentes áreas.',
    requirements:
        '- Ingeniería de Sistemas, Estadística o ramas afines.\n'
        '- Manejo de Python y SQL.\n'
        '- Conocimientos de Power BI.\n'
        '- Excel intermedio o avanzado.\n'
        '- Capacidad analítica.',
    area: 'Tecnología y Software',
    modality: 'Remota',
    employmentType: 'Tiempo completo',
    experience: 'Junior (0-2 años)',
    education: 'Licenciatura / Egresado',
    salaryMinimum: 4000,
    salaryMaximum: 5000,
    skills: const ['Python', 'SQL', 'Power BI', 'Excel'],
    hours: 3,
  ),
  _job(
    id: 'demo-job-uxui',
    companyId: 'demo-company-pixel',
    companyName: 'Pixel Creative Studio',
    companySector: 'Diseño y publicidad',
    companyEmail: 'hola@pixelcreative.bo',
    companyPhone: '+591 4444455',
    companyWebsite: 'https://pixelcreative.bo',
    companyAddress: 'Calle 25 de Mayo 210, Cochabamba',
    title: 'Diseñador/a UX/UI',
    description:
        'Estudio creativo busca un diseñador UX/UI para desarrollar experiencias digitales atractivas, funcionales y centradas en las necesidades de los usuarios.',
    responsibilities:
        '- Diseñar interfaces para aplicaciones web y móviles.\n'
        '- Elaborar wireframes y prototipos.\n'
        '- Realizar investigaciones de usuarios.\n'
        '- Crear componentes y sistemas de diseño.\n'
        '- Participar en pruebas de usabilidad.',
    requirements:
        '- Formación en Diseño Gráfico, Sistemas o áreas afines.\n'
        '- Dominio de Figma.\n'
        '- Conocimientos de UX Research.\n'
        '- Manejo de herramientas de prototipado.\n'
        '- Portafolio de proyectos.',
    area: 'Marketing y Comunicación',
    modality: 'Híbrida',
    employmentType: 'Medio tiempo',
    experience: 'Junior (0-2 años)',
    education: 'Técnico',
    salaryMinimum: 2500,
    salaryMaximum: 3200,
    skills: const ['Figma', 'UX Research', 'Prototipado'],
    requiredDocuments: const [
      'Currículum Vitae (CV) actualizado',
      'Portafolio de proyectos / Enlace GitHub',
    ],
    hours: 4,
  ),
  _job(
    id: 'demo-job-rrhh',
    companyId: 'demo-company-andino',
    companyName: 'Grupo Empresarial Andino',
    companySector: 'Comercio',
    companyEmail: 'talento@grupoandino.bo',
    companyPhone: '+591 4445566',
    companyWebsite: 'https://grupoandino.bo',
    companyAddress: 'Av. América 890, Cochabamba',
    title: 'Asistente de Recursos Humanos',
    description:
        'Empresa del sector comercial requiere un asistente de Recursos Humanos para apoyar los procesos administrativos y de gestión del talento humano.',
    responsibilities:
        '- Apoyar en procesos de reclutamiento y selección.\n'
        '- Publicar ofertas laborales.\n'
        '- Revisar currículums y perfiles profesionales.\n'
        '- Coordinar entrevistas.\n'
        '- Organizar expedientes del personal.\n'
        '- Apoyar en actividades de capacitación.',
    requirements:
        '- Licenciatura en Psicología, Administración de Empresas o ramas afines.\n'
        '- Manejo de Microsoft Office.\n'
        '- Habilidades de comunicación.\n'
        '- Organización y responsabilidad.\n'
        '- Experiencia mínima de 6 meses (deseable).',
    area: 'Administración y Negocios',
    modality: 'Presencial',
    employmentType: 'Tiempo completo',
    experience: 'Junior (0-2 años)',
    education: 'Licenciatura / Egresado',
    salaryMinimum: 2800,
    salaryMaximum: 3500,
    skills: const ['Comunicación', 'Ofimática', 'Reclutamiento'],
    hours: 5,
  ),
  _job(
    id: 'demo-job-frontend',
    companyId: 'demo-company-nexotech',
    companyName: 'NexoTech Solutions',
    companySector: 'Tecnología',
    companyEmail: 'talento@nexotech.bo',
    companyPhone: '+591 4442233',
    companyWebsite: 'https://nexotech.bo',
    companyAddress: 'Calle España 312, Cochabamba',
    title: 'Desarrollador Frontend',
    description:
        'Buscamos un desarrollador frontend para construir interfaces web accesibles y de alto rendimiento junto al equipo de producto.',
    responsibilities:
        '- Implementar interfaces en React.\n'
        '- Integrar APIs REST.\n'
        '- Mantener componentes reutilizables.\n'
        '- Colaborar con diseño UX/UI.',
    requirements:
        '- Conocimientos de HTML, CSS y JavaScript.\n'
        '- Experiencia con React.\n'
        '- Uso de Git.',
    area: 'Tecnología y Software',
    modality: 'Híbrida',
    employmentType: 'Tiempo completo',
    experience: 'Junior (0-2 años)',
    education: 'Técnico',
    salaryMinimum: 3800,
    salaryMaximum: 4800,
    skills: const ['React', 'JavaScript', 'CSS'],
    hours: 6,
  ),
  _job(
    id: 'demo-job-software',
    companyId: 'demo-company-datavision',
    companyName: 'DataVision Bolivia',
    companySector: 'Analítica y software',
    companyEmail: 'rrhh@datavision.bo',
    companyPhone: '+591 4443344',
    companyWebsite: 'https://datavision.bo',
    companyAddress: 'Av. Blanco Galindo km 2, Cochabamba',
    title: 'Ingeniero de Software',
    description:
        'Incorporamos un ingeniero de software para diseñar, construir y mantener productos digitales usados por equipos de analítica.',
    responsibilities:
        '- Desarrollar features de punta a punta.\n'
        '- Revisar código y proponer mejoras.\n'
        '- Coordinar con producto y datos.',
    requirements:
        '- Ingeniería de Sistemas o similar.\n'
        '- Experiencia con servicios web y bases de datos.\n'
        '- Trabajo en equipo.',
    area: 'Tecnología y Software',
    modality: 'Híbrida',
    employmentType: 'Tiempo completo',
    experience: 'Semi Senior (3-5 años)',
    education: 'Licenciatura / Egresado',
    salaryMinimum: 5500,
    salaryMaximum: 7000,
    skills: const ['Software', 'APIs', 'SQL'],
    hours: 7,
  ),
  _job(
    id: 'demo-job-qa',
    companyId: 'demo-company-nexotech',
    companyName: 'NexoTech Solutions',
    companySector: 'Tecnología',
    companyEmail: 'talento@nexotech.bo',
    companyPhone: '+591 4442233',
    companyWebsite: 'https://nexotech.bo',
    companyAddress: 'Calle España 312, Cochabamba',
    title: 'Analista QA',
    description:
        'Se requiere un analista de calidad para planificar pruebas, reportar incidentes y cuidar la estabilidad de las aplicaciones.',
    responsibilities:
        '- Diseñar casos de prueba.\n'
        '- Ejecutar pruebas funcionales y de regresión.\n'
        '- Documentar bugs y seguimiento.',
    requirements:
        '- Conocimientos de testing manual.\n'
        '- Nociones de automatización deseables.\n'
        '- Atención al detalle.',
    area: 'Tecnología y Software',
    modality: 'Presencial',
    employmentType: 'Tiempo completo',
    experience: 'Junior (0-2 años)',
    education: 'Técnico',
    salaryMinimum: 3200,
    salaryMaximum: 4000,
    skills: const ['QA', 'Pruebas', 'Documentación'],
    hours: 8,
  ),
  _job(
    id: 'demo-job-dba',
    companyId: 'demo-company-datavision',
    companyName: 'DataVision Bolivia',
    companySector: 'Analítica y software',
    companyEmail: 'rrhh@datavision.bo',
    companyPhone: '+591 4443344',
    companyWebsite: 'https://datavision.bo',
    companyAddress: 'Av. Blanco Galindo km 2, Cochabamba',
    title: 'Administrador de Bases de Datos',
    description:
        'Buscamos un DBA para administrar PostgreSQL, respaldos y el rendimiento de los almacenes de datos de la empresa.',
    responsibilities:
        '- Administrar instancias de PostgreSQL.\n'
        '- Diseñar respaldos y recuperación.\n'
        '- Optimizar consultas y permisos.',
    requirements:
        '- Experiencia con PostgreSQL o similar.\n'
        '- Conocimientos de SQL avanzado.\n'
        '- Responsabilidad en disponibilidad de datos.',
    area: 'Tecnología y Software',
    modality: 'Híbrida',
    employmentType: 'Tiempo completo',
    experience: 'Semi Senior (3-5 años)',
    education: 'Licenciatura / Egresado',
    salaryMinimum: 5000,
    salaryMaximum: 6500,
    skills: const ['PostgreSQL', 'SQL', 'Backups'],
    hours: 9,
  ),
  _job(
    id: 'demo-job-ciberseguridad',
    companyId: 'demo-company-nexotech',
    companyName: 'NexoTech Solutions',
    companySector: 'Tecnología',
    companyEmail: 'talento@nexotech.bo',
    companyPhone: '+591 4442233',
    companyWebsite: 'https://nexotech.bo',
    companyAddress: 'Calle España 312, Cochabamba',
    title: 'Especialista en Ciberseguridad',
    description:
        'Incorporamos un especialista para fortalecer la seguridad de aplicaciones, redes internas y accesos de usuarios.',
    responsibilities:
        '- Evaluar vulnerabilidades.\n'
        '- Definir políticas de acceso.\n'
        '- Capacitar al equipo en buenas prácticas.',
    requirements:
        '- Formación en sistemas o ciberseguridad.\n'
        '- Conocimientos de redes y hardening.\n'
        '- Capacidad de reporte ejecutivo.',
    area: 'Tecnología y Software',
    modality: 'Presencial',
    employmentType: 'Tiempo completo',
    experience: 'Semi Senior (3-5 años)',
    education: 'Licenciatura / Egresado',
    salaryMinimum: 6000,
    salaryMaximum: 7800,
    skills: const ['Ciberseguridad', 'Redes', 'Auditoría'],
    hours: 10,
  ),
  _job(
    id: 'demo-job-consultor-ambiental',
    companyId: 'demo-company-ecoandes',
    companyName: 'EcoAndes Consultores',
    companySector: 'Consultoría ambiental',
    companyEmail: 'empleos@ecoandes.bo',
    companyPhone: '+591 4441122',
    companyWebsite: 'https://ecoandes.bo',
    companyAddress: 'Av. Heroínas 1420, Cochabamba',
    title: 'Consultor Ambiental',
    description:
        'Se requiere un consultor para acompañar a empresas en licenciamiento ambiental, auditorías y planes de mitigación.',
    responsibilities:
        '- Elaborar fichas y estudios ambientales.\n'
        '- Coordinar con autoridades competentes.\n'
        '- Asesorar a clientes en campo.',
    requirements:
        '- Ingeniería Ambiental o afines.\n'
        '- Experiencia en consultoría.\n'
        '- Manejo de normativa ambiental boliviana.',
    area: 'Ingeniería',
    modality: 'Híbrida',
    employmentType: 'Contrato',
    experience: 'Semi Senior (3-5 años)',
    education: 'Licenciatura / Egresado',
    salaryMinimum: 4800,
    salaryMaximum: 6200,
    skills: const ['Consultoría', 'Licenciamiento', 'QGIS'],
    hours: 11,
  ),
  _job(
    id: 'demo-job-tecnico-ambiental',
    companyId: 'demo-company-ecoandes',
    companyName: 'EcoAndes Consultores',
    companySector: 'Consultoría ambiental',
    companyEmail: 'empleos@ecoandes.bo',
    companyPhone: '+591 4441122',
    companyWebsite: 'https://ecoandes.bo',
    companyAddress: 'Av. Heroínas 1420, Cochabamba',
    title: 'Técnico en Seguridad Ambiental',
    description:
        'Buscamos un técnico para apoyar inspecciones, muestreos y el control de riesgos ambientales en obra.',
    responsibilities:
        '- Apoyar monitoreos de campo.\n'
        '- Registrar hallazgos de seguridad ambiental.\n'
        '- Elaborar checklists e informes simples.',
    requirements:
        '- Técnico superior o estudiante avanzado.\n'
        '- Disponibilidad para trabajo de campo.\n'
        '- Licencia de conducir deseable.',
    area: 'Ingeniería',
    modality: 'Presencial',
    employmentType: 'Tiempo completo',
    experience: 'Sin experiencia',
    education: 'Técnico',
    salaryMinimum: 2500,
    salaryMaximum: 3200,
    skills: const ['Campo', 'Monitoreo', 'Informes'],
    hours: 12,
  ),
  _job(
    id: 'demo-job-residuos',
    companyId: 'demo-company-ecoandes',
    companyName: 'EcoAndes Consultores',
    companySector: 'Consultoría ambiental',
    companyEmail: 'empleos@ecoandes.bo',
    companyPhone: '+591 4441122',
    companyWebsite: 'https://ecoandes.bo',
    companyAddress: 'Av. Heroínas 1420, Cochabamba',
    title: 'Especialista en Gestión de Residuos',
    description:
        'Se busca un especialista para diseñar y seguir planes de gestión integral de residuos sólidos en empresas y municipios.',
    responsibilities:
        '- Diagnosticar flujos de residuos.\n'
        '- Proponer rutas de reciclaje y disposición.\n'
        '- Capacitar personal operativo.',
    requirements:
        '- Formación ambiental o industrial.\n'
        '- Experiencia en residuos sólidos.\n'
        '- Habilidad de coordinación con operarios.',
    area: 'Ingeniería',
    modality: 'Presencial',
    employmentType: 'Tiempo completo',
    experience: 'Junior (0-2 años)',
    education: 'Licenciatura / Egresado',
    salaryMinimum: 3800,
    salaryMaximum: 4700,
    skills: const ['Residuos', 'Capacitación', 'Normativa'],
    hours: 13,
  ),
  _job(
    id: 'demo-job-admin',
    companyId: 'demo-company-andino',
    companyName: 'Grupo Empresarial Andino',
    companySector: 'Comercio',
    companyEmail: 'talento@grupoandino.bo',
    companyPhone: '+591 4445566',
    companyWebsite: 'https://grupoandino.bo',
    companyAddress: 'Av. América 890, Cochabamba',
    title: 'Asistente Administrativo',
    description:
        'Requerimos un asistente para apoyar la operación diaria de oficina, archivo, agenda y atención a proveedores.',
    responsibilities:
        '- Organizar correspondencia y archivos.\n'
        '- Apoyar compras menores y caja chica.\n'
        '- Atender llamadas y visitas.',
    requirements:
        '- Bachillerato o estudios en administración.\n'
        '- Manejo de Office.\n'
        '- Orden y puntualidad.',
    area: 'Administración y Negocios',
    modality: 'Presencial',
    employmentType: 'Tiempo completo',
    experience: 'Sin experiencia',
    education: 'Bachillerato',
    salaryMinimum: 2200,
    salaryMaximum: 2800,
    skills: const ['Ofimática', 'Organización', 'Atención al cliente'],
    hours: 14,
  ),
  _job(
    id: 'demo-job-financiero',
    companyId: 'demo-company-andino',
    companyName: 'Grupo Empresarial Andino',
    companySector: 'Comercio',
    companyEmail: 'talento@grupoandino.bo',
    companyPhone: '+591 4445566',
    companyWebsite: 'https://grupoandino.bo',
    companyAddress: 'Av. América 890, Cochabamba',
    title: 'Analista Financiero',
    description:
        'Buscamos un analista para elaborar reportes de ingresos, control presupuestario y seguimiento de indicadores financieros.',
    responsibilities:
        '- Armar reportes mensuales.\n'
        '- Controlar presupuestos de áreas.\n'
        '- Apoyar cierres contables.',
    requirements:
        '- Formación en economía, auditoría o administración.\n'
        '- Excel avanzado.\n'
        '- Experiencia en reportes financieros deseable.',
    area: 'Administración y Negocios',
    modality: 'Híbrida',
    employmentType: 'Tiempo completo',
    experience: 'Junior (0-2 años)',
    education: 'Licenciatura / Egresado',
    salaryMinimum: 4000,
    salaryMaximum: 5200,
    skills: const ['Excel', 'Presupuestos', 'Reportes'],
    hours: 15,
  ),
  _job(
    id: 'demo-job-community',
    companyId: 'demo-company-pixel',
    companyName: 'Pixel Creative Studio',
    companySector: 'Diseño y publicidad',
    companyEmail: 'hola@pixelcreative.bo',
    companyPhone: '+591 4444455',
    companyWebsite: 'https://pixelcreative.bo',
    companyAddress: 'Calle 25 de Mayo 210, Cochabamba',
    title: 'Community Manager',
    description:
        'Estudio creativo busca community manager para gestionar redes, calendario de contenidos y comunidad de marcas locales.',
    responsibilities:
        '- Publicar y moderar redes sociales.\n'
        '- Armar calendarios de contenido.\n'
        '- Reportar métricas mensuales.',
    requirements:
        '- Conocimientos de Meta e Instagram.\n'
        '- Redacción clara.\n'
        '- Portafolio o ejemplos de campañas.',
    area: 'Marketing y Comunicación',
    modality: 'Híbrida',
    employmentType: 'Medio tiempo',
    experience: 'Junior (0-2 años)',
    education: 'Bachillerato',
    salaryMinimum: 2200,
    salaryMaximum: 3000,
    skills: const ['Redes sociales', 'Copywriting', 'Canva'],
    hours: 16,
  ),
  _job(
    id: 'demo-job-grafico',
    companyId: 'demo-company-pixel',
    companyName: 'Pixel Creative Studio',
    companySector: 'Diseño y publicidad',
    companyEmail: 'hola@pixelcreative.bo',
    companyPhone: '+591 4444455',
    companyWebsite: 'https://pixelcreative.bo',
    companyAddress: 'Calle 25 de Mayo 210, Cochabamba',
    title: 'Diseñador Gráfico',
    description:
        'Se requiere un diseñador gráfico para piezas digitales e impresas de campañas comerciales y educativas.',
    responsibilities:
        '- Diseñar posts, banners y presentaciones.\n'
        '- Cuidar identidad visual de clientes.\n'
        '- Entregar archivos listos para publicación.',
    requirements:
        '- Manejo de Illustrator, Photoshop o Figma.\n'
        '- Portafolio obligatorio.\n'
        '- Sentido de marca y tipografía.',
    area: 'Marketing y Comunicación',
    modality: 'Presencial',
    employmentType: 'Tiempo completo',
    experience: 'Junior (0-2 años)',
    education: 'Técnico',
    salaryMinimum: 3000,
    salaryMaximum: 3800,
    skills: const ['Illustrator', 'Photoshop', 'Figma'],
    hours: 17,
  ),
  _job(
    id: 'demo-job-industrial',
    companyId: 'demo-company-andino',
    companyName: 'Grupo Empresarial Andino',
    companySector: 'Comercio',
    companyEmail: 'talento@grupoandino.bo',
    companyPhone: '+591 4445566',
    companyWebsite: 'https://grupoandino.bo',
    companyAddress: 'Av. América 890, Cochabamba',
    title: 'Ingeniero Industrial',
    description:
        'Incorporamos un ingeniero industrial para mejorar procesos logísticos, indicadores de almacén y productividad operativa.',
    responsibilities:
        '- Mapear procesos de almacén y despacho.\n'
        '- Proponer mejoras de eficiencia.\n'
        '- Seguir KPIs operativos.',
    requirements:
        '- Ingeniería Industrial.\n'
        '- Conocimientos de Lean o similar.\n'
        '- Excel intermedio.',
    area: 'Ingeniería',
    modality: 'Presencial',
    employmentType: 'Tiempo completo',
    experience: 'Junior (0-2 años)',
    education: 'Licenciatura / Egresado',
    salaryMinimum: 4200,
    salaryMaximum: 5300,
    skills: const ['Procesos', 'Lean', 'Excel'],
    hours: 18,
  ),
  _job(
    id: 'demo-job-civil',
    companyId: 'demo-company-ecoandes',
    companyName: 'EcoAndes Consultores',
    companySector: 'Consultoría ambiental',
    companyEmail: 'empleos@ecoandes.bo',
    companyPhone: '+591 4441122',
    companyWebsite: 'https://ecoandes.bo',
    companyAddress: 'Av. Heroínas 1420, Cochabamba',
    title: 'Ingeniero Civil',
    description:
        'Se busca un ingeniero civil para apoyar supervisión de obras menores y el cumplimiento ambiental en proyectos de infraestructura.',
    responsibilities:
        '- Revisar avances de obra.\n'
        '- Coordinar con residentes y consultores ambientales.\n'
        '- Elaborar informes técnicos.',
    requirements:
        '- Ingeniería Civil.\n'
        '- Disponibilidad de campo.\n'
        '- AutoCAD deseable.',
    area: 'Ingeniería',
    modality: 'Presencial',
    employmentType: 'Contrato',
    experience: 'Junior (0-2 años)',
    education: 'Licenciatura / Egresado',
    salaryMinimum: 4500,
    salaryMaximum: 5800,
    skills: const ['Obra', 'AutoCAD', 'Informes técnicos'],
    hours: 19,
  ),
  _job(
    id: 'demo-job-seleccion',
    companyId: 'demo-company-andino',
    companyName: 'Grupo Empresarial Andino',
    companySector: 'Comercio',
    companyEmail: 'talento@grupoandino.bo',
    companyPhone: '+591 4445566',
    companyWebsite: 'https://grupoandino.bo',
    companyAddress: 'Av. América 890, Cochabamba',
    title: 'Analista de Selección',
    description:
        'Buscamos un analista de selección para filtrar postulaciones, coordinar entrevistas y acompañar la incorporación de personal.',
    responsibilities:
        '- Publicar y filtrar vacantes.\n'
        '- Entrevistar candidatos.\n'
        '- Armar informes de terna.',
    requirements:
        '- Psicología, RR. HH. o administración.\n'
        '- Experiencia en reclutamiento deseable.\n'
        '- Buena comunicación.',
    area: 'Administración y Negocios',
    modality: 'Híbrida',
    employmentType: 'Tiempo completo',
    experience: 'Junior (0-2 años)',
    education: 'Licenciatura / Egresado',
    salaryMinimum: 3200,
    salaryMaximum: 4100,
    skills: const ['Selección', 'Entrevistas', 'Comunicación'],
    hours: 20,
  ),
];

JobPosting _job({
  required String id,
  required String companyId,
  required String companyName,
  required String companySector,
  required String companyEmail,
  required String companyPhone,
  required String companyWebsite,
  required String companyAddress,
  required String title,
  required String description,
  required String responsibilities,
  required String requirements,
  required String area,
  required String modality,
  required String employmentType,
  required String experience,
  required String education,
  required int salaryMinimum,
  required int salaryMaximum,
  required List<String> skills,
  required int hours,
  List<String> requiredDocuments = const [
    'Currículum Vitae (CV) actualizado',
    'Carta de presentación o motivación',
  ],
}) {
  final createdAt = _published.add(Duration(hours: hours));
  return JobPosting(
    id: id,
    companyId: companyId,
    ownerUid: companyId,
    companyName: companyName,
    companySector: companySector,
    companyEmail: companyEmail,
    companyPhone: companyPhone,
    companyWebsite: companyWebsite,
    companyAddress: companyAddress,
    title: title,
    description: description,
    responsibilities: responsibilities,
    requirements: requirements,
    area: area,
    city: 'Cochabamba',
    modality: modality,
    employmentType: employmentType,
    experience: experience,
    education: education,
    salaryMinimum: salaryMinimum,
    salaryMaximum: salaryMaximum,
    currency: 'BOB',
    createdAt: createdAt,
    deadline: _deadline,
    status: 'published',
    zone: 'Centro',
    requiredDocuments: requiredDocuments,
    skills: skills,
    benefits: const ['Horario Flexible', 'Capacitación Pagada'],
    publicationDate: createdAt,
    vacancyCount: 1,
    applicationChannel: 'app',
    contactEmail: companyEmail,
    whatsApp: companyPhone,
  );
}
