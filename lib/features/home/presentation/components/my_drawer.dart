import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:socialx/features/home/presentation/components/my_drawer_tile.dart';
import 'package:socialx/features/posts/presentation/pages/twitter.dart';
import 'package:socialx/features/profile/presentation/pages/profile_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialx/themes/app_colors.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            children: [
              //logo
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50.0),
                child: Icon(
                  Icons.person,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                  ),
              ),

              //divider line
              Divider(
                color: Theme.of(context).colorScheme.secondary,
              ),
          
                //home tile
                MyDrawerTile(
                  title: 'H O M E', 
                  icon: Icons.home, 
                  onTap: ()=>Navigator.of(context).pop(),),

                  //profile tile
                MyDrawerTile(
                  title: 'P R O F I L E', 
                  icon: Icons.person_2, 
                  onTap: (){
                    //pop menu drawer
                    Navigator.of(context).pop();

                    // get current user id
                    final user = context.read<AuthCubit>().currentuser;
                    String? uid = user!.uid;

                    //navigating to profile page
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context)=> ProfilePage(uid: uid,))
                    );
                  }),
          
                //twitter tile
                MyDrawerTile(
                  title: 'TWITTER',
                  icon: Icons.cloud,
                  onTap: (){
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context)=> const TwitterPage())
                    );
                  }),

                //   //settings tile
                // MyDrawerTile(
                //   title: 'S E T T I N G S', 
                //   icon: Icons.settings, 
                //   onTap: (){
                //     Navigator.of(context).pop();
                //     // Navigator.of(context).push(
                //     //   MaterialPageRoute(
                //     //     builder: (context)=> ProfilePage())
                //     // );
                //   }),

                const Spacer(),
          
                //logout tile
                MyDrawerTile(
                  title: 'L O G O U T', 
                  icon: Icons.logout, 
                  onTap: () async {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: AppColors.error,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: GoogleFonts.poppins(
                                color: AppColors.error,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          'Are you sure you want to logout?',
                          style: GoogleFonts.poppins(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              // Close the dialog first
                              Navigator.pop(context);
                              try {
                                await context.read<AuthCubit>().logout();
                                if (context.mounted) {
                                  // Navigate to auth page and remove all routes
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/',
                                    (route) => false,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to logout: ${e.toString()}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              'Logout',
                              style: GoogleFonts.poppins(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}