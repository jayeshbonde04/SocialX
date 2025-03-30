import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:socialx/features/posts/presentation/cubits/post_cubit.dart';

import '../../domain/entities/comment.dart';

// Dark mode color scheme
const Color primaryColor = Color(0xFF1A1A1A);
const Color secondaryColor = Color(0xFF2D2D2D);
const Color accentColor = Color(0xFF6C63FF);
const Color backgroundColor = Color(0xFF121212);
const Color surfaceColor = Color(0xFF1E1E1E);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0xFFB3B3B3);
const Color dividerColor = Color(0xFF2D2D2D);
const Color errorColor = Color(0xFFFF4B4B);

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

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser(){
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.currentuser;
    isOwnPost = widget.comment.userId == currentUser!.uid;
  }

  // show option for delete
  void showOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Comment?',
          style: TextStyle(color: textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<PostCubit>().deleteComment(widget.comment.postId, widget.comment.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: errorColor),
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
          //name
          Text(
            widget.comment.userName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: textPrimary,
              fontSize: 14,
            ),
          ),

          const SizedBox(width: 8),

          //comment text
          Expanded(
            child: Text(
              widget.comment.text,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(width: 8),

          //delete button
          if (isOwnPost)
            GestureDetector(
              onTap: showOption,
              child: const Icon(
                Icons.more_horiz,
                color: textSecondary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

  
