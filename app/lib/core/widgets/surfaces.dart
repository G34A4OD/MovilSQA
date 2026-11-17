import 'package:flutter/material.dart';
import '../design/tokens.dart';
import 'feedback.dart';

/// Rounded tinted square that anchors a row or card visually.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.tone = Tone.info,
    this.size = 40,
  });
  final IconData icon;
  final Tone tone;
  final double size;
  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.container(tone),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: palette.foreground(tone, scheme),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff3b82f6), AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Icon(
        Icons.cottage_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    ),
  );
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name, this.size = 40, this.icon});
  final String name;
  final double size;
  final IconData? icon;

  static const _tints = [
    (Color(0xffdbeafe), Color(0xff1d4ed8)),
    (Color(0xffdcfce7), Color(0xff15803d)),
    (Color(0xfffef3c7), Color(0xffb45309)),
    (Color(0xfffce7f3), Color(0xffbe185d)),
    (Color(0xffe0e7ff), Color(0xff4338ca)),
    (Color(0xffccfbf1), Color(0xff0f766e)),
  ];

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tint =
        _tints[name.codeUnits.fold<int>(0, (a, b) => a + b) % _tints.length];
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? tint.$2.withValues(alpha: 0.28) : tint.$1,
        ),
        child: icon != null
            ? Icon(icon, size: size * 0.5, color: dark ? tint.$1 : tint.$2)
            : Text(
                initials,
                style: TextStyle(
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w700,
                  color: dark ? tint.$1 : tint.$2,
                ),
              ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = Tone.neutral,
    this.icon,
  });
  final String label;
  final Tone tone;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = palette.foreground(tone, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.container(tone),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: Space.xxs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen-level title block.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(eyebrow!.toUpperCase(), style: text.labelSmall),
                const SizedBox(height: Space.xxs + 2),
              ],
              Semantics(
                header: true,
                child: Text(title, style: text.headlineSmall),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: Space.xxs + 2),
                Text(
                  subtitle!,
                  style: text.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: Space.sm), trailing!],
      ],
    );
  }
}

/// Label above a group of cards.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: Space.lg,
      bottom: Space.xs,
      left: Space.xxs,
    ),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        ?action,
      ],
    ),
  );
}

/// Card with icon header, refresh, progress and message slots. Panels share
/// it so loading and error feedback looks the same everywhere.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.tone = Tone.info,
    this.subtitle,
    this.onRefresh,
    this.refreshTooltip,
    this.busy = false,
    this.message,
    this.messageTone = Tone.danger,
    this.trailing,
  });
  final String title;
  final IconData? icon;
  final Tone tone;
  final String? subtitle;
  final VoidCallback? onRefresh;
  final String? refreshTooltip;
  final bool busy;
  final String? message;
  final Tone messageTone;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.md,
          Space.md,
          Space.xs,
          Space.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  IconTile(icon: icon!, tone: tone),
                  const SizedBox(width: Space.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(title, style: text.titleMedium),
                      ),
                      if (subtitle != null)
                        Text(subtitle!, style: text.bodySmall),
                    ],
                  ),
                ),
                ?trailing,
                if (refreshTooltip != null)
                  IconButton(
                    tooltip: refreshTooltip,
                    onPressed: busy ? null : onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: Space.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: Space.sm),
                  LoadingStrip(busy: busy),
                  InlineMessage(text: message, tone: messageTone),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact label/value block used in summaries.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone = Tone.neutral,
    this.valueKey,
  });
  final String label;
  final String value;
  final IconData icon;
  final Tone tone;
  final Key? valueKey;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          IconTile(icon: icon, tone: tone, size: 34),
          const SizedBox(width: Space.sm - 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    key: valueKey,
                    maxLines: 1,
                    style: moneyStyle(
                      text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
