import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Brand hero using the player photo supplied with the redesign brief.
class PlayerHeroBanner extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double height;

  const PlayerHeroBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.height = 224,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppTheme.primary),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 4, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9FF4E4),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.55,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE2F4EF),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 40,
                          child: FilledButton.icon(
                            onPressed: onAction,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: AppTheme.textPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            icon: const Icon(Icons.sports_cricket, size: 17),
                            label: Text(
                              actionLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: SizedBox.expand(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/player_hero.png',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0.03, -0.06),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppTheme.primary,
                              Color(0xCC006B5C),
                              Color(0x00006B5C),
                            ],
                            stops: [0, 0.25, 0.8],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
