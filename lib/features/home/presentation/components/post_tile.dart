import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:socialx/features/posts/presentation/cubits/post_cubit.dart';

import '../../../posts/domain/entities/post.dart';
import '../../../profile/domain/entities/profile_user.dart';
import '../../../profile/presentation/cubits/profile_cubits.dart';

class PostTile extends StatefulWidget {
  final Post post;
  final void Function()? onDeletePressed;
  const PostTile({super.key, required this.post, required this.onDeletePressed});

  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> {
  //cubits
  late final postCubit = context.read<PostCubit>();
  late final profileCubit = context.read<ProfileCubit>();

  bool isOwnPost = false;

  //current user
  AppUsers? currentUser;

  // post User
  ProfileUser? postUser;

  //on startup
  @override
  void initState() {
    super.initState();

    getCurrentUser();
    fetchPostUser();
  }

  void getCurrentUser(){
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.currentuser;
    isOwnPost = (widget.post.userId == currentUser!.uid);
  }

  Future<void> fetchPostUser() async{
    final fetchUser = await profileCubit.getUserProfile(widget.post.userId);
    if(fetchUser != null){
      setState(() {
        postUser = fetchUser;
      });
    }
  }

  // Show options for deletion
  void showOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),

          // Delete button
          TextButton(
            onPressed: () {
              widget.onDeletePressed?.call();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.secondary,
      child: Column(
        children: [
          // Name
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              //top selection: profile pic? name/ delete
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                //profile pic
                postUser?.profileImageUrl != null? CachedNetworkImage(
                    imageUrl: postUser!.profileImageUrl,
                errorWidget: (context, url, error)=> const Icon(Icons.person),
                  imageBuilder: (context, imageProvider)=> Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                          image: imageProvider,
                        fit: BoxFit.cover
                      ),
                    ),
                  ),
                ) : const Icon(Icons.person),

                const SizedBox(width: 10,),

                //name
                Text(widget.post.userName),

                const Spacer(),

                // Delete button
                if(isOwnPost)
                  IconButton(
                    onPressed: showOption,
                    icon: const Icon(Icons.delete),
                  ),
              ],
            ),
          ),

          // Image
          CachedNetworkImage(
            imageUrl: widget.post.imageUrl,
            height: 420,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(height: 430),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ],
      ),
    );
  }
}
