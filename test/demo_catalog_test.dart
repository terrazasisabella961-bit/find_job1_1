import 'package:flutter_test/flutter_test.dart';

import 'package:find_job1_1/src/data/demo_catalog.dart';

void main() {
  test('demo catalog includes the requested courses and jobs', () {
    expect(demoPublishedCourses, hasLength(5));
    expect(
      demoPublishedCourses.map((course) => course.title),
      containsAll([
        'Desarrollo Web Full Stack',
        'Análisis de Datos con Python',
        'Gestión Ambiental y Desarrollo Sostenible',
        'Diseño UX/UI y Prototipado Digital',
        'Marketing Digital y Comercio Electrónico',
      ]),
    );
    expect(
      demoPublishedJobs.map((job) => job.title),
      containsAll([
        'Ingeniero/a Ambiental',
        'Desarrollador Backend Junior',
        'Analista de Datos',
        'Diseñador/a UX/UI',
        'Asistente de Recursos Humanos',
        'Community Manager',
        'Analista de Selección',
      ]),
    );
    expect(
      withDemoJobs(const []).every((job) => job.status == 'published'),
      isTrue,
    );
    expect(
      withDemoCourses(const []).every((course) => course.status == 'published'),
      isTrue,
    );
  });
}
