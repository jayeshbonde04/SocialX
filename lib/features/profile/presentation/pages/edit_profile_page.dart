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

// Reuse the same color scheme
const Color primaryColor = Color(0xFF1A1A1A);
const Color secondaryColor = Color(0xFF2D2D2D);
const Color accentColor = Color(0xFF6C63FF);
const Color backgroundColor = Color(0xFF121212);
const Color surfaceColor = Color(0xFF1E1E1E);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0xFFB3B3B3);
const Color dividerColor = Color(0xFF2D2D2D);
const Color errorColor = Color(0xFFFF4B4B);

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
            backgroundColor: surfaceColor,
            title: Text(
              'Enter Current Password',
              style: titleStyle.copyWith(fontSize: 20),
            ),
            content: MyTextfield(
              controller: passwordController,
              hintText: 'Current Password',
              obscuretext: true,
              style: bodyStyle.copyWith(color: textPrimary),
              cursorColor: textPrimary,
              decoration: InputDecoration(
                hintStyle: bodyStyle.copyWith(
                  color: textSecondary.withOpacity(0.5),
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
                  style: bodyStyle.copyWith(color: accentColor),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, passwordController.text);
                },
                child: Text(
                  'Confirm',
                  style: bodyStyle.copyWith(color: accentColor),
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
            backgroundColor: backgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: accentColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Uploading...',
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
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: accentColor,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        } else if (state is ProfileSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: accentColor,
              duration: const Duration(seconds: 3),
            ),
          );
          // Don't navigate back if we need to verify email
          if (!state.message.contains('verify')) {
            Navigator.pop(context);
          }
        } else if (state is ProfileErrors) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  Widget buildEditPage() {
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
                Icons.edit_rounded,
                color: accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Edit Profile',
              style: titleStyle,
            ),
          ],
        ),
        foregroundColor: textPrimary,
        actions: [
          //save button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: updateProfile,
              icon: const Icon(
                Icons.check_rounded,
                color: accentColor,
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
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: //display selected image for mobile
                      (!kIsWeb && imagePickedFile != null)
                          ? Image.file(
                              File(imagePickedFile!.path!),
                              fit: BoxFit.cover,
                            )
                          :
                          //display selected image for web
                          (kIsWeb && webImage != null)
                              ? Image.memory(
                                  webImage!,
                                  fit: BoxFit.cover,
                                )
                              :
                              //No image selected -> display existing profile pic
                              widget.user.profileImageUrl.isNotEmpty &&
                                      widget.user.profileImageUrl != 'null'
                                  ? CachedNetworkImage(
                                      imageUrl: widget.user.profileImageUrl,
                                      //loading...
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(
                                        color: accentColor,
                                        strokeWidth: 3,
                                      ),
                                      //error -> failed to load
                                      errorWidget: (context, url, error) =>
                                          const Icon(
                                        Icons.person_rounded,
                                        size: 72,
                                        color: textSecondary,
                                      ),
                                      //loaded
                                      imageBuilder: (context, imageProvider) =>
                                          Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: imageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_rounded,
                                      size: 72,
                                      color: textSecondary,
                                    ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            //pick image button
            Center(
              child: ElevatedButton.icon(
                onPressed: pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.camera_alt_rounded,
                  size: 20,
                ),
                label: Text(
                  'Change Photo',
                  style: buttonStyle.copyWith(
                    color: textPrimary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            //name section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name',
                    style: subtitleStyle,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: MyTextfield(
                      controller: nameTextController,
                      hintText: 'Enter your name',
                      obscuretext: false,
                      style: bodyStyle.copyWith(color: textPrimary),
                      cursorColor: textPrimary,
                      decoration: InputDecoration(
                        hintStyle: bodyStyle.copyWith(
                          color: textSecondary.withOpacity(0.5),
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
                  Text(
                    'Email',
                    style: subtitleStyle,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: MyTextfield(
                      controller: emailTextController,
                      hintText: 'Enter your email',
                      obscuretext: false,
                      style: bodyStyle.copyWith(color: textPrimary),
                      cursorColor: textPrimary,
                      decoration: InputDecoration(
                        hintStyle: bodyStyle.copyWith(
                          color: textSecondary.withOpacity(0.5),
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
                  Text(
                    'Bio',
                    style: subtitleStyle,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: MyTextfield(
                      controller: bioTextController,
                      hintText: 'Enter your bio',
                      obscuretext: false,
                      style: bodyStyle.copyWith(color: textPrimary),
                      cursorColor: textPrimary,
                      decoration: InputDecoration(
                        hintStyle: bodyStyle.copyWith(
                          color: textSecondary.withOpacity(0.5),
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
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            //logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await context.read<AuthCubit>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/',
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor,
                  foregroundColor: textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 20,
                ),
                label: Text(
                  'Logout',
                  style: buttonStyle.copyWith(
                    color: textPrimary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Delete Account Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  final passwordController = TextEditingController();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: surfaceColor,
                      title: Text(
                        'Delete Account',
                        style: titleStyle.copyWith(
                          color: errorColor,
                          fontSize: 20,
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Are you sure you want to delete your account? This action cannot be undone.',
                            style: bodyStyle,
                          ),
                          const SizedBox(height: 16),
                          MyTextfield(
                            controller: passwordController,
                            hintText: 'Enter your password to confirm',
                            obscuretext: true,
                            style: bodyStyle,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: buttonStyle.copyWith(
                              color: textSecondary,
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
                                  backgroundColor: errorColor,
                                ),
                              );
                              return;
                            }

                            // Delete account
                            await context
                                .read<AuthCubit>()
                                .deleteAccount(passwordController.text);
                            if (context.mounted) {
                              Navigator.pop(context); // Close dialog
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/',
                                (route) => false,
                              );
                            }
                          },
                          child: Text(
                            'Delete',
                            style: buttonStyle.copyWith(
                              color: errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor.withOpacity(0.1),
                  foregroundColor: errorColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: errorColor,
                      width: 1,
                    ),
                  ),
                ),
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  size: 20,
                ),
                label: Text(
                  'Delete Account',
                  style: buttonStyle.copyWith(
                    color: errorColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
