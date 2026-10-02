import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';

/// Oversized, tactile key for the live scoring pad.
class ScoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;
  final int flex;

  const ScoreButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final background = color ?? AppTheme.surface;
    final foreground = textColor ??
        (color == null ? AppTheme.textPrimary : Colors.white);
    final labelSize = label.length > 3 ? 14.0 : label.length > 2 ? 18.0 : 30.0;

    return Expanded(
      flex: flex,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: color == null
              ? const BorderSide(color: AppTheme.border)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: labelSize,
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
