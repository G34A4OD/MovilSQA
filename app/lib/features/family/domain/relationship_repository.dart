import 'family_repository.dart';

enum FamilyRole {
  parent('Padre / madre de', 'parent'),
  child('Hijo / hija de', 'parent', true),
  grandparent('Abuelo / abuela de', 'grandparent'),
  grandchild('Nieto / nieta de', 'grandparent', true),
  uncle('Tío / tía de', 'uncle'),
  nephew('Sobrino / sobrina de', 'uncle', true),
  sibling('Hermano / hermana de', 'sibling'),
  cousin('Primo / prima de', 'cousin'),
  partner('Pareja de', 'partner');

  const FamilyRole(this.label, this.kind, [this.reverse = false]);
  final String label, kind;
  final bool reverse;
}

class RelationshipRecord {
  const RelationshipRecord({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.kind,
    required this.version,
  });
  final String id, fromUserId, toUserId, kind;
  final int version;
  bool get isAncestry => kind == 'parent' || kind == 'grandparent';
  String get label =>
      FamilyRole.values.firstWhere((r) => r.kind == kind && !r.reverse).label;
}

class RelationshipInput {
  const RelationshipInput({
    required this.personId,
    required this.relativeId,
    required this.role,
  });
  final String personId, relativeId;
  final FamilyRole role;
  String get fromUserId => role.reverse ? relativeId : personId;
  String get toUserId => role.reverse ? personId : relativeId;
}

abstract interface class RelationshipRepository {
  Future<List<RelationshipRecord>> list(String familyId);
  Future<void> save(
    String familyId,
    RelationshipInput input,
    String requestId, {
    RelationshipRecord? existing,
  });
  Future<void> delete(String familyId, RelationshipRecord relationship);
}

/// A DAG may have more than one parent; grandparents can be recorded even when
/// the intermediate parent has no account. Lateral roles do not imply ancestry.
Map<String, int> familyGenerations(
  List<FamilyMember> members,
  List<RelationshipRecord> relationships,
) {
  final levels = {for (final m in members) m.userId: 0};
  final incoming = {for (final m in members) m.userId: 0};
  final edges = <String, List<RelationshipRecord>>{};
  for (final r in relationships.where((r) => r.isAncestry)) {
    if (!levels.containsKey(r.fromUserId) || !levels.containsKey(r.toUserId)) {
      continue;
    }
    edges.putIfAbsent(r.fromUserId, () => []).add(r);
    incoming[r.toUserId] = incoming[r.toUserId]! + 1;
  }
  final ready = incoming.keys.where((id) => incoming[id] == 0).toList();
  var processed = 0;
  for (var index = 0; index < ready.length; index++) {
    final id = ready[index];
    processed++;
    for (final r in edges[id] ?? <RelationshipRecord>[]) {
      final proposed = levels[id]! + (r.kind == 'grandparent' ? 2 : 1);
      if (proposed > levels[r.toUserId]!) {
        levels[r.toUserId] = proposed;
      }
      incoming[r.toUserId] = incoming[r.toUserId]! - 1;
      if (incoming[r.toUserId] == 0) {
        ready.add(r.toUserId);
      }
    }
  }
  if (processed != members.length) {
    throw StateError('invalid_relationship');
  }
  return levels;
}
