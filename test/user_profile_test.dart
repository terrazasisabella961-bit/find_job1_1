import 'package:flutter_test/flutter_test.dart';
import 'package:find_job1_1/src/models/user_profile.dart';

void main() {
  test('legacy Firestore user docs still parse without the new fields', () {
    final profile = UserProfile.fromMap({
      'uid': 'user-1',
      'fullName': 'Ana',
      'email': 'ana@example.com',
      'phone': '70000000',
      'city': 'Cochabamba',
      'areaOfInterest': 'Tecnología',
      'acceptedTerms': true,
    });

    expect(profile.educationLevel, isEmpty);
    expect(profile.careerTitle, isEmpty);
    expect(profile.skills, isEmpty);
    expect(profile.languages, isEmpty);
    expect(profile.aboutMe, isEmpty);
    expect(profile.hasCoordinates, isFalse);
    expect(profile.birthDate, isNull);
    expect(profile.isUnder18, isFalse);
  });

  test('new profile fields round-trip through the Firestore map', () {
    final original = UserProfile(
      uid: 'user-2',
      fullName: 'Luis',
      email: 'luis@example.com',
      phone: '',
      city: 'Cochabamba',
      areaOfInterest: 'Salud',
      educationLevel: 'Licenciatura',
      careerTitle: 'Ingeniería Ambiental',
      skills: ['Comunicación', 'Logística'],
      languages: [
        ProfileLanguage(name: 'Español', level: 'Nativo'),
        ProfileLanguage(name: 'Quechua', level: 'Intermedio'),
      ],
      aboutMe: 'Busco empleo en gestión ambiental.',
      birthDate: DateTime(2000, 5, 20),
    );

    final restored = UserProfile.fromMap(
      Map<String, dynamic>.from(original.toMap()),
    );

    expect(restored.educationLevel, 'Licenciatura');
    expect(restored.careerTitle, 'Ingeniería Ambiental');
    expect(restored.skills, ['Comunicación', 'Logística']);
    expect(restored.languages, hasLength(2));
    expect(restored.languages.first.name, 'Español');
    expect(restored.languages.first.level, 'Nativo');
    expect(restored.languages.last.name, 'Quechua');
    expect(restored.aboutMe, 'Busco empleo en gestión ambiental.');
    expect(restored.birthDate, DateTime(2000, 5, 20));
    expect(restored.isUnder18, isFalse);
  });

  test('age gate treats today as the 18th birthday', () {
    final today = DateTime(2026, 11, 24);
    expect(
      isAtLeast18YearsOld(DateTime(2008, 11, 24), now: today),
      isTrue,
    );
    expect(
      isAtLeast18YearsOld(DateTime(2008, 11, 25), now: today),
      isFalse,
    );
    expect(latestAdultBirthDate(today), DateTime(2008, 11, 24));
  });
}
