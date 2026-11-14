enum InvitationStatus { pending, accepted, rejected }

class FamilyInvitation {
  const FamilyInvitation({
    required this.id,
    required this.target,
    required this.invitedBy,
    this.status = InvitationStatus.pending,
  });
  final String id;
  final String target;
  final String invitedBy;
  final InvitationStatus status;
}

/// Local domain aggregate. Concurrency, expiration, account lookup and access
/// control across devices require the Laravel transactional implementation.
class FamilyGroup {
  FamilyGroup({
    required this.id,
    required this.name,
    required String creatorId,
  }) {
    if (id.trim().isEmpty || name.trim().isEmpty || creatorId.trim().isEmpty) {
      throw ArgumentError('Grupo y creador obligatorios.');
    }
    _members[creatorId] = true;
  }
  final String id;
  String name;
  final Map<String, bool> _members = {};
  final Map<String, FamilyInvitation> _invitations = {};
  final Map<String, Set<String>> _children = {};
  int _sequence = 0;
  Map<String, bool> get members => Map.unmodifiable(_members);
  List<FamilyInvitation> get invitations =>
      List.unmodifiable(_invitations.values);
  bool contains(String userId) => _members.containsKey(userId);
  bool isAdmin(String userId) => _members[userId] == true;

  FamilyInvitation invite({required String actor, required String target}) {
    _requireAdmin(actor);
    if (target.trim().isEmpty ||
        contains(target) ||
        _invitations.values.any(
          (i) => i.target == target && i.status == InvitationStatus.pending,
        )) {
      throw StateError('El usuario ya pertenece al grupo o tiene invitación.');
    }
    final invitation = FamilyInvitation(
      id: '$id-${++_sequence}',
      target: target,
      invitedBy: actor,
    );
    _invitations[invitation.id] = invitation;
    return invitation;
  }

  void respond(
    String invitationId, {
    required String actor,
    required bool accept,
  }) {
    final invitation = _invitations[invitationId];
    if (invitation == null ||
        invitation.target != actor ||
        invitation.status != InvitationStatus.pending ||
        !isAdmin(invitation.invitedBy)) {
      throw StateError('La invitación no se puede responder.');
    }
    if (accept) _members[actor] = false;
    _invitations[invitationId] = FamilyInvitation(
      id: invitation.id,
      target: invitation.target,
      invitedBy: invitation.invitedBy,
      status: accept ? InvitationStatus.accepted : InvitationStatus.rejected,
    );
  }

  void setAdmin({
    required String actor,
    required String target,
    required bool value,
  }) {
    _requireAdmin(actor);
    if (!contains(target)) {
      throw StateError('El usuario no pertenece al grupo.');
    }
    if (!value) _protectLastAdmin(target);
    _members[target] = value;
  }

  void leave(String userId) {
    if (!contains(userId)) throw StateError('No eres miembro de este grupo.');
    _remove(userId);
  }

  void removeMember({required String actor, required String target}) {
    _requireAdmin(actor);
    if (!contains(target)) throw StateError('No es miembro del grupo.');
    _remove(target);
  }

  void _remove(String target) {
    _protectLastAdmin(target);
    _members.remove(target);
    _children.remove(target);
    for (final children in _children.values) {
      children.remove(target);
    }
  }

  void addParent({
    required String actor,
    required String parent,
    required String child,
  }) {
    _requireAdmin(actor);
    if (!contains(parent) ||
        !contains(child) ||
        parent == child ||
        _reaches(child, parent, {})) {
      throw StateError('El parentesco es inválido o crea un ciclo.');
    }
    (_children[parent] ??= {}).add(child);
  }

  bool _reaches(String from, String target, Set<String> visited) {
    if (from == target) return true;
    if (!visited.add(from)) return false;
    return (_children[from] ?? {}).any(
      (child) => _reaches(child, target, visited),
    );
  }

  void _requireAdmin(String actor) {
    if (!isAdmin(actor)) {
      throw StateError('Solo un administrador puede hacer esto.');
    }
  }

  void _protectLastAdmin(String target) {
    if (isAdmin(target) &&
        _members.values.where((value) => value).length == 1) {
      throw StateError(
        'Designa otro administrador antes de salir o renunciar.',
      );
    }
  }
}
