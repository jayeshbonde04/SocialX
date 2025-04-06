import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialx/features/notifications/domain/entities/notification.dart' as app_notification;
import 'package:socialx/features/notifications/presentation/cubits/notification_cubit.dart';
import 'package:socialx/themes/app_colors.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationItem extends StatelessWidget {
  final app_notification.Notification notification;
  final VoidCallback onTap;

  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  IconData _getNotificationIcon(app_notification.NotificationType type) {
    switch (type) {
      case app_notification.NotificationType.like:
        return Icons.favorite_rounded;
      case app_notification.NotificationType.comment:
        return Icons.comment_rounded;
      case app_notification.NotificationType.follow:
        return Icons.person_add_rounded;
      case app_notification.NotificationType.followRequest:
        return Icons.person_add_outlined;
      case app_notification.NotificationType.message:
        return Icons.message_rounded;
      case app_notification.NotificationType.post:
        return Icons.post_add_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(app_notification.NotificationType type) {
    switch (type) {
      case app_notification.NotificationType.like:
        return Colors.red;
      case app_notification.NotificationType.comment:
        return Colors.blue;
      case app_notification.NotificationType.follow:
        return Colors.green;
      case app_notification.NotificationType.followRequest:
        return Colors.orange;
      case app_notification.NotificationType.message:
        return Colors.orange;
      case app_notification.NotificationType.post:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getNotificationMessage(app_notification.Notification notification) {
    final actorName = notification.metadata?['actorName'] ?? 'Someone';
    
    switch (notification.type) {
      case app_notification.NotificationType.like:
        return '$actorName liked your post';
      case app_notification.NotificationType.comment:
        return '$actorName commented on your post';
      case app_notification.NotificationType.follow:
        return '$actorName started following you';
      case app_notification.NotificationType.followRequest:
        return '$actorName sent you a follow request';
      case app_notification.NotificationType.message:
        return '$actorName sent you a message';
      case app_notification.NotificationType.post:
        return '$actorName posted something new';
      default:
        return 'New notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);
    final message = _getNotificationMessage(notification);
    final timeAgo = timeago.format(notification.timestamp);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        message,
        style: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(
        timeAgo,
        style: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: notification.type == app_notification.NotificationType.followRequest
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Accept follow request
                    context.read<NotificationCubit>().acceptFollowRequest(notification).then((_) {
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Follow request accepted',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }).catchError((error) {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to accept follow request: $error',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Accept',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    // Reject follow request
                    context.read<NotificationCubit>().rejectFollowRequest(notification).then((_) {
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Follow request declined',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red.shade400,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }).catchError((error) {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to decline follow request: $error',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.textPrimary.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Decline',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          : notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
      onTap: onTap,
    );
  }
} 