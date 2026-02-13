import 'package:flutter/material.dart';
import '../utils/screen_size.dart';
import '../utils/app_colors.dart';
import '../models/chat_message.dart';

/// Chat Bubble Widget
/// Displays chat messages (user/bot)
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isFailed;
  final VoidCallback? onRetry;
  
  const ChatBubble({
    super.key, 
    required this.message,
    this.isFailed = false,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingMedium : ScreenSize.spacingMedium),
          left: isUser ? (ScreenSize.isLargeTablet ? ScreenSize.paddingLarge : (ScreenSize.isSmallTablet ? ScreenSize.spacingLarge : ScreenSize.spacingLarge)) : 0,
          right: isUser ? 0 : (ScreenSize.isLargeTablet ? ScreenSize.paddingLarge : (ScreenSize.isSmallTablet ? ScreenSize.spacingLarge : ScreenSize.spacingLarge)),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * (ScreenSize.isLargeTablet ? 0.65 : (ScreenSize.isSmallTablet ? 0.72 : 0.75)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: ScreenSize.isLargeTablet ? ScreenSize.paddingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingMedium + 4 : ScreenSize.spacingMedium + 4),
          vertical: ScreenSize.isLargeTablet ? ScreenSize.spacingMedium : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall + 6 : ScreenSize.spacingSmall + 6),
        ),
        decoration: BoxDecoration(
          color: isFailed 
              ? AppColors.error.withOpacity(0.1)
              : (isUser ? AppColors.primary : Colors.white),
          borderRadius: BorderRadius.circular(ScreenSize.isLargeTablet ? 20 : (ScreenSize.isSmallTablet ? 19 : 18)),
          border: isFailed 
              ? Border.all(color: AppColors.error.withOpacity(0.5), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: isFailed
                  ? AppColors.error.withOpacity(0.2)
                  : (isUser 
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.black.withOpacity(0.08)),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                fontSize: ScreenSize.isLargeTablet ? ScreenSize.textLarge : (ScreenSize.isSmallTablet ? ScreenSize.textMedium : ScreenSize.textMedium),
                color: isFailed 
                    ? AppColors.error
                    : (isUser ? AppColors.textWhite : AppColors.textPrimary),
                height: 1.4,
              ),
            ),
            if (isFailed) ...[
              SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingXSmall : (ScreenSize.isSmallTablet ? ScreenSize.spacingExtraSmall : ScreenSize.spacingExtraSmall)),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ScreenSize.isLargeTablet ? ScreenSize.spacingSmall : (ScreenSize.isSmallTablet ? ScreenSize.spacingSmall : ScreenSize.spacingSmall),
                    vertical: ScreenSize.isLargeTablet ? 4 : (ScreenSize.isSmallTablet ? 3 : 2),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ScreenSize.isLargeTablet ? 8 : (ScreenSize.isSmallTablet ? 7 : 6)),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: ScreenSize.isLargeTablet ? ScreenSize.iconSmall * 0.7 : (ScreenSize.isSmallTablet ? 12 : 11),
                        color: AppColors.error,
                      ),
                      SizedBox(width: ScreenSize.isLargeTablet ? ScreenSize.spacingXSmall : (ScreenSize.isSmallTablet ? 4 : 3)),
                      Text(
                        'Tap to retry',
                        style: TextStyle(
                          fontSize: ScreenSize.isLargeTablet ? ScreenSize.textSmall : (ScreenSize.isSmallTablet ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall),
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: ScreenSize.isLargeTablet ? ScreenSize.spacingXSmall : (ScreenSize.isSmallTablet ? ScreenSize.spacingExtraSmall : ScreenSize.spacingExtraSmall)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: ScreenSize.isLargeTablet ? ScreenSize.textSmall : (ScreenSize.isSmallTablet ? ScreenSize.textExtraSmall : ScreenSize.textExtraSmall),
                    color: isFailed
                        ? AppColors.error.withOpacity(0.7)
                        : (isUser 
                            ? AppColors.textWhite.withOpacity(0.7)
                            : AppColors.textSecondary),
                  ),
                ),
                if (isUser && !isFailed) ...[
                  SizedBox(width: ScreenSize.isLargeTablet ? ScreenSize.spacingXSmall : (ScreenSize.isSmallTablet ? ScreenSize.spacingExtraSmall : ScreenSize.spacingExtraSmall)),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: ScreenSize.isLargeTablet ? ScreenSize.iconSmall * 0.6 : (ScreenSize.isSmallTablet ? 13 : 12),
                    color: AppColors.textWhite.withOpacity(0.7),
                  ),
                ],
                if (isFailed) ...[
                  SizedBox(width: ScreenSize.isLargeTablet ? ScreenSize.spacingXSmall : (ScreenSize.isSmallTablet ? ScreenSize.spacingExtraSmall : ScreenSize.spacingExtraSmall)),
                  Icon(
                    Icons.error_outline,
                    size: ScreenSize.isLargeTablet ? ScreenSize.iconSmall * 0.6 : (ScreenSize.isSmallTablet ? 13 : 12),
                    color: AppColors.error,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inMinutes < 1) {
        return 'Just now';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (e) {
      return dateTime;
    }
  }
}

