import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:app/core/app_theme.dart';
import 'package:app/features/family/domain/family_repository.dart';
import 'package:app/features/family/domain/relationship_repository.dart';
import 'package:app/features/family/presentation/relationship_view_model.dart';
import 'package:app/features/family/presentation/family_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const members = [
  FamilyMember(
    userId: 'a',
    fullName: 'Persona A',
    publicId: 'ficticio-a',
    isAdmin: true,
  ),
  FamilyMember(
    userId: 'b',
    fullName: 'Persona B',
    publicId: 'ficticio-b',
    isAdmin: false,
  ),
  FamilyMember(
    userId: 'c',
    fullName: 'Persona C',
    publicId: 'ficticio-c',
    isAdmin: false,
  ),
];
const ab = RelationshipRecord(
  id: 'ab',
  fromUserId: 'a',
  toUserId: 'b',
  kind: 'parent',
  version: 1,
);
const bc = RelationshipRecord(
  id: 'bc',
  fromUserId: 'b',
  toUserId: 'c',
  kind: 'parent',
  version: 1,
);

class FakeRelationships implements RelationshipRepository {
  List<RelationshipRecord> values = [];
  bool fail = false;
  final requests = <String>[];
  @override
  Future<List<RelationshipRecord>> list(String familyId) async => values;
  @override
  Future<void> save(
    String familyId,
    RelationshipInput input,
    String requestId, {
    RelationshipRecord? existing,
  }) async {
    requests.add(requestId);
    if (fail) {
      throw StateError('invalid_relationship');
    }
    values = [ab];
  }

  @override
  Future<void> delete(String familyId, RelationshipRecord relationship) async {
    values = [];
  }
}

void main() {
  test(
    'TC-FAM-05 HU-06: hijo/nieto/sobrino invierten dirección, parentesco no concede admin',
    () {
      for (final role in [
        FamilyRole.child,
        FamilyRole.grandchild,
        FamilyRole.nephew,
      ]) {
        final input = RelationshipInput(
          personId: 'b',
          relativeId: 'a',
          role: role,
        );
        expect(input.fromUserId, 'a');
        expect(input.toUserId, 'b');
      }
      expect(members[1].isAdmin, false);
    },
  );
  test('TC-FAM-05 HU-06: generaciones, abuelo explícito y ciclo defensivo', () {
    expect(familyGenerations(members, [ab, bc]), {'a': 0, 'b': 1, 'c': 2});
    expect(
      familyGenerations(members, [
        const RelationshipRecord(
          id: 'ac',
          fromUserId: 'a',
          toUserId: 'c',
          kind: 'grandparent',
          version: 1,
        ),
      ])['c'],
      2,
    );
    expect(
      () => familyGenerations(members, [
        ab,
        bc,
        const RelationshipRecord(
          id: 'ca',
          fromUserId: 'c',
          toUserId: 'a',
          kind: 'parent',
          version: 1,
        ),
      ]),
      throwsStateError,
    );
  });
  test(
    'TC-FAM-05 HU-06: reintento no cambia request y conflicto conserva grafo',
    () async {
      final repo = FakeRelationships();
      final vm = RelationshipViewModel(repo, 'familia');
      addTearDown(vm.dispose);
      const input = RelationshipInput(
        personId: 'a',
        relativeId: 'b',
        role: FamilyRole.parent,
      );
      repo.fail = true;
      expect(await vm.save(input), false);
      repo.fail = false;
      expect(await vm.save(input), true);
      expect(repo.requests[0], repo.requests[1]);
      expect(vm.items, hasLength(1));
      await vm.delete(ab);
      expect(vm.items, isEmpty);
    },
  );
  testWidgets(
    'TC-FAM-05 HU-06: árbol renderiza tres generaciones sin desbordar',
    (tester) async {
      const boundaryKey = Key('tree-boundary');
      tester.view.physicalSize = const Size(412, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fontPath = Platform.environment['NIDO_TEST_FONT_PATH'];
      if (fontPath != null) {
        await tester.runAsync(() async {
          final loader = FontLoader('Roboto')
            ..addFont(
              Future.value(
                ByteData.sublistView(File(fontPath).readAsBytesSync()),
              ),
            );
          await loader.load();
        });
      }
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: RepaintBoundary(
              key: boundaryKey,
              child: ColoredBox(
                color: AppTheme.cream,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: FamilyTree(members: members, relationships: [ab, bc]),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final target = Platform.environment['NIDO_CAPTURE_WIDGET_PATH'];
      if (target != null) {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(boundaryKey),
          );
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(target).parent.createSync(recursive: true);
          File(target).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    },
  );
}
