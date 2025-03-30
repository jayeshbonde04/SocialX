import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialx/features/chats/presentation/pages/chat_page.dart';
import 'package:socialx/services/database/database_service.dart';
import 'package:socialx/themes/app_colors.dart';

// Reuse the same color scheme
const Color primaryColor = Color(0xFF1A1A1A);
const Color secondaryColor = Color(0xFF2D2D2D);
const Color accentColor = Color(0xFF6C63FF);
const Color backgroundColor = Color(0xFF121212);
const Color surfaceColor = Color(0xFF1E1E1E);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0xFFB3B3B3);
const Color dividerColor = Color(0xFF2D2D2D);
const Color errorColor = Color(0xFFFF4B4B);

// Text styles
final TextStyle titleStyle = GoogleFonts.poppins(
  color: AppColors.textPrimary,
  fontWeight: FontWeight.bold,
  fontSize: 24,
  letterSpacing: 0.5,
);

final TextStyle subtitleStyle = GoogleFonts.poppins(
  color: AppColors.textSecondary,
  fontSize: 16,
  fontWeight: FontWeight.w500,
);

final TextStyle bodyStyle = GoogleFonts.poppins(
  color: AppColors.textSecondary,
  fontSize: 14,
);

class DisplayUser extends StatefulWidget {
  const DisplayUser({super.key});

  @override
  State<DisplayUser> createState() => _DisplayUserState();
}

class _DisplayUserState extends State<DisplayUser> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: textPrimary),
        elevation: 0,
        backgroundColor: surfaceColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.message_rounded,
                color: accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Messages',
              style: titleStyle,
            ),
          ],
        ),
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getUserStream(),
      builder: (context, snapshot) {
        // Error case
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: errorColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading users',
                  style: subtitleStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: bodyStyle,
                ),
              ],
            ),
          );
        }

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: accentColor,
              strokeWidth: 3,
            ),
          );
        }

        // Check if data exists
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_outline_rounded,
                    size: 64,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: subtitleStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start following people to message them',
                  style: bodyStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Return list
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final userData = snapshot.data![index];
            return _buildUserListItem(userData, context);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    if (userData['name'] != null && userData['name'] != currentUserEmail) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: accentColor.withOpacity(0.1),
            child: const Icon(
              Icons.person_rounded,
              color: accentColor,
              size: 24,
            ),
          ),
          title: Text(
            userData['name'] ?? '',
            style: subtitleStyle,
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: textSecondary,
            size: 16,
          ),
          onTap: () {
            print("Tapped on user: ${userData['name']}");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  receiverUserEmail: userData["name"],
                  receiverUserID: userData['uid'],
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Container(); // Hide current user
    }
  }
}
