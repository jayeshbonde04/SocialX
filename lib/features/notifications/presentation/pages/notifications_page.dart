import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:socialx/features/notifications/domain/entities/notification.dart' as app_notification;
import 'package:socialx/features/notifications/presentation/cubits/notification_cubit.dart';
import 'package:socialx/features/notifications/presentation/cubits/notification_states.dart';
import 'package:socialx/themes/app_colors.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    final currentUser = context.read<AuthCubit>().currentuser;
    if (currentUser != null) {
      context.read<NotificationCubit>().initializeNotifications(currentUser.uid);
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
      case app_notification.NotificationType.message:
        return '$actorName sent you a message';
      case app_notification.NotificationType.post:
        return '$actorName posted something new';
    }
  }

  IconData _getNotificationIcon(app_notification.NotificationType type) {
    switch (type) {
      case app_notification.NotificationType.like:
        return Icons.favorite_rounded;
      case app_notification.NotificationType.comment:
        return Icons.comment_rounded;
      case app_notification.NotificationType.follow:
        return Icons.person_add_rounded;
      case app_notification.NotificationType.message:
        return Icons.message_rounded;
      case app_notification.NotificationType.post:
        return Icons.post_add_rounded;
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
      case app_notification.NotificationType.message:
        return Colors.orange;
      case app_notification.NotificationType.post:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: AppColors.accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Notifications',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          ],
        ),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              return IconButton(
                onPressed: () {
                  final currentUser = context.read<AuthCubit>().currentuser;
                  if (currentUser != null) {
                    context.read<NotificationCubit>().markAllAsRead(currentUser.uid);
                  }
                },
                icon: const Icon(
                  Icons.done_all_rounded,
                  color: AppColors.accent,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 3,
              ),
            );
          } else if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_off_rounded,
                        size: 64,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When someone interacts with your content,\nyou\'ll see it here',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async {
                final currentUser = context.read<AuthCubit>().currentuser;
                if (currentUser != null) {
                  context
                      .read<NotificationCubit>()
                      .initializeNotifications(currentUser.uid);
                }
                return Future.value();
              },
              child: ListView.builder(
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red.shade100,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                    onDismissed: (direction) async {
                      final deletedNotification = notification;
                      // Update UI state immediately
                      final currentState = context.read<NotificationCubit>().state;
                      if (currentState is NotificationLoaded) {
                        final updatedNotifications = List<app_notification.Notification>.from(currentState.notifications)
                          ..removeWhere((n) => n.id == notification.id);
                        context.read<NotificationCubit>().emit(NotificationLoaded(updatedNotifications));
                      }
                      
                      // Then delete from repository
                      await context
                          .read<NotificationCubit>()
                          .deleteNotification(notification.id);
                          
                      if (!context.mounted) return;
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Notification deleted',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
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
                    },
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getNotificationColor(notification.type)
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNotificationIcon(notification.type),
                          color: _getNotificationColor(notification.type),
                        ),
                      ),
                      title: Text(
                        _getNotificationMessage(notification),
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontWeight:
                              notification.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        timeago.format(notification.timestamp),
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: notification.isRead
                          ? null
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                      onTap: () {
                        if (!notification.isRead) {
                          context
                              .read<NotificationCubit>()
                              .markAsRead(notification.id);
                        }
                      },
                    ),
                  );
                },
              ),
            );
          } else if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}