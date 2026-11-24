import 'package:flutter_test/flutter_test.dart';
import 'package:find_job1_1/src/data/demo_catalog.dart';
import 'package:find_job1_1/src/geo/map_defaults.dart';

void main() {
  test('distance between Cochabamba center and a nearby pin is under 3 km', () {
    final km = distanceKm(
      fromLat: cochabambaCenter.latitude,
      fromLng: cochabambaCenter.longitude,
      toLat: -17.3938,
      toLng: -66.1560,
    );
    expect(km, lessThan(3));
    expect(formatDistanceKm(0.4), '400 m');
  });

  test('demo companies sort by distance from the city center', () {
    final origin = cochabambaCenter;
    final companies = [...demoLocatedCompanies]
      ..sort((a, b) {
        final da = distanceKm(
          fromLat: origin.latitude,
          fromLng: origin.longitude,
          toLat: a.latitude!,
          toLng: a.longitude!,
        );
        final db = distanceKm(
          fromLat: origin.latitude,
          fromLng: origin.longitude,
          toLat: b.latitude!,
          toLng: b.longitude!,
        );
        return da.compareTo(db);
      });
    expect(companies, isNotEmpty);
    final first = distanceKm(
      fromLat: origin.latitude,
      fromLng: origin.longitude,
      toLat: companies.first.latitude!,
      toLng: companies.first.longitude!,
    );
    final last = distanceKm(
      fromLat: origin.latitude,
      fromLng: origin.longitude,
      toLat: companies.last.latitude!,
      toLng: companies.last.longitude!,
    );
    expect(first, lessThanOrEqualTo(last));
  });
}
