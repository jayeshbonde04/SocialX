import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialx/features/profile/domain/entities/profile_user.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_cubits.dart';
import 'package:socialx/features/profile/presentation/pages/profile_page.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_states.dart';
import 'package:socialx/themes/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FollowersFollowingPage extends StatelessWidget {
  final String uid;
  final bool isFollowers;

  const FollowersFollowingPage({
    Key? key,
    required this.uid,
    required this.isFollowers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileStates>(
      builder: (context, state) {
        if (state is ProfileLoaded) {
          final user = state.profileUser;
          final List<String> userIds = isFollowers ? user.followers : user.following;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: AppColors.surface,
              title: Text(
                isFollowers ? 'Followers' : 'Following',
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              foregroundColor: AppColors.textPrimary,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: ListView.builder(
              itemCount: userIds.length,
              itemBuilder: (context, index) {
                return FutureBuilder<ProfileUser?>(
                  future: context.read<ProfileCubit>().getUserProfile(userIds[index]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data == null) {
                      return const SizedBox.shrink();
                    }

                    final ProfileUser followerUser = snapshot.data!;

                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(
                              uid: followerUser.uid,
                            ),
                          ),
                        );
                      },
                      leading: followerUser.profileImageUrl.isEmpty
                          ? Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: followerUser.profileImageUrl,
                              imageBuilder: (context, imageProvider) => Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              placeholder: (context, url) => Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                      title: Text(
                        followerUser.name,
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        followerUser.email,
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
