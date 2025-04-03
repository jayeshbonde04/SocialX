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
import 'package:socialx/features/notifications/data/firebase_notification_repo.dart';
import 'package:socialx/features/notifications/presentation/cubits/notification_cubit.dart';
import 'package:socialx/features/notifications/presentation/pages/notifications_page.dart';
import 'package:socialx/features/posts/presentation/pages/upload_post_page.dart';
import 'package:socialx/features/profile/presentation/pages/profile_page.dart';
import 'package:socialx/services/notifications/in_app_notification_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize repositories
    final firebaseAuthRepo = FirebaseAuthRepo();
    final firebaseProfileRepo = FirebaseProfileRepo();
    final firebaseStorageRepo = FirebaseStorageRepo();
    final firebasePostRepo = FirebasePostRepo();
    final firebaseNotificationRepo = FirebaseNotificationRepo();
    
    // Initialize in-app notification service
    final inAppNotificationService = InAppNotificationService();

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
                storageRepo: firebaseStorageRepo,
                authCubit: context.read<AuthCubit>())),

        // Provide notification cubit
        BlocProvider<NotificationCubit>(
            create: (context) => NotificationCubit(firebaseNotificationRepo)),

        // Provide post cubit
        BlocProvider<PostCubit>(
            create: (context) => PostCubit(
                postRepo: firebasePostRepo,
                storageRepo: firebaseStorageRepo,
                notificationCubit: context.read<NotificationCubit>())),
      ],
      child: MaterialApp(
        navigatorKey: inAppNotificationService.navigatorKey,
        theme: lightMode,
        initialRoute: '/',
        routes: {
          '/': (context) => BlocConsumer<AuthCubit, AuthState>(
                builder: (context, authState) {
                  // Check authentication state
                  if (authState is Unauthenticated) {
                    return const AuthPage();
                  } else if (authState is Authenticated) {
                    // Initialize in-app notification service with context
                    inAppNotificationService.initialize(context);
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
          '/notifications': (context) => const NotificationsPage(),
          '/upload': (context) => const UploadPostPage(),
          '/twitter': (context) => const HomePage(),
        },
        onGenerateRoute: (settings) {
          // Handle dynamic routes like /profile/:uid
          if (settings.name?.startsWith('/profile/') == true) {
            final uid = settings.name?.substring(8); // Remove '/profile/'
            if (uid != null) {
              return MaterialPageRoute(
                builder: (context) => ProfilePage(uid: uid),
              );
            }
          }
          return null;
        },
        onUnknownRoute: (settings) {
          // Redirect unknown routes to home
          return MaterialPageRoute(
            builder: (context) => const HomePage(),
          );
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
