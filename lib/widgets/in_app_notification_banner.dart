import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../utils/app_colors.dart';

/// Slide-down banner — feels like a real push when the app is open.
class InAppNotificationBanner {
  InAppNotificationBanner._();

  static OverlayEntry? _entry;
  static Timer? _dismissTimer;

  static void show({
    required String title,
    required String message,
    IconData icon = Icons.notifications_active_rounded,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 5),
  }) {
    final overlay = Get.overlayContext;
    if (overlay == null) return;

    dismiss();
    HapticFeedback.mediumImpact();

    _entry = OverlayEntry(
      builder: (context) {
        final top = MediaQuery.paddingOf(context).top + 8;
        return Positioned(
          top: top,
          left: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -1, end: 0),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value * 120),
                  child: child,
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    dismiss();
                    onTap?.call();
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.3,
                                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close, size: 18),
                          color: AppColors.textSecondary,
                          onPressed: dismiss,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    final state = Overlay.of(overlay);
    state.insert(_entry!);

    _dismissTimer = Timer(duration, dismiss);
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _entry?.remove();
    _entry = null;
  }
}
