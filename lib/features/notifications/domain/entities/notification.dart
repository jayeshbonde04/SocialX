import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  like,
  comment,
  follow,
  followRequest,
  message,
  post,
}

class Notification {
  final String id;
  final String userId;
  final String actorId;
  final NotificationType type;
  final String? postId;
  final String? commentId;
  final bool isRead;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  Notification({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.type,
    this.postId,
    this.commentId,
    this.isRead = false,
    required this.timestamp,
    this.metadata,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    // Parse the notification type
    NotificationType type;
    try {
      final typeString = json['type'] as String;
      print('Notification.fromJson: Parsing notification type: $typeString');
      
      type = NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == typeString,
        orElse: () {
          print('Notification.fromJson: Type not found, defaulting to like');
          return NotificationType.like; // Default to like if not found
        },
      );
      
      print('Notification.fromJson: Successfully parsed type: ${type.toString()}');
    } catch (e) {
      print('Notification.fromJson: Error parsing type: $e');
      type = NotificationType.like; // Default to like if there's an error
    }

    return Notification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      actorId: json['actorId'] as String,
      type: type,
      postId: json['postId'] as String?,
      commentId: json['commentId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'actorId': actorId,
      'type': type.toString().split('.').last,
      'postId': postId,
      'commentId': commentId,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  Notification copyWith({
    String? id,
    String? userId,
    String? actorId,
    NotificationType? type,
    String? postId,
    String? commentId,
    bool? isRead,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
} 