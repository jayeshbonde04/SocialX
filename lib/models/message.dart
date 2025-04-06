import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, audio }
enum MessageStatus { pending, sent, delivered, seen }

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp timestamp;
  final MessageType type;
  final String? mediaUrl;
  final int? audioDuration;
  final MessageStatus status;
  final Timestamp? seenAt;

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.message,
    required this.timestamp,
    this.type = MessageType.text,
    this.mediaUrl,
    this.audioDuration,
    this.status = MessageStatus.sent,
    this.seenAt,
  });

  //convert to a map
  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'timestamp': timestamp,
      'type': type.toString(),
      'mediaUrl': mediaUrl,
      'audioDuration': audioDuration,
      'status': status.toString(),
      'seenAt': seenAt,
    };
  }

  // Create from map
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderID: map['senderID'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      receiverID: map['receiverID'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MessageType.text,
      ),
      mediaUrl: map['mediaUrl'],
      audioDuration: map['audioDuration'],
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      seenAt: map['seenAt'],
    );
  }
}
