import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TweetCard extends StatelessWidget {
  final String name;
  final String username;
  final String message;
  final String imageUrl;
  final DateTime timestamp;
  final int likes;
  final List<String> likedBy;
  final VoidCallback onLikePressed;
  final VoidCallback onDeletePressed;
  final String uid;

  const TweetCard({
    super.key,
    required this.name,
    required this.username,
    required this.message,
    required this.imageUrl,
    required this.timestamp,
    required this.likes,
    required this.likedBy,
    required this.onLikePressed,
    required this.onDeletePressed,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnTweet = currentUser?.uid == uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
                  child: imageUrl.isEmpty
                      ? Text(name[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '@$username',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeago.format(timestamp),
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Tweet message
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        likedBy.contains(username)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: likedBy.contains(username)
                            ? Colors.red
                            : Colors.grey,
                      ),
                      onPressed: onLikePressed,
                    ),
                    Text(
                      likes.toString(),
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (isOwnTweet)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.grey,
                    onPressed: onDeletePressed,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 