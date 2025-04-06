import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:socialx/features/chats/presentation/pages/chat_page.dart';
import 'package:socialx/features/posts/domain/entities/post.dart';
import 'package:socialx/features/posts/presentation/components/post_tile.dart';
import 'package:socialx/features/posts/presentation/cubits/post_cubit.dart';
import 'package:socialx/features/posts/presentation/cubits/post_states.dart';
import 'package:socialx/features/profile/domain/entities/profile_user.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_cubits.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_states.dart';
import 'package:socialx/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:socialx/features/profile/presentation/pages/followers_following_page.dart';
import 'package:socialx/themes/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socialx/features/home/presentation/pages/home_page.dart';
import 'package:socialx/features/search/presentation/pages/search_page.dart';
import 'package:socialx/features/posts/presentation/pages/upload_post_page.dart';
import 'package:socialx/features/posts/presentation/pages/twitter.dart';

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

final TextStyle buttonStyle = GoogleFonts.poppins(
  color: AppColors.buttonPrimary,
  fontSize: 12,
  fontWeight: FontWeight.w600,
);

class ProfilePage extends StatefulWidget {
  final String uid;
  const ProfilePage({super.key, required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  //cubits
  late final authCubit = context.read<AuthCubit>();
  late final profileCubit = context.read<ProfileCubit>();

  //current user
  AppUsers? currentUser;

  //posts
  int postCount = 0;

  //toggle state
  bool showPhotos = true;

  // Selected index for bottom navigation
  int _selectedIndex = 4;  // Profile tab is selected by default

  //on startup
  @override
  void initState() {
    super.initState();

    //get current user
    getCurrentUser();

    //load user profile state
    profileCubit.fetchUserProfile(widget.uid);
    
    //load posts
    context.read<PostCubit>().fetchAllPosts();
  }

  //get current user
  void getCurrentUser() {
    currentUser = authCubit.currentuser;
  }

  //toggle between photos and tweets
  void toggleContent() {
    setState(() {
      showPhotos = !showPhotos;
    });
  }

  void _onItemTapped(int index) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1: // Search
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchPage()),
        ).then((_) {
          setState(() {
            _selectedIndex = 4; // Reset to profile
          });
        });
        break;
      case 2: // Add Post
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UploadPostPage()),
        ).then((_) {
          setState(() {
            _selectedIndex = 4; // Reset to profile
          });
        });
        break;
      case 3: // Twitter
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TwitterPage()),
        ).then((_) {
          setState(() {
            _selectedIndex = 4; // Reset to profile
          });
        });
        break;
      case 4: // Profile
        // Already on profile page
        break;
    }
  }

  void _showPostDialog(BuildContext context, Post post) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: AppColors.background,
          child: Column(
            children: [
              // App bar with close button
              AppBar(
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  post.userName,
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              // Main image
              Expanded(
                flex: 2,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: post.imageUrl.isNotEmpty
                      ? Image.network(
                          post.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.surface,
                              child: const Center(
                                child: Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 48,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.surface,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: AppColors.textSecondary,
                              size: 48,
                            ),
                          ),
                        ),
                ),
              ),
              // Post details and likes
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post text
                    if (post.text.isNotEmpty)
                      Text(
                        post.text,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Likes section
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${post.likes.length} likes',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Who liked the post
                    if (post.likes.isNotEmpty)
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.2,
                        ),
                        child: SingleChildScrollView(
                          child: FutureBuilder<List<ProfileUser>>(
                            future: Future.wait(
                              post.likes.map((userId) => profileCubit.getUserProfile(userId)),
                            ).then((users) => users.whereType<ProfileUser>().toList()),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                );
                              }
                              
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              
                              final likers = snapshot.data!;
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: likers.map((user) => GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfilePage(uid: user.uid ?? ''),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.primary.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundImage: user.profileImageUrl?.isNotEmpty == true
                                              ? NetworkImage(user.profileImageUrl!)
                                              : null,
                                          child: user.profileImageUrl?.isEmpty == true
                                              ? const Icon(Icons.person, size: 16, color: AppColors.textSecondary)
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          user.name ?? 'Unknown User',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )).toList(),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Comments section
                    Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${post.comment.length} comments',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Comments list
                    if (post.comment.isNotEmpty)
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.3,
                        ),
                        child: SingleChildScrollView(
                          child: FutureBuilder<List<ProfileUser>>(
                            future: Future.wait(
                              post.comment.map((comment) => profileCubit.getUserProfile(comment.userId)),
                            ).then((users) => users.whereType<ProfileUser>().toList()),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                );
                              }
                              
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              
                              final commenters = snapshot.data!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(post.comment.length, (index) {
                                  final comment = post.comment[index];
                                  final commenter = commenters.firstWhere(
                                    (user) => user.uid == comment.userId,
                                    orElse: () => ProfileUser(
                                      uid: '',
                                      name: 'Unknown User',
                                      email: '',
                                      profileImageUrl: '',
                                      bio: '',
                                      followers: [],
                                      following: [],
                                    ),
                                  );
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfilePage(uid: commenter.uid ?? ''),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundImage: commenter.profileImageUrl?.isNotEmpty == true
                                                ? NetworkImage(commenter.profileImageUrl!)
                                                : null,
                                            child: commenter.profileImageUrl?.isEmpty == true
                                                ? const Icon(Icons.person, size: 20, color: AppColors.textSecondary)
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  commenter.name ?? 'Unknown User',
                                                  style: const TextStyle(
                                                    color: AppColors.textPrimary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  comment.text,
                                                  style: const TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Other posts by the same owner
              Expanded(
                child: Container(
                  color: AppColors.background,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'More posts by ${post.userName}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: BlocBuilder<PostCubit, PostState>(
                          builder: (context, state) {
                            if (state is PostsLoading) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              );
                            }
                            
                            if (state is PostsLoaded) {
                              final otherPosts = state.posts
                                  .where((p) => 
                                      p.userId == post.userId && 
                                      p.id != post.id &&
                                      p.type != PostType.tweet)
                                  .toList();
                              
                              if (otherPosts.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No other posts',
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                );
                              }
                              
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                itemCount: otherPosts.length,
                                itemBuilder: (context, index) {
                                  final otherPost = otherPosts[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showPostDialog(context, otherPost);
                                    },
                                    child: Container(
                                      height: 80,
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: AppColors.surface,
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Post image
                                          ClipRRect(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              bottomLeft: Radius.circular(8),
                                            ),
                                            child: otherPost.imageUrl.isNotEmpty
                                                ? Image.network(
                                                    otherPost.imageUrl,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        width: 80,
                                                        height: 80,
                                                        color: AppColors.surface,
                                                        child: const Icon(
                                                          Icons.error_outline,
                                                          color: AppColors.error,
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: AppColors.surface,
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                          ),
                                          // Post details
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    otherPost.text.isNotEmpty 
                                                        ? otherPost.text 
                                                        : 'No caption',
                                                    style: const TextStyle(
                                                      color: AppColors.textPrimary,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.favorite,
                                                        color: AppColors.textSecondary,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${otherPost.likes?.length ?? 0}',
                                                        style: const TextStyle(
                                                          color: AppColors.textSecondary,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Icon(
                                                        Icons.comment,
                                                        color: AppColors.textSecondary,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${otherPost.comment.length}',
                                                        style: const TextStyle(
                                                          color: AppColors.textSecondary,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                            
                            return const Center(
                              child: Text(
                                'Failed to load posts',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileStates>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          );
        }

        if (state is ProfileErrors) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: GoogleFonts.poppins(
                      color: AppColors.error,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ProfileLoaded) {
          final user = state.profileUser;
          final isCurrentUser = currentUser?.uid == widget.uid;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: AppColors.surface,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (isCurrentUser)
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(user: user),
                      ),
                      );
                    },
                    ),
                if (!isCurrentUser)
                  IconButton(
                    icon: const Icon(
                      Icons.message_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            receiverUserEmail: user.email,
                            receiverUserID: user.uid,
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(width: 8),
              ],
            ),
            body: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await profileCubit.fetchUserProfile(widget.uid);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Hero(
                            tag: 'profile_${user.uid}',
                            child: Container(
                              width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                  width: 4,
                                ),
                          ),
                              child: ClipOval(
                                child: user.profileImageUrl.isEmpty
                                    ? Container(
                                        color: AppColors.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.person_rounded,
                                          size: 60,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: user.profileImageUrl,
                              fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: AppColors.primary.withOpacity(0.1),
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: AppColors.primary.withOpacity(0.1),
                                          child: const Icon(
                                            Icons.error_outline_rounded,
                                            size: 40,
                                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.name,
                            style: titleStyle,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '@${user.email.split('@')[0]}',
                                style: subtitleStyle,
                              ),
                              if (user.isPrivate) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.textSecondary,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              BlocBuilder<PostCubit, PostState>(
                                builder: (context, state) {
                                  if (state is PostsLoaded) {
                                    final userPosts = state.posts.where((post) => 
                                      post.userId == user.uid && 
                                      post.type != PostType.tweet
                                    ).toList();
                                    return _buildStatColumn(
                                      'Posts',
                                      _buildStatValue(userPosts.length.toString()),
                                    );
                                  }
                                  return _buildStatColumn(
                                    'Posts',
                                    _buildStatValue('0'),
                                  );
                                },
                              ),
                              Container(
                                height: 30,
                                width: 1,
                                color: AppColors.divider,
                              ),
                              BlocBuilder<PostCubit, PostState>(
                                builder: (context, state) {
                                  if (state is PostsLoaded) {
                                    final userTweets = state.posts.where((post) => 
                                      post.userId == user.uid && 
                                      post.type == PostType.tweet
                                    ).toList();
                                    return _buildStatColumn(
                                      'Tweets',
                                      _buildStatValue(userTweets.length.toString()),
                                    );
                                  }
                                  return _buildStatColumn(
                                    'Tweets',
                                    _buildStatValue('0'),
                                  );
                                },
                              ),
                              Container(
                                height: 30,
                                width: 1,
                                color: AppColors.divider,
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowersFollowingPage(
                                      uid: user.uid,
                                      isFollowers: true,
                                    ),
                                  ),
                                ),
                                child: _buildStatColumn(
                                  'Followers',
                                  _buildStatValue(user.followers.length.toString()),
                                ),
                              ),
                              Container(
                                height: 30,
                                width: 1,
                                color: AppColors.divider,
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowersFollowingPage(
                                      uid: user.uid,
                                      isFollowers: false,
                                    ),
                                  ),
                                ),
                                child: _buildStatColumn(
                                  'Following',
                                  _buildStatValue(user.following.length.toString()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (user.bio.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                user.bio,
                                style: GoogleFonts.poppins(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 24),
                          // Show follow button or follow request status for non-owners
                          if (user.uid != FirebaseAuth.instance.currentUser?.uid)
                            BlocBuilder<ProfileCubit, ProfileStates>(
                              builder: (context, state) {
                                final isFollowing = user.followers.contains(currentUser?.uid);
                                final hasPendingRequest = state is FollowRequestPending;
                                
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: ElevatedButton(
                                    onPressed: isFollowing || hasPendingRequest
                                        ? null
                                        : () {
                                            if (user.isPrivate) {
                                              context.read<ProfileCubit>().toggleFollow(
                                                user.uid,
                                                currentUser!.uid,
                                              );
                                            } else {
                                              context.read<ProfileCubit>().toggleFollow(
                                                user.uid,
                                                currentUser!.uid,
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFollowing
                                          ? AppColors.surface
                                          : AppColors.primary,
                                      foregroundColor: isFollowing
                                          ? AppColors.textSecondary
                                          : Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      isFollowing
                                          ? 'Following'
                                          : hasPendingRequest
                                              ? 'Request Sent'
                                              : user.isPrivate
                                                  ? 'Follow Request'
                                                  : 'Follow',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 24),
                          // Show follow requests for account owner
                          if (user.uid == FirebaseAuth.instance.currentUser?.uid)
                            FutureBuilder<List<String>>(
                              future: context.read<ProfileCubit>().getFollowRequests(user.uid),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                
                                final followRequests = snapshot.data ?? [];
                                if (followRequests.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Follow Requests',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ...followRequests.map((requestUserId) {
                                        return FutureBuilder<ProfileUser?>(
                                          future: context.read<ProfileCubit>().getUserProfile(requestUserId),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const Center(
                                                child: CircularProgressIndicator(),
                                              );
                                            }
                                            
                                            final requestUser = snapshot.data;
                                            if (requestUser == null) {
                                              return const SizedBox.shrink();
                                            }
                                            
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 20,
                                                    backgroundImage: requestUser.profileImageUrl.isNotEmpty
                                                        ? NetworkImage(requestUser.profileImageUrl)
                                                        : null,
                                                    child: requestUser.profileImageUrl.isEmpty
                                                        ? const Icon(Icons.person)
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          requestUser.name,
                                                          style: GoogleFonts.poppins(
                                                            color: AppColors.textPrimary,
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        Text(
                                                          '@${requestUser.name.toLowerCase()}',
                                                          style: GoogleFonts.poppins(
                                                            color: AppColors.textSecondary,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        onPressed: () {
                                                          context.read<ProfileCubit>().handleFollowRequest(
                                                            user.uid,
                                                            requestUser.uid,
                                                            false,
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.close,
                                                          color: AppColors.error,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: () {
                                                          context.read<ProfileCubit>().handleFollowRequest(
                                                            user.uid,
                                                            requestUser.uid,
                                                            true,
                                                          );
                                                        },
                                                        icon: const Icon(
                                                          Icons.check,
                                                          color: AppColors.success,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.1),
                                width: 1,
                              ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => showPhotos = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: showPhotos
                                            ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_library_rounded,
                                      color: showPhotos
                                                ? Colors.white
                                          : AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Photos',
                                            style: GoogleFonts.poppins(
                                        color: showPhotos
                                                  ? Colors.white
                                            : AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => showPhotos = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !showPhotos
                                            ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: !showPhotos
                                                ? Colors.white
                                          : AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tweets',
                                            style: GoogleFonts.poppins(
                                        color: !showPhotos
                                                  ? Colors.white
                                            : AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                        ],
                      ),
                    ),
                    if (showPhotos)
                      BlocBuilder<PostCubit, PostState>(
                        builder: (context, state) {
                          if (state is PostsLoaded) {
                            final userPosts = state.posts
                                .where((post) =>
                                    post.userId == widget.uid &&
                                    post.imageUrl.isNotEmpty)
                                .toList();

                            if (userPosts.isEmpty) {
                              return _buildEmptyState(
                                icon: Icons.photo_library_outlined,
                                title: 'No photos yet',
                                subtitle: 'Photos you share will appear here',
                              );
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: userPosts.length,
                              itemBuilder: (context, index) {
                                final post = userPosts[index];
                                return GestureDetector(
                                  onTap: () {
                                    _showPostDialog(context, post);
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: post.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: AppColors.primary.withOpacity(0.1),
                                            child: const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: AppColors.primary.withOpacity(0.1),
                                            child: const Icon(
                                              Icons.error_outline_rounded,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.6),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.favorite,
                                                      color: post.likes.contains(currentUser?.uid) ? AppColors.error : Colors.white,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      post.likes.length.toString(),
                                                      style: GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.6),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.chat_bubble_outline,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      post.comment.length.toString(),
                                                      style: GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      )
                    else
                      BlocBuilder<PostCubit, PostState>(
                        builder: (context, state) {
                          if (state is PostsLoaded) {
                            final userPosts = state.posts
                                .where((post) =>
                                    post.userId == widget.uid &&
                                    post.type == PostType.tweet)
                                .toList();

                            if (userPosts.isEmpty) {
                              return _buildEmptyState(
                                icon: Icons.chat_bubble_outline_rounded,
                                title: 'No tweets yet',
                                subtitle: 'Tweets you post will appear here',
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: userPosts.length,
                              itemBuilder: (context, index) {
                                final post = userPosts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: PostTile(
                                  post: post,
                                  onDeletePressed: () {
                                      context.read<PostCubit>().deletePost(post.id);
                                  },
                                  ),
                                );
                              },
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppColors.surface,
                selectedItemColor: AppColors.accent,
                unselectedItemColor: AppColors.textSecondary,
                selectedLabelStyle: GoogleFonts.poppins(
                  color: AppColors.buttonPrimary,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  color: AppColors.buttonDisabled,
                  fontWeight: FontWeight.w500,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search_rounded),
                    label: 'Search',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.add_box_rounded),
                    label: 'Post',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.cloud),
                    label: 'Twitter',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildStatColumn(String label, Widget value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        value,
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatValue(String value) {
    return Text(
      value,
      style: GoogleFonts.poppins(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
