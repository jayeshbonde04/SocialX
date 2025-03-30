import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get Messages
  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    try {
      final snapshot = await _db
          .collection('Chats')
          .doc(chatId)
          .collection('Messages')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Failed to fetch messages');
    }
  }

  // Send Message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      await _db.collection('Chats').doc(chatId).collection('Messages').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      throw Exception('Failed to send message');
    }
  }

  // Mark Message as Read
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _db
          .collection('Chats')
          .doc(chatId)
          .collection('Messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark message as read');
    }
  }
}