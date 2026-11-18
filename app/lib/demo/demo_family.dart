import 'package:flutter/foundation.dart';

class DemoInvitation {
  const DemoInvitation({required this.family, required this.from});
  final String family;
  final String from;
}

/// Presentation family state, kept in memory with fictitious data only.
class DemoFamily extends ChangeNotifier {
  static const publicId = '7f3a9c2e5b1d4e8fa06c2b9d5e1f7a34';
  static final _idPattern = RegExp(r'^[0-9a-fA-F]{32}$');

  final List<String> families = ['Casa Rivera'];
  final List<DemoInvitation> received = [
    const DemoInvitation(family: 'Familia Quispe', from: 'Rosa Quispe'),
  ];
  final List<String> sent = [];

  void respond(DemoInvitation invitation, {required bool accept}) {
    received.remove(invitation);
    if (accept) families.add(invitation.family);
    notifyListeners();
  }

  /// Returns an error message, or null when the invitation was sent.
  String? invite(String id) {
    final value = id.trim();
    if (!_idPattern.hasMatch(value)) {
      return 'Pega el ID completo: 32 letras y números.';
    }
    if (value.toLowerCase() == publicId) {
      return 'Ese es tu propio ID.';
    }
    if (sent.contains(value)) return 'Ya invitaste a esa persona.';
    sent.add(value);
    notifyListeners();
    return null;
  }
}
