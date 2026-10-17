import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Read-only star row (Sprint 11's `rating_stars.dart`).
///
/// Shows five stars filled to [rating] (0-5, halves supported) with an
/// optional review-count suffix.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.reviewCount,
    this.showValue = false,
  });

  final double rating;
  final double size;
  final int? reviewCount;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    final clamped = rating.clamp(0.0, 5.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            clamped >= i
                ? Icons.star_rounded
                : clamped >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: size,
            color: AppTheme.accent,
          ),
        if (showValue) ...[
          const SizedBox(width: 4),
          Text(
            clamped.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: size * 0.75,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Interactive star picker used by the "leave a review" screen.
class RatingStarsInput extends StatelessWidget {
  const RatingStarsInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 36,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            constraints: const BoxConstraints(),
            onPressed: () => onChanged(i),
            icon: Icon(
              i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: AppTheme.accent,
            ),
          ),
      ],
    );
  }
}
