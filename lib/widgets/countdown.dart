import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Rebuilds [builder] once a second with the current time.
class Ticker extends StatefulWidget {
  const Ticker({super.key, required this.builder});

  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}

/// Each character rolls up into place when it changes, like a mechanical
/// counter. Unchanged characters stay still.
class RollingText extends StatelessWidget {
  const RollingText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final chars = text.split('');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chars.length; i++)
          ClipRect(
            child: AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) {
                final incoming = child.key == ValueKey('${chars.length - i}-${chars[i]}');
                final offset = Tween(begin: Offset(0, incoming ? 0.9 : -0.9), end: Offset.zero).animate(anim);
                return SlideTransition(
                  position: offset,
                  child: FadeTransition(opacity: anim, child: child),
                );
              },
              layoutBuilder: (current, previous) =>
                  Stack(alignment: Alignment.center, children: [...previous, ?current]),
              // Key from the right edge so digits keep identity when the
              // string shrinks (e.g. 10 days -> 9 days).
              child: Text(chars[i], key: ValueKey('${chars.length - i}-${chars[i]}'), style: style),
            ),
          ),
      ],
    );
  }
}

class _Segment {
  const _Segment(this.value, this.unit);
  final String value;
  final String unit;
}

List<_Segment> _segmentsFor(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final days = d.inDays;
  final h = d.inHours % 24;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;

  if (days >= 100) return [_Segment('$days', 'days')];
  if (days >= 1) {
    return [_Segment('$days', days == 1 ? 'day' : 'days'), _Segment(two(h), 'hrs'), _Segment(two(m), 'min')];
  }
  return [_Segment(two(d.inHours), 'hrs'), _Segment(two(m), 'min'), _Segment(two(s), 'sec')];
}

/// The marquee countdown: huge condensed numerals with a quiet unit word
/// under each group. Drops seconds once more than a day out so the number
/// that changes is the one that matters.
class MarqueeCountdown extends StatelessWidget {
  const MarqueeCountdown({
    super.key,
    required this.target,
    this.size = 88,
    this.color = KColors.text,
    this.separatorColor = KColors.sodium,
    this.arrivedLabel = 'Out now',
  });

  final DateTime target;
  final double size;
  final Color color;
  final Color separatorColor;
  final String arrivedLabel;

  @override
  Widget build(BuildContext context) {
    return Ticker(
      builder: (context, now) {
        final remaining = target.difference(now);
        if (remaining.isNegative || remaining == Duration.zero) {
          return Text(arrivedLabel, style: KType.numerals(size * 0.8, color: color));
        }

        final segments = _segmentsFor(remaining);
        final numStyle = KType.numerals(size, color: color);

        return Semantics(
          label: segments.map((s) => '${int.parse(s.value)} ${s.unit}').join(', '),
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: size * 0.06),
                    child: Text(
                      ':',
                      style: numStyle.copyWith(color: separatorColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RollingText(segments[i].value, style: numStyle),
                    SizedBox(height: size * 0.08),
                    Text(segments[i].unit, style: KType.small.copyWith(fontSize: (size * 0.15).clamp(11, 15))),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
