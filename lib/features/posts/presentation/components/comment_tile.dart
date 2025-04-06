import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:socialx/features/posts/presentation/cubits/post_cubit.dart';
import 'package:socialx/themes/app_colors.dart';
import 'package:socialx/features/profile/presentation/pages/profile_page.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_cubits.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/entities/comment.dart';

class CommentTile extends StatefulWidget {
  final Comment comment;
  const CommentTile({super.key, required this.comment});

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  // current user
  AppUsers? currentUser;
  bool isOwnPost = false;
  String? profileImageUrl;

  @override
  void initState() {
    getCurrentUser();
    fetchUserProfile();
    super.initState();
  }

  void getCurrentUser() {
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.currentuser;
    isOwnPost = widget.comment.userId == currentUser!.uid;
  }

  Future<void> fetchUserProfile() async {
    final profileCubit = context.read<ProfileCubit>();
    final userProfile = await profileCubit.getUserProfile(widget.comment.userId);
    if (userProfile != null) {
      setState(() {
        profileImageUrl = userProfile.profileImageUrl;
      });
    }
  }

  // show option for delete
  void showOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Comment?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<PostCubit>().deleteComment(widget.comment.postId, widget.comment.id);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(uid: widget.comment.userId),
                ),
              );
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentWithOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: profileImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.accentWithOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            color: AppColors.accent,
                            size: 16,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.accentWithOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            color: AppColors.accent,
                            size: 16,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.accentWithOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: AppColors.accent,
                          size: 16,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(uid: widget.comment.userId),
                      ),
                    );
                  },
                  child: Text(
                    widget.comment.userName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Comment text
                Text(
                  widget.comment.text,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          if (isOwnPost)
            GestureDetector(
              onTap: showOption,
              child: Icon(
                Icons.more_horiz,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

  
