import 'package:flutter/material.dart';
import 'package:socialx/features/notifications/domain/entities/notification.dart' as app_notification;

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  // Store the current overlay entry
  OverlayEntry? _currentOverlay;
  
  // Store the current context
  BuildContext? _context;
  
  // Store the current navigator key
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  // Get the navigator key
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  // Initialize the service with a context
  void initialize(BuildContext context) {
    _context = context;
    print('InAppNotificationService: Initialized with context');
  }

  // Show a notification
  void showNotification(app_notification.Notification notification) {
    print('InAppNotificationService: Showing notification for: ${notification.id}');
    
    // Get the current context
    final context = _context;
    if (context == null) {
      print('InAppNotificationService: No context available, cannot show notification');
      return;
    }
    
    // Remove any existing notification
    _removeCurrentNotification();
    
    // Get notification details
    final String title = _getNotificationTitle(notification);
    final String body = _getNotificationBody(notification);
    final Color color = _getNotificationColor(notification.type);
    final IconData icon = _getNotificationIcon(notification.type);
    
    // Create the overlay entry
    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          child: InkWell(
            onTap: () {
              _removeCurrentNotification();
              // Navigate to the notifications page
              Navigator.pushNamed(context, '/notifications');
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.5), width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _removeCurrentNotification,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    // Insert the overlay
    Overlay.of(context).insert(_currentOverlay!);
    
    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _removeCurrentNotification();
    });
    
    print('InAppNotificationService: Notification shown successfully');
  }
  
  // Remove the current notification
  void _removeCurrentNotification() {
    if (_currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
    }
  }

  String _getNotificationTitle(app_notification.Notification notification) {
    final actorName = notification.metadata?['actorName'] ?? 'Someone';
    
    switch (notification.type) {
      case app_notification.NotificationType.like:
        return 'New Like';
      case app_notification.NotificationType.comment:
        return 'New Comment';
      case app_notification.NotificationType.follow:
        return 'New Follower';
      case app_notification.NotificationType.message:
        return 'New Message';
      case app_notification.NotificationType.post:
        return 'New Post';
    }
  }

  String _getNotificationBody(app_notification.Notification notification) {
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
} 