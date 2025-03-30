import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/presentation/components/my_textfield.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:socialx/features/posts/domain/entities/comment.dart';
import 'package:socialx/features/posts/presentation/components/comment_tile.dart';
import 'package:socialx/features/posts/presentation/cubits/post_cubit.dart';
import 'package:socialx/features/posts/presentation/cubits/post_states.dart';
import 'package:socialx/features/profile/presentation/pages/profile_page.dart';
import '../../domain/entities/post.dart';
import '../../../profile/domain/entities/profile_user.dart';
import '../../../profile/presentation/cubits/profile_cubits.dart';

// Dark mode color scheme
const Color primaryColor =
    Color(0xFF1A1A1A); // Dark background for primary elements
const Color secondaryColor =
    Color(0xFF2D2D2D); // Slightly lighter dark for secondary elements
const Color accentColor =
    Color(0xFF6C63FF); // Purple accent for interactive elements
const Color backgroundColor =
    Color(0xFF121212); // Darkest shade for backgrounds
const Color surfaceColor = Color(0xFF1E1E1E); // Dark surface for cards
const Color textPrimary = Color(0xFFFFFFFF); // White text for primary content
const Color textSecondary =
    Color(0xFFB3B3B3); // Light gray text for secondary content
const Color dividerColor = Color(0xFF2D2D2D); // Dark gray for dividers
const Color errorColor = Color(0xFFFF4B4B); // Red for errors and delete actions

class PostTile extends StatefulWidget {
  final Post post;
  final void Function()? onDeletePressed;
  const PostTile(
      {super.key, required this.post, required this.onDeletePressed});

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

  void getCurrentUser() {
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.currentuser;
    isOwnPost = (widget.post.userId == currentUser!.uid);
  }

  Future<void> fetchPostUser() async {
    final fetchUser = await profileCubit.getUserProfile(widget.post.userId);
    if (fetchUser != null) {
      setState(() {
        postUser = fetchUser;
      });
    }
  }

  /*
  * Likes
  * */

  //user tapped like button
  void toggleLikePost() {
    //current like status
    final isLiked = widget.post.likes.contains(currentUser!.uid);

    // optimistically like & update Ui
    setState(() {
      if (isLiked) {
        widget.post.likes.remove(currentUser!.uid); //unlike
      } else {
        widget.post.likes.add(currentUser!.uid); //like
      }
    });

    //update like
    postCubit
        .toggleLikedPost(widget.post.id, currentUser!.uid)
        .catchError((error) {
      // if there and error, revert back to original values
      setState(() {
        if (isLiked) {
          widget.post.likes.add(currentUser!.uid); // revert unlike
        } else {
          widget.post.likes.remove(currentUser!.uid); // revert like
        }
      });
    });
  }

  /*
  * Comments
  * */

  //comment text controller
  final commentTextController = TextEditingController();

  //open comment box -> user wants to type a new comment
  void openCommentBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Add a Comment",
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: MyTextfield(
            controller: commentTextController,
            hintText: "Write a comment...",
            obscuretext: false,
            maxLines: 3,
            style: const TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintStyle: TextStyle(
                color: textSecondary.withOpacity(0.5),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "Cancel",
              style: TextStyle(color: textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              addComment();
              Navigator.of(context).pop();
            },
            child: const Text(
              "Post",
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //add comment
  void addComment() {
    //create a new comment
    final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        postId: widget.post.id,
        userId: currentUser!.uid,
        userName: currentUser!.name,
        text: commentTextController.text);

    //addd comment using cubit
    if (commentTextController.text.isNotEmpty) {
      postCubit.addComment(widget.post.id, newComment);
    }
  }

  @override
  void dispose() {
    commentTextController.dispose();
    super.dispose();
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
      color: surfaceColor,
      child: Column(
        children: [
          // Name
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(uid: widget.post.userId),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  //profile pic
                  postUser?.profileImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: postUser!.profileImageUrl,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person, color: textSecondary),
                          imageBuilder: (context, imageProvider) => Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      : const Icon(Icons.person, color: textSecondary),

                  const SizedBox(width: 10),

                  //name
                  Text(
                    widget.post.userName,
                    style: const TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  // Delete button
                  if (isOwnPost)
                    GestureDetector(
                      onTap: showOption,
                      child: const Icon(Icons.delete, color: errorColor),
                    ),
                ],
              ),
            ),
          ),

          // Image or Text
          if (widget.post.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.post.imageUrl,
              height: 420,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 420,
                color: backgroundColor,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: accentColor,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 420,
                color: backgroundColor,
                child: const Icon(
                  Icons.error_outline,
                  color: errorColor,
                  size: 48,
                ),
              ),
            ),

          // Post text if no image
          if (widget.post.imageUrl.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: backgroundColor,
              child: Text(
                widget.post.text,
                style: const TextStyle(
                  fontSize: 16,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // buttons -> like, comment, timestamp
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Row(
                    children: [
                      //like button
                      GestureDetector(
                        onTap: toggleLikePost,
                        child: Icon(
                          widget.post.likes.contains(currentUser!.uid)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.post.likes.contains(currentUser!.uid)
                              ? errorColor
                              : textSecondary,
                        ),
                      ),
                      const SizedBox(width: 5),

                      //like count
                      Text(
                        widget.post.likes.length.toString(),
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                //comment button
                GestureDetector(
                  onTap: openCommentBox,
                  child: const Icon(
                    Icons.comment,
                    color: textSecondary,
                  ),
                ),

                const SizedBox(width: 5),

                Text(
                  widget.post.comment.length.toString(),
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),

          //caption
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            child: Row(
              children: [
                //username
                Text(
                  widget.post.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(width: 8),

                //text
                Expanded(
                  child: Text(
                    widget.post.text,
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          //COMMENT SECTION

          BlocBuilder<PostCubit, PostState>(builder: (context, state) {
            //loaded
            if (state is PostsLoaded) {
              final post =
                  state.posts.firstWhere((post) => (post.id == widget.post.id));

              if (post.comment.isNotEmpty) {
                // how many comments to show
                int showCommentCount = post.comment.length;

                //comment section
                return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: showCommentCount,
                    itemBuilder: (context, index) {
                      //get individual comment
                      final comment = post.comment[index];

                      //comment tile UI
                      return CommentTile(comment: comment);
                    });
              }
            }

            //loading
            if (state is PostsLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            //error
            else if (state is PostsError) {
              return Center(
                child: Text(state.message),
              );
            } else {
              return const SizedBox();
            }
          })
        ],
      ),
    );
  }
}
