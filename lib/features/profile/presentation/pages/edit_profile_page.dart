import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialx/features/auth/presentation/components/my_textfield.dart';
import 'package:socialx/features/profile/domain/entities/profile_user.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_cubits.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_states.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
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
  color: Colors.cyan,
  fontSize: 12,
  fontWeight: FontWeight.w600,
);

class EditProfilePage extends StatefulWidget {
  final ProfileUser user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  //mobile image pick
  PlatformFile? imagePickedFile;

  //web picked images
  Uint8List? webImage;

  //bio text controller
  final bioTextController = TextEditingController();
  //name text controller
  final nameTextController = TextEditingController();
  //email text controller
  final emailTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
    nameTextController.text = widget.user.name;
    emailTextController.text = widget.user.email;
    bioTextController.text = widget.user.bio;
  }

  @override
  void dispose() {
    bioTextController.dispose();
    nameTextController.dispose();
    emailTextController.dispose();
    super.dispose();
  }

  //pick images
  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );

    if (result != null) {
      setState(() {
        imagePickedFile = result.files.first;

        if (kIsWeb) {
          webImage = imagePickedFile?.bytes;
        }
      });
    }
  }

  //update profile button pressed
  void updateProfile() async {
    //profile cubit
    final profileCubit = context.read<ProfileCubit>();

    //prepare images & data
    final String uid = widget.user.uid;
    final imageMobilePath = kIsWeb ? null : imagePickedFile?.path;
    final imagesWebBytes = kIsWeb ? imagePickedFile?.bytes : null;
    final String? newBio =
        bioTextController.text.isNotEmpty ? bioTextController.text : null;
    final String newName = nameTextController.text;
    final String newEmail = emailTextController.text;

    //only update profile if there is something to update
    if (imagePickedFile != null ||
        newBio != null ||
        newName != widget.user.name ||
        newEmail != widget.user.email) {
      // If email is being updated, prompt for current password
      String? currentPassword;
      if (newEmail != widget.user.email) {
        final passwordController = TextEditingController();
        currentPassword = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              'Enter Current Password',
              style: titleStyle.copyWith(fontSize: 20),
            ),
            content: MyTextfield(
              controller: passwordController,
              hintText: 'Current Password',
              obscuretext: true,
              style: bodyStyle.copyWith(color: AppColors.textPrimary),
              cursorColor: AppColors.textPrimary,
              decoration: InputDecoration(
                hintStyle: bodyStyle.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: bodyStyle.copyWith(color: AppColors.primary),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, passwordController.text);
                },
                child: Text(
                  'Confirm',
                  style: bodyStyle.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        );
      }

      profileCubit.updateProfile(
        uid: widget.user.uid,
        newBio: bioTextController.text,
        imageMobilePath: imageMobilePath,
        imageWebBytes: imagesWebBytes,
        newName: newName,
        newEmail: newEmail,
        currentPassword: currentPassword,
      );
    }
    //nothing to update -> go to previous page
    else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileStates>(
      builder: (context, state) {
        //profile loading...
        if (state is ProfileLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Updating profile...',
                    style: subtitleStyle,
                  ),
                ],
              ),
            ),
          );
        }

        //edit form
        return buildEditPage();
      },
      listener: (context, state) {
        if (state is ProfileLoaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile updated successfully!',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context);
        } else if (state is ProfileSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          // Don't navigate back if we need to verify email
          if (!state.message.contains('verify')) {
            Navigator.pop(context);
          }
        } else if (state is ProfileErrors) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
    );
  }

  Widget buildEditPage() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.cyan,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Edit Profile',
              style: titleStyle.copyWith(
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          //save button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: updateProfile,
              icon: const Icon(
                Icons.check_rounded,
                color: Colors.cyan,
                size: 20,
              ),
              label: Text(
                'Save',
                style: GoogleFonts.poppins(
                  color: Colors.cyan,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.cyan.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            //profile pic
            Center(
              child: Stack(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.cyan.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: imagePickedFile != null
                          ? kIsWeb
                              ? Image.memory(
                                  webImage!,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(imagePickedFile!.path!),
                                  fit: BoxFit.cover,
                                )
                          : widget.user.profileImageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.user.profileImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.cyan,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.cyan,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            
            // Change photo text
            Center(
              child: TextButton(
                onPressed: pickImage,
                child: Text(
                  'Change Profile Photo',
                  style: GoogleFonts.poppins(
                    color: Colors.cyan,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            
            // Divider
            Container(
              height: 1,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            
            const SizedBox(height: 24),

            //name section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        color: Colors.cyan.withOpacity(0.7),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                  Text(
                    'Name',
                        style: subtitleStyle.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.cyan.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: MyTextfield(
                      controller: nameTextController,
                      hintText: 'Enter your name',
                      obscuretext: false,
                      style: bodyStyle.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      cursorColor: Colors.cyan,
                      decoration: InputDecoration(
                        hintStyle: bodyStyle.copyWith(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            //email section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        color: Colors.cyan.withOpacity(0.7),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                  Text(
                    'Email',
                        style: subtitleStyle.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.cyan.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: MyTextfield(
                      controller: emailTextController,
                      hintText: 'Enter your email',
                      obscuretext: false,
                      style: bodyStyle.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      cursorColor: Colors.cyan,
                      decoration: InputDecoration(
                        hintStyle: bodyStyle.copyWith(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            //bio section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.cyan.withOpacity(0.7),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                  Text(
                    'Bio',
                        style: subtitleStyle.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.cyan.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: MyTextfield(
                      controller: bioTextController,
                      hintText: 'Tell us about yourself',
                      obscuretext: false,
                      maxLines: 4,
                      style: bodyStyle.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      cursorColor: Colors.cyan,
                      decoration: InputDecoration(
                        hintStyle: bodyStyle.copyWith(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Divider
            Container(
              height: 1,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            
            const SizedBox(height: 24),

            // Add privacy toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Private Account',
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Only approved followers can see your posts',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: widget.user.isPrivate,
                    onChanged: (bool value) async {
                      await context.read<ProfileCubit>().updateProfile(
                        uid: widget.user.uid,
                        newIsPrivate: value,
                      );
                      // Refresh the profile after updating privacy setting
                      if (context.mounted) {
                        await context.read<ProfileCubit>().fetchUserProfile(widget.user.uid);
                      }
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextButton.icon(
                onPressed: () {
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
                            style: titleStyle.copyWith(
                              color: AppColors.error,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        'Are you sure you want to logout?',
                        style: bodyStyle,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: bodyStyle.copyWith(color: AppColors.primary),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              await context.read<AuthCubit>().logout();
                              if (context.mounted) {
                                // Close the dialog first
                                Navigator.pop(context);
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
                                      style: bodyStyle.copyWith(
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
                            style: bodyStyle.copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                label: Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            //delete account button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextButton.icon(
                onPressed: () async {
                  final passwordController = TextEditingController();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: AppColors.error,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                        'Delete Account',
                        style: titleStyle.copyWith(
                              color: AppColors.error,
                          fontSize: 20,
                        ),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This action cannot be undone. All your data will be permanently deleted.',
                            style: bodyStyle,
                          ),
                          const SizedBox(height: 16),
                          MyTextfield(
                            controller: passwordController,
                            hintText: 'Enter your password to confirm',
                            obscuretext: true,
                            style: bodyStyle.copyWith(color: AppColors.textPrimary),
                            cursorColor: AppColors.textPrimary,
                            decoration: InputDecoration(
                              hintStyle: bodyStyle.copyWith(
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.error.withOpacity(0.7),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancel',
                            style: bodyStyle.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (passwordController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please enter your password',
                                    style: bodyStyle,
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            // Delete account
                            await context
                                .read<AuthCubit>()
                                .deleteAccount(passwordController.text);
                            if (context.mounted) {
                              Navigator.pop(context, true); // Close dialog
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/',
                                (route) => false,
                              );
                            }
                          },
                          child: Text(
                            'Delete',
                            style: bodyStyle.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                label: Text(
                  'Delete Account',
                  style: GoogleFonts.poppins(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
