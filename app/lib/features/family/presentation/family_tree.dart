import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.pinch_outlined,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Text(
                'Árbol de ascendencia · amplía o desliza para explorar',
                style: text.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xs),
        Container(
          height: 380,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(Radii.md + 2),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.md + 2),
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
                  text.bodyMedium?.fontFamily,
                  line: scheme.primary,
                  node: scheme.surface,
                  nodeBorder: scheme.outline,
                  label: scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.xs),
        Text(
          'Los vínculos laterales y sus roles aparecen en la lista accesible de abajo.',
          style: text.bodySmall,
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
    this.fontFamily, {
    required this.line,
    required this.node,
    required this.nodeBorder,
    required this.label,
  });
  final String? fontFamily;
  final Color line;
  final Color node;
  final Color nodeBorder;
  final Color label;
  final List<FamilyMember> members;
  final List<RelationshipRecord> relationships;
  final Map<String, Offset> positions;
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = line
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final border = Paint()
      ..color = nodeBorder
      ..strokeWidth = 1.2
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
        stroke,
      );
      canvas.drawPath(
        Path()
          ..moveTo(end.dx - 5, end.dy - 8)
          ..lineTo(end.dx, end.dy)
          ..lineTo(end.dx + 5, end.dy - 8),
        stroke,
      );
    }
    for (final member in members) {
      final point = positions[member.userId]!;
      final rect = RRect.fromRectAndRadius(
        point & const Size(168, 68),
        const Radius.circular(14),
      );
      canvas.drawRRect(
        rect.shift(const Offset(0, 3)),
        Paint()
          ..color = const Color(0x140f172a)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawRRect(rect, Paint()..color = node);
      canvas.drawRRect(rect, border);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(point.dx, point.dy + 14, 4, 40),
          topRight: const Radius.circular(2),
          bottomRight: const Radius.circular(2),
        ),
        Paint()..color = line,
      );
      final text = TextPainter(
        text: TextSpan(
          text: member.fullName,
          style: TextStyle(
            fontFamily: fontFamily,
            color: label,
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
