import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialx/features/chats/presentation/pages/display_user.dart';
import 'package:socialx/features/posts/domain/entities/post.dart';
import 'package:socialx/features/posts/presentation/cubits/post_states.dart';
import 'package:socialx/features/posts/presentation/pages/upload_post_page.dart';
import 'package:socialx/features/posts/presentation/pages/twitter.dart';
import 'package:socialx/features/profile/presentation/pages/profile_page.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_cubits.dart';
import '../../../posts/presentation/components/post_tile.dart';
import '../../../posts/presentation/cubits/post_cubit.dart';
import 'package:socialx/features/search/presentation/pages/search_page.dart';
import 'package:socialx/features/notifications/presentation/pages/notifications_page.dart';
import 'package:socialx/features/notifications/presentation/cubits/notification_cubit.dart';
import 'package:socialx/features/notifications/presentation/cubits/notification_states.dart';
import 'package:socialx/features/auth/domain/entities/app_users.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:socialx/features/chats/presentation/pages/chat_page.dart';
import 'package:socialx/themes/app_colors.dart';

/*
 HOME PAGE
 This is the main page of this app: it displays a list of posts.
 */

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

// Text styles
final TextStyle titleStyle = GoogleFonts.poppins(
  color: textPrimary,
  fontWeight: FontWeight.bold,
  fontSize: 24,
  letterSpacing: 0.5,
);

final TextStyle subtitleStyle = GoogleFonts.poppins(
  color: textSecondary,
  fontSize: 16,
  fontWeight: FontWeight.w500,
);

final TextStyle bodyStyle = GoogleFonts.poppins(
  color: textSecondary,
  fontSize: 14,
);

final TextStyle buttonStyle = GoogleFonts.poppins(
  color: accentColor,
  fontSize: 12,
  fontWeight: FontWeight.w600,
);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //post cubit
  late final postCubit = context.read<PostCubit>();
  late final profileCubit = context.read<ProfileCubit>();
  int _selectedIndex = 0;
  List<String> following = [];

  //on startup
  @override
  void initState() {
    super.initState();

    // Initialize notifications first
    initializeNotifications();
    // Then fetch posts and following
    fetchAllPosts();
    fetchFollowing();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh following list when returning to home page
    fetchFollowing();
    // Refresh notifications when returning to home page
    refreshNotifications();
  }

  void fetchAllPosts() {
    postCubit.fetchAllPosts();
  }

  void refreshNotifications() {
    context.read<NotificationCubit>().refreshNotifications();
  }

  Future<void> fetchFollowing() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userProfile = await profileCubit.getUserProfile(currentUser.uid);
      if (userProfile != null) {
        setState(() {
          following = userProfile.following;
        });
      }
    }
  }

  void deletePost(String postId) {
    postCubit.deletePost(postId);
    fetchAllPosts();
  }

  void _onItemTapped(int index) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    switch (index) {
      case 0: // Home
        setState(() {
          _selectedIndex = index;
        });
        // Refresh data when returning to home
        fetchAllPosts();
        fetchFollowing();
        break;
      case 1: // Search
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchPage()),
        ).then((_) {
          setState(() {
            _selectedIndex = 0; // Reset to home
          });
        });
        break;
      case 2: // Add Post
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UploadPostPage()),
        ).then((_) {
          setState(() {
            _selectedIndex = 0; // Reset to home
          });
        });
        break;
      case 3: // Twitter
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TwitterPage()),
        ).then((_) {
          setState(() {
            _selectedIndex = 0; // Reset to home
          });
        });
        break;
      case 4: // Profile
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProfilePage(uid: currentUser.uid)),
        ).then((_) {
          setState(() {
            _selectedIndex = 0; // Reset to home
          });
        });
        break;
    }
  }

  void initializeNotifications() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('Initializing notifications for user: ${currentUser.uid}');
      context.read<NotificationCubit>().initializeNotifications(currentUser.uid);
    } else {
      print('No current user found for notification initialization');
    }
  }

  // Build UI
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
              child: const Icon(
                Icons.home_rounded,
                color: accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'SocialX',
              style: titleStyle,
            ),
          ],
        ),
        foregroundColor: AppColors.textPrimary,
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (context, state) {
              print('HomePage: Notification state: ${state.toString()}');
              
              if (state is NotificationLoaded) {
                final unreadCount = state.notifications
                    .where((notification) => !notification.isRead)
                    .length;
                print('HomePage: Unread notifications count: $unreadCount');
                
                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        print('HomePage: Notification icon pressed');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsPage(),
                          ),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: GoogleFonts.poppins(
                              color: AppColors.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
              print('HomePage: Using default notification icon');
              return IconButton(
                icon: Icon(
                  Icons.notifications_rounded,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  print('HomePage: Default notification icon pressed');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.message_rounded, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DisplayUser()),
              );
            },
            tooltip: 'Messages',
          ),
        ],
      ),
      body: BlocBuilder<PostCubit, PostState>(
        builder: (context, state) {
          //loading...
          if (state is PostsLoading && state is PostsUploading) {
            return const Center(
              child: CircularProgressIndicator(
                color: accentColor,
                strokeWidth: 3,
              ),
            );
          }
          //loaded
          else if (state is PostsLoaded) {
            final allPosts = state.posts;
            // Filter posts to only show regular posts from users you follow
            final filteredPosts = allPosts.where((post) => 
              following.contains(post.userId) && post.type == PostType.regular
            ).toList();

            if (filteredPosts.isEmpty) {
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
                      'No posts to show',
                      style: subtitleStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Follow some users to see their posts here!',
                      style: bodyStyle,
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              color: accentColor,
              backgroundColor: surfaceColor,
              onRefresh: () async {
                await Future.wait([
                  Future(() => fetchAllPosts()),
                  Future(() => fetchFollowing()),
                ]);
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  //get individual posts
                  final post = filteredPosts[index];

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: surfaceColor,
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
                      onDeletePressed: () => deletePost(post.id),
                    ),
                  );
                },
              ),
            );
          }
          //error
          else if (state is PostsError) {
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
                      Icons.error_outline,
                      size: 64,
                      color: errorColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: errorColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
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
          backgroundColor: surfaceColor,
          selectedItemColor: accentColor,
          unselectedItemColor: textSecondary,
          selectedLabelStyle: buttonStyle,
          unselectedLabelStyle: bodyStyle,
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
}
