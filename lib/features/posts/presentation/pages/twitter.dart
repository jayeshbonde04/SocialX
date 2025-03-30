import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socialx/features/posts/domain/entities/post.dart';
import 'package:socialx/features/posts/presentation/cubits/post_cubit.dart';
import 'package:socialx/features/posts/presentation/cubits/post_states.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_cubits.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_states.dart';
import 'package:socialx/features/profile/presentation/pages/profile_page.dart';
import 'package:socialx/features/posts/presentation/components/my_input_alertBox.dart';
import 'package:socialx/features/posts/presentation/components/post_tile.dart';

class TwitterPage extends StatefulWidget {
  const TwitterPage({super.key});

  @override
  State<TwitterPage> createState() => _TwitterPageState();
}

class _TwitterPageState extends State<TwitterPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PostCubit>().fetchAllPosts();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void deletePost(String postId) {
    context.read<PostCubit>().deletePost(postId);
    context.read<PostCubit>().fetchAllPosts();
  }

  void _postTweet() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final userProfile = await context.read<ProfileCubit>().getUserProfile(currentUser.uid);
    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile not found')),
      );
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => MyInputAlertBox(
        textController: _messageController,
        hintText: 'What\'s happening?',
        maxLength: 280,
        onPressed: () {
          final text = _messageController.text;
          Navigator.pop(context, text);
        },
        onPressedText: 'Tweet',
      ),
    );

    if (result != null && result.isNotEmpty) {
      final post = Post(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser.uid,
        userName: userProfile.name,
        text: result,
        imageUrl: '', // Explicitly set empty string for no image
        timestamp: DateTime.now(),
        likes: [],
        comment: [],
        type: PostType.tweet,
      );

      if (mounted) {
        context.read<PostCubit>().createPost(post);
        _messageController.clear(); // Clear the input after posting
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('${userProfile.name} tweeted: ${result.substring(0, result.length > 30 ? 30 : result.length)}${result.length > 30 ? '...' : ''}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Twitter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _postTweet,
          ),
        ],
      ),
      body: BlocBuilder<PostCubit, PostState>(
        builder: (context, state) {
          if (state is PostsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PostsError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is PostsLoaded) {
            // Filter only tweets and sort by timestamp (newest first)
            final tweets = state.posts
                .where((post) => post.type == PostType.tweet)
                .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            
            if (tweets.isEmpty) {
              return const Center(
                child: Text('No tweets yet. Be the first to tweet!'),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<PostCubit>().fetchAllPosts();
              },
              child: ListView.builder(
                itemCount: tweets.length,
                itemBuilder: (context, index) {
                  final tweet = tweets[index];
                  return PostTile(
                    post: tweet,
                    onDeletePressed: () => deletePost(tweet.id),
                  );
                },
              ),
            );
          }

          return const Center(child: Text('No posts available'));
        },
      ),
    );
  }
}

