import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socialx/features/auth/data/firebase_auth_repo.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:socialx/features/auth/presentation/cubits/auth_state.dart';
import 'package:socialx/features/auth/presentation/pages/auth_page.dart';
import 'package:socialx/features/home/presentation/pages/home_page.dart';
import 'package:socialx/features/posts/data/firebase_post_repo.dart';
import 'package:socialx/features/posts/presentation/cubits/post_cubit.dart';
import 'package:socialx/features/profile/data/firebase_profile_repo.dart';
import 'package:socialx/features/profile/presentation/cubits/profile_cubits.dart';
import 'package:socialx/storage/data/firebase_storage_repo.dart';
import 'package:socialx/themes/light_mode.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize repositories
    final firebaseAuthRepo = FirebaseAuthRepo();
    final firebaseProfileRepo = FirebaseProfileRepo();
    final firebaseStorageRepo = FirebaseStorageRepo();
    final firebasePostRepo = FirebasePostRepo();

    return MultiBlocProvider(
      providers: [
        // Provide authentication cubit
        BlocProvider<AuthCubit>(
            create: (context) =>
                AuthCubit(authRepo: firebaseAuthRepo)..checkAuth()),

        // Provide profile cubit
        BlocProvider<ProfileCubit>(
            create: (context) => ProfileCubit(
                profileRepo: firebaseProfileRepo,
                storageRepo: firebaseStorageRepo)),

        // Provide post cubit
        BlocProvider<PostCubit>(
            create: (context) => PostCubit(
                postRepo: firebasePostRepo, storageRepo: firebaseStorageRepo)),
      ],
      child: MaterialApp(
        theme: lightMode,
        home: BlocConsumer<AuthCubit, AuthState>(
          builder: (context, authState) {
            // Check authentication state
            if (authState is Unauthenticated) {
              return const AuthPage();
            } else if (authState is Authenticated) {
              return const HomePage();
            } else {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
          },
          listener: (context, authState) {
            if (authState is AuthErrors) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(authState.message)));
              });
            }
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
