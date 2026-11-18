import 'package:flutter/material.dart';
import '../design/tokens.dart';

/// Thin progress bar with reserved height so content does not jump.
class LoadingStrip extends StatelessWidget {
  const LoadingStrip({super.key, required this.busy});
  final bool busy;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 3,
    child: busy
        ? ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: const LinearProgressIndicator(semanticsLabel: 'Cargando'),
          )
        : null,
  );
}

/// Tinted banner for view-model messages. Collapses when [text] is null.
class InlineMessage extends StatelessWidget {
  const InlineMessage({super.key, required this.text, this.tone = Tone.info});
  final String? text;
  final Tone tone;
  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = palette.foreground(tone, Theme.of(context).colorScheme);
    return AnimatedSize(
      duration: Motion.of(context, Motion.medium),
      curve: Motion.curve,
      alignment: Alignment.topCenter,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Semantics(
                liveRegion: true,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.sm,
                    vertical: Space.sm - 2,
                  ),
                  decoration: BoxDecoration(
                    color: palette.container(tone),
                    borderRadius: BorderRadius.circular(Radii.md - 2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          switch (tone) {
                            Tone.danger => Icons.error_outline_rounded,
                            Tone.warning => Icons.warning_amber_rounded,
                            Tone.success => Icons.check_circle_outline_rounded,
                            _ => Icons.info_outline_rounded,
                          },
                          size: 18,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Text(
                          text!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.compact = false,
  });
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final size = compact ? 44.0 : 64.0;
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact ? Space.md : Space.xxl,
        horizontal: Space.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: size * 0.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: compact ? Space.sm : Space.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: compact ? text.bodyMedium : text.titleMedium,
          ),
          if (message != null) ...[
            const SizedBox(height: Space.xxs),
            Text(message!, textAlign: TextAlign.center, style: text.bodySmall),
          ],
          if (action != null) ...[const SizedBox(height: Space.md), action!],
        ],
      ),
    );
  }
}
