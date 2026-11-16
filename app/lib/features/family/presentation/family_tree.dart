import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../domain/family_repository.dart';
import '../domain/relationship_repository.dart';

class FamilyTree extends StatelessWidget {
  const FamilyTree({
    super.key,
    required this.members,
    required this.relationships,
  });
  final List<FamilyMember> members;
  final List<RelationshipRecord> relationships;
  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }
    Map<String, int> generations;
    try {
      generations = familyGenerations(members, relationships);
    } catch (_) {
      return const Text('No se pudo dibujar el árbol. Recarga los vínculos.');
    }
    final positions = <String, Offset>{};
    final columns = <int, int>{};
    var maxColumns = 1;
    var maxLevel = 0;
    for (final member in members) {
      final level = generations[member.userId]!;
      final column = columns[level] ?? 0;
      columns[level] = column + 1;
      maxColumns = math.max(maxColumns, column + 1);
      maxLevel = math.max(maxLevel, level);
      positions[member.userId] = Offset(20 + column * 196, 20 + level * 130);
    }
    final size = Size(
      math.max(360, maxColumns * 196 + 20).toDouble(),
      math.max(160, (maxLevel + 1) * 130 + 20).toDouble(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Árbol de ascendencia · amplía o desliza para explorar'),
        const SizedBox(height: 8),
        SizedBox(
          height: 380,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: const Color(0xffedf2e9),
              child: InteractiveViewer(
                constrained: false,
                minScale: .3,
                maxScale: 2.5,
                child: CustomPaint(
                  size: size,
                  painter: _TreePainter(
                    members,
                    relationships,
                    positions,
                    Theme.of(context).textTheme.bodyMedium?.fontFamily,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Los vínculos laterales y sus roles aparecen en la lista accesible de abajo.',
        ),
      ],
    );
  }
}

class _TreePainter extends CustomPainter {
  _TreePainter(
    this.members,
    this.relationships,
    this.positions,
    this.fontFamily,
  );
  final String? fontFamily;
  final List<FamilyMember> members;
  final List<RelationshipRecord> relationships;
  final Map<String, Offset> positions;
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppTheme.forest
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final r in relationships.where((r) => r.isAncestry)) {
      final from = positions[r.fromUserId];
      final to = positions[r.toUserId];
      if (from == null || to == null) {
        continue;
      }
      final start = from + const Offset(84, 68);
      final end = to + const Offset(84, 0);
      final mid = (start.dy + end.dy) / 2;
      canvas.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(start.dx, mid, end.dx, mid, end.dx, end.dy),
        line,
      );
      canvas.drawPath(
        Path()
          ..moveTo(end.dx - 5, end.dy - 8)
          ..lineTo(end.dx, end.dy)
          ..lineTo(end.dx + 5, end.dy - 8),
        line,
      );
    }
    for (final member in members) {
      final point = positions[member.userId]!;
      final rect = RRect.fromRectAndRadius(
        point & const Size(168, 68),
        const Radius.circular(14),
      );
      canvas.drawRRect(rect, Paint()..color = Colors.white);
      canvas.drawRRect(rect, line);
      final text = TextPainter(
        text: TextSpan(
          text: member.fullName,
          style: TextStyle(
            fontFamily: fontFamily,
            color: AppTheme.forest,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: 144);
      text.paint(canvas, point + Offset(12, (68 - text.height) / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _TreePainter oldDelegate) => true;
}
