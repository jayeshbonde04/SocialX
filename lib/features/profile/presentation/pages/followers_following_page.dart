import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:socialx/features/profile/domain/entities/profile_user.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_cubits.dart';
import 'package:socialx/features/profile/presentation/pages/profile_page.dart';
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

class FollowersFollowingPage extends StatefulWidget {
  final String uid;
  final bool isFollowers;
  const FollowersFollowingPage({
    super.key,
    required this.uid,
    required this.isFollowers,
  });

  @override
  State<FollowersFollowingPage> createState() => _FollowersFollowingPageState();
}

class _FollowersFollowingPageState extends State<FollowersFollowingPage> {
  late final authCubit = context.read<AuthCubit>();
  late final profileCubit = context.read<ProfileCubit>();
  AppUsers? currentUser;
  List<ProfileUser> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentUser = authCubit.currentuser;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userList = widget.isFollowers
          ? await profileCubit.getFollowers(widget.uid)
          : await profileCubit.getFollowing(widget.uid);

      setState(() {
        users = userList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading users: ${e.toString()}',
            style: bodyStyle,
          ),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
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
              child: Icon(
                widget.isFollowers
                    ? Icons.people_rounded
                    : Icons.person_add_rounded,
                color: accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.isFollowers ? 'Followers' : 'Following',
              style: titleStyle,
            ),
          ],
        ),
        foregroundColor: textPrimary,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: accentColor,
                strokeWidth: 3,
              ),
            )
          : users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isFollowers
                              ? Icons.people_outline_rounded
                              : Icons.person_add_outlined,
                          size: 64,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.isFollowers
                            ? 'No followers yet'
                            : 'Not following anyone',
                        style: subtitleStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isFollowers
                            ? 'When someone follows you, they\'ll appear here'
                            : 'When you follow someone, they\'ll appear here',
                        style: bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
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
                          backgroundImage: user.profileImageUrl.isNotEmpty
                              ? NetworkImage(user.profileImageUrl)
                              : null,
                          child: user.profileImageUrl.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: textSecondary,
                                  size: 24,
                                )
                              : null,
                        ),
                        title: Text(
                          user.name,
                          style: subtitleStyle,
                        ),
                        subtitle: Text(
                          user.email,
                          style: bodyStyle,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(uid: user.uid),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
