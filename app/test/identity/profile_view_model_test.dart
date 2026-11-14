import 'package:app/features/identity/domain/profile.dart';
import 'package:app/features/identity/presentation/profile_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

const valid = ProfileInput(
  fullName: 'Persona ficticia',
  identityCard: 'FICTICIO',
  birthDate: '2000-02-29',
  address: 'Domicilio de prueba',
  bloodType: 'O+',
);

class FakeProfiles implements ProfileRepository {
  PersonalProfile? value;
  bool conflict = false;
  int calls = 0;
  int? version;
  @override
  Future<PersonalProfile?> load() async => value;
  @override
  Future<PersonalProfile> save(
    ProfileInput input, {
    int? expectedVersion,
  }) async {
    calls++;
    version = expectedVersion;
    if (conflict) throw StateError('version_conflict');
    return value = PersonalProfile(
      userId: 'ficticio',
      publicId: 'aleatorio',
      version: (expectedVersion ?? 0) + 1,
      details: input,
    );
  }

  @override
  Future<void> share(
    String familyId,
    List<String> fields,
    String requestId,
  ) async {}
}

void main() {
  test(
    'TC-PRO-01 HU-02: fecha imposible y futuro rechazados antes de enviar',
    () {
      expect(valid.isValid, true);
      expect(
        const ProfileInput(
          fullName: 'Persona',
          identityCard: 'FICTICIO',
          birthDate: '2001-02-29',
          address: 'Domicilio',
        ).isValid,
        false,
      );
      expect(
        const ProfileInput(
          fullName: 'Persona',
          identityCard: 'FICTICIO',
          birthDate: '9999-01-01',
          address: 'Domicilio',
        ).isValid,
        false,
      );
      expect(valid.toParams().containsKey('user_id'), false);
    },
  );
  test(
    'TC-PRO-01 HU-02: creación, versión y conflicto no sustituyen datos locales',
    () async {
      final repo = FakeProfiles();
      final vm = ProfileViewModel(repo);
      addTearDown(vm.dispose);
      await vm.load();
      expect(vm.loaded, true);
      expect(vm.profile, isNull);
      expect(await vm.save(valid), true);
      expect(repo.version, isNull);
      expect(await vm.save(valid), true);
      expect(repo.version, 1);
      expect(vm.profile!.version, 2);
      repo.conflict = true;
      expect(await vm.save(valid), false);
      expect(vm.profile!.version, 2);
      expect(vm.message, contains('recarga'));
    },
  );
  test('TC-PRO-01 HU-02: validación no llama al repositorio', () async {
    final repo = FakeProfiles();
    final vm = ProfileViewModel(repo);
    addTearDown(vm.dispose);
    expect(
      await vm.save(
        const ProfileInput(
          fullName: '',
          identityCard: '',
          birthDate: '',
          address: '',
        ),
      ),
      false,
    );
    expect(repo.calls, 0);
  });
}
