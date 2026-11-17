import 'package:flutter/material.dart';
import '../design/tokens.dart';

/// [AnimatedSwitcher] layout that fills the parent; the default centered
/// stack would shrink-wrap and vertically center scroll views.
Widget expandedSwitcherLayout(Widget? current, List<Widget> previous) =>
    Stack(fit: StackFit.expand, children: [...previous, ?current]);

/// One-shot fade and rise used when cards first appear. [index] staggers
/// siblings slightly; it is capped so long lists never wait.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;
  @override
  Widget build(BuildContext context) {
    final base = Motion.of(context, Motion.slow);
    if (base == Duration.zero) return child;
    final delay = Duration(milliseconds: 40 * index.clamp(0, 6));
    final total = base + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: Motion.curve,
      ),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}
