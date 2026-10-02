import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';

/// Big, thumb-friendly scoring button (UI/UX doc Screen 2).
/// 0 and 1 are the most-tapped -> keep them near the thumb rest zone.
class ScoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final int flex;

  const ScoreButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppTheme.surface;

    return Expanded(
      flex: flex,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact(); // subtle tap feedback
            onTap();
          },
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: label.length > 2 ? 20 : 30,
                fontWeight: FontWeight.bold,
                color: bg == AppTheme.surface
                    ? AppTheme.textPrimary
                    : AppTheme.background,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
