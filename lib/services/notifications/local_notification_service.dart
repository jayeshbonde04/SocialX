import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socialx/features/notifications/domain/entities/notification.dart' as app_notification;
import 'dart:typed_data';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    print('LocalNotificationService: Initializing local notifications');
    
    // Initialize settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Initialize settings for iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    // Initialize settings for all platforms
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        print('LocalNotificationService: Notification tapped: ${notificationResponse.payload}');
        // Handle notification tap
      },
    );
    
    print('LocalNotificationService: Local notifications initialized');
  }

  Future<void> showNotification(app_notification.Notification notification) async {
    print('LocalNotificationService: Showing notification for: ${notification.id}');
    
    // Get notification details based on type
    final String title = _getNotificationTitle(notification);
    final String body = _getNotificationBody(notification);
    final int notificationId = notification.id.hashCode;
    
    // Create Android notification details
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'socialx_notifications', // channel id
      'SocialX Notifications', // channel name
      channelDescription: 'Notifications from SocialX app', // channel description
      importance: Importance.max, // importance level
      priority: Priority.high, // priority level
      showWhen: true, // show timestamp
      enableVibration: true, // enable vibration
      enableLights: true, // enable lights
      color: _getNotificationColor(notification.type), // notification color
      icon: '@mipmap/ic_launcher', // notification icon
      colorized: false, // disable colorized notifications to ensure text visibility
      styleInformation: DefaultStyleInformation(true, true), // use default style with title and body
      category: AndroidNotificationCategory.message, // set category
      fullScreenIntent: false, // disable full screen intent
      visibility: NotificationVisibility.public, // make notification visible on lock screen
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('open', 'Open'),
        AndroidNotificationAction('dismiss', 'Dismiss'),
      ],
      ticker: 'New notification', // add ticker text
      channelShowBadge: true, // show badge on channel
      playSound: true, // play sound
      sound: const RawResourceAndroidNotificationSound('notification_sound'), // custom sound
      vibrationPattern: Int64List.fromList([0, 100, 200, 300]), // vibration pattern
    );
    
    // Create iOS notification details
    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true, // present alert
      presentBadge: true, // present badge
      presentSound: true, // present sound
      interruptionLevel: InterruptionLevel.timeSensitive, // set interruption level
      threadIdentifier: 'socialx_notifications', // set thread identifier
    );
    
    // Create notification details for all platforms
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Show the notification
    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: notification.id, // payload to identify the notification
    );
    
    print('LocalNotificationService: Notification shown successfully');
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
      default:
        return 'New Notification'; // Default case to ensure a non-null return
    }
  }

  String _getNotificationBody(app_notification.Notification notification) {
    final actorName = notification.metadata?['actorName'] ?? 'Someone';
    final contentPreview = notification.metadata?['content'] ?? '';
    
    switch (notification.type) {
      case app_notification.NotificationType.like:
        return '$actorName liked your post';
      case app_notification.NotificationType.comment:
        return '$actorName commented: "$contentPreview"';
      case app_notification.NotificationType.follow:
        return '$actorName started following you';
      case app_notification.NotificationType.message:
        return '$actorName: "$contentPreview"';
      case app_notification.NotificationType.post:
        return '$actorName posted: "$contentPreview"';
      default:
        return 'You have a new notification'; // Default case to ensure a non-null return
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
    }
  }
}