import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../models/watch_face_model.dart';

class PlatformBadge extends StatelessWidget {
  const PlatformBadge({
    super.key,
    required this.platform,
    this.compact = false,
  });

  final WatchPlatform platform;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isApple = platform == WatchPlatform.ios;
    final color = isApple ? const Color(0xFF0A84FF) : AppColors.secondary;
    final icon = isApple ? Icons.watch : Icons.watch_outlined;
    final label = isApple ? 'Apple Watch' : 'Galaxy / Wear OS';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentLight, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: Colors.black87),
          SizedBox(width: 3),
          Text(
            'Premium',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
