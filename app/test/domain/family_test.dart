import 'package:app/features/family/domain/family.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FamilyGroup family;
  setUp(() => family = FamilyGroup(id: 'A', name: 'Casa', creatorId: 'alice'));

  test('TC-FAM-01 HU-03 creador admin y solo admin invita', () {
    expect(family.isAdmin('alice'), isTrue);
    expect(
      () => family.invite(actor: 'stranger', target: 'bob'),
      throwsStateError,
    );
    expect(
      () => family.invite(actor: 'alice', target: 'alice'),
      throwsStateError,
    );
  });
  test(
    'TC-FAM-02 HU-04 invitación no concede acceso; receptor decide una vez',
    () {
      final invitation = family.invite(actor: 'alice', target: 'bob');
      expect(family.contains('bob'), isFalse);
      expect(
        () => family.respond(invitation.id, actor: 'eve', accept: true),
        throwsStateError,
      );
      family.respond(invitation.id, actor: 'bob', accept: true);
      expect(family.contains('bob'), isTrue);
      expect(family.isAdmin('bob'), isFalse);
      expect(
        () => family.respond(invitation.id, actor: 'bob', accept: true),
        throwsStateError,
      );
    },
  );
  test('TC-FAM-02 HU-04 rechazo y duplicado pendiente', () {
    final invitation = family.invite(actor: 'alice', target: 'bob');
    expect(
      () => family.invite(actor: 'alice', target: 'bob'),
      throwsStateError,
    );
    family.respond(invitation.id, actor: 'bob', accept: false);
    expect(family.contains('bob'), isFalse);
    expect(family.invite(actor: 'alice', target: 'bob'), isNotNull);
  });
  test('TC-FAM-04 HU-05 último admin no sale ni renuncia', () {
    expect(() => family.leave('alice'), throwsStateError);
    expect(
      () => family.setAdmin(actor: 'alice', target: 'alice', value: false),
      throwsStateError,
    );
    expect(family.isAdmin('alice'), isTrue);
  });
  test('TC-FAM-03 HU-05 transferencia, renuncia y salida', () {
    family.respond(
      family.invite(actor: 'alice', target: 'bob').id,
      actor: 'bob',
      accept: true,
    );
    expect(
      () => family.setAdmin(actor: 'bob', target: 'bob', value: true),
      throwsStateError,
    );
    family.setAdmin(actor: 'alice', target: 'bob', value: true);
    family.setAdmin(actor: 'alice', target: 'alice', value: false);
    family.leave('alice');
    expect(family.isAdmin('bob'), isTrue);
    expect(family.contains('alice'), isFalse);
  });
  test(
    'TC-FAM-05 HU-06 ascendencia rechaza ciclos, autorrelación y ajenos',
    () {
      for (final user in ['bob', 'carol']) {
        family.respond(
          family.invite(actor: 'alice', target: user).id,
          actor: user,
          accept: true,
        );
      }
      family.addParent(actor: 'alice', parent: 'alice', child: 'bob');
      family.addParent(actor: 'alice', parent: 'bob', child: 'carol');
      expect(
        () => family.addParent(actor: 'alice', parent: 'carol', child: 'alice'),
        throwsStateError,
      );
      expect(
        () => family.addParent(actor: 'alice', parent: 'alice', child: 'alice'),
        throwsStateError,
      );
      expect(
        () =>
            family.addParent(actor: 'alice', parent: 'alice', child: 'outside'),
        throwsStateError,
      );
      expect(
        () => family.addParent(actor: 'bob', parent: 'alice', child: 'carol'),
        throwsStateError,
      );
    },
  );
  test(
    'TC-SEC-01 HU-03 mismo usuario en dos grupos sin compartir permisos',
    () {
      final other = FamilyGroup(id: 'B', name: 'Otra casa', creatorId: 'bob');
      expect(other.isAdmin('alice'), isFalse);
      expect(
        () => other.invite(actor: 'alice', target: 'carol'),
        throwsStateError,
      );
      expect(family.isAdmin('alice'), isTrue);
    },
  );
}
