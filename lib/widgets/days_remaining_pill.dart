import 'dart:ui';

import 'package:flutter/material.dart';

class DaysRemainingPill extends StatelessWidget {
  const DaysRemainingPill({super.key, required this.target});

  final DateTime target;

  @override
  Widget build(BuildContext context) {
    final days = target.difference(DateTime.now()).inDays;
    final urgent = days <= 0;
    final soon = days == 1;
    final label = urgent ? 'Today' : soon ? 'Tomorrow' : '$days days';
    final tint = urgent
        ? const Color(0xffff5c7a)
        : soon
            ? const Color(0xffffb648)
            : Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (urgent ? tint : Colors.black).withValues(alpha: urgent ? 0.24 : 0.35),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tint.withValues(alpha: urgent || soon ? 0.7 : 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (urgent) ...[
                Icon(Icons.bolt_rounded, size: 12, color: tint),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  color: urgent || soon ? tint : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
