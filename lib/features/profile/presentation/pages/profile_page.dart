import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:socialx/features/chats/presentation/pages/chat_page.dart';
import 'package:socialx/features/posts/presentation/components/post_tile.dart';
import 'package:socialx/features/posts/presentation/cubits/post_cubit.dart';
import 'package:socialx/features/posts/presentation/cubits/post_states.dart';
import 'package:socialx/features/profile/presentation/components/bio_box.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_cubits.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_states.dart';
import 'package:socialx/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:socialx/features/profile/presentation/pages/followers_following_page.dart';
import 'package:socialx/themes/app_colors.dart';

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
  color: AppColors.accent,
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

  //on startup
  @override
  void initState() {
    super.initState();

    //get current user
    getCurrentUser();

    //load user profile state
    profileCubit.fetchUserProfile(widget.uid);
  }

  //get current user
  void getCurrentUser() {
    currentUser = authCubit.currentuser;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileStates>(
      builder: (context, state) {
        if (state is ProfileLoaded) {
          final user = state.profileUser;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: AppColors.surface,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentWithOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    user.name,
                    style: titleStyle,
                  ),
                ],
              ),
              foregroundColor: AppColors.textPrimary,
              actions: [
                if (currentUser?.uid == user.uid)
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(user: user),
                      ),
                    ),
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Profile Picture
                  Center(
                    child: CachedNetworkImage(
                      imageUrl: user.profileImageUrl,
                      placeholder: (context, url) => const CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 3,
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 120,
                        width: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 72,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      imageBuilder: (context, imageProvider) => Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(
                          'Posts',
                          BlocBuilder<PostCubit, PostState>(
                            builder: (context, state) {
                              if (state is PostsLoaded) {
                                final userPost = state.posts
                                    .where((post) => post.userId == widget.uid)
                                    .toList();
                                return _buildStatValue(userPost.length.toString());
                              }
                              return _buildStatValue('0');
                            },
                          ),
                        ),
                        _buildStatColumn(
                          'Followers',
                          _buildStatValue(user.followers.length.toString()),
                        ),
                        _buildStatColumn(
                          'Following',
                          _buildStatValue(user.following.length.toString()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Bio Section
                  BioBox(text: user.bio),
                  if (currentUser?.uid != user.uid) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              profileCubit.toggleFollow(user.uid, currentUser!.uid);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: user.followers.contains(currentUser!.uid)
                                  ? AppColors.secondary
                                  : AppColors.accent,
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              user.followers.contains(currentUser!.uid)
                                  ? 'Unfollow'
                                  : 'Follow',
                              style: buttonStyle.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Message',
                              style: buttonStyle.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Posts Grid
                  BlocBuilder<PostCubit, PostState>(
                    builder: (context, state) {
                      if (state is PostsLoaded) {
                        final userPosts = state.posts
                            .where((post) => post.userId == widget.uid)
                            .toList();
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: userPosts.length,
                          itemBuilder: (context, index) {
                            final post = userPosts[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: PostTile(
                                post: post,
                                onDeletePressed: () {},
                              ),
                            );
                          },
                        );
                      }
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 3,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }
        //loading...
        else if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          return const Center(child: Text("No profile found"));
        }
      },
    );
  }

  Widget _buildStatColumn(String label, Widget value) {
    return Column(
      children: [
        value,
        Text(
          label,
          style: bodyStyle,
        ),
      ],
    );
  }

  Widget _buildStatValue(String value) {
    return Text(
      value,
      style: subtitleStyle,
    );
  }
}
