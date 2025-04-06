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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading messages',
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.message_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start connecting with people!',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

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

  Widget _buildUserListItem(Map<String, dynamic> userData, BuildContext context) {
    String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    if (userData['name'] != null && userData['name'] != currentUserEmail) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: userData['profileImageUrl'] != null &&
                      userData['profileImageUrl'].isNotEmpty
                  ? NetworkImage(userData['profileImageUrl'])
                  : null,
              child: userData['profileImageUrl'] == null ||
                      userData['profileImageUrl'].isEmpty
                  ? Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 24,
                    )
                  : null,
            ),
          ),
          title: Text(
            userData['name'] ?? '',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Tap to start chatting',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.primary,
            size: 16,
          ),
          onTap: () {
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
      return Container();
    }
  }
}
