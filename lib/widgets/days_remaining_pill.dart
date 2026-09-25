import 'dart:ui';

import 'package:flutter/material.dart';

class DaysRemainingPill extends StatelessWidget {
  const DaysRemainingPill({super.key, required this.target});

  final DateTime target;

  @override
  Widget build(BuildContext context) {
    final days = target.difference(DateTime.now()).inDays;
    final label = days <= 0 ? 'Today' : days == 1 ? '1 day' : '$days days';

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
