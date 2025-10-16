import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'User/components/welcome_page.dart';
import 'User/features/auth/data/firebase_auth_repo.dart';
import 'User/features/auth/presentation/components/loading.dart';
import 'User/features/auth/presentation/cubits/auth_cubit.dart';
import 'User/features/auth/presentation/cubits/auth_states.dart';
import 'User/features/auth/presentation/pages/auth_page.dart';
/*import 'User/features/home/data/firebase_post_repo.dart';
import 'User/features/home/presentation/cubits/post_cubit.dart';
import 'User/features/home/presentation/pages/home_page.dart';
import 'User/features/moderation/data/firebase_moderation_repo.dart';
import 'User/features/moderation/presentation/cubits/moderation_cubit.dart';
import 'User/features/subscriptions/data/revenuecat_constants.dart';
import 'User/features/subscriptions/data/revenuecat_service.dart';
import 'User/features/subscriptions/presentation/cubits/offerings_cubit.dart';
import 'User/features/subscriptions/presentation/cubits/subscription_cubit.dart';*/
import 'User/themes/dark_mode.dart';
import 'User/themes/light_mode.dart';

// =====================================================
// MAIN ENTRY POINT - START HERE!
// =====================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =====================================================
  // STEP 1: FIREBASE SETUP (REQUIRED FOR FULL APP)
  // =====================================================
  // The app will show a welcome page until you connect Firebase.
  // To get started:
  // 1. Create a Firebase project at console.firebase.google.com
  // 2. Add your Flutter app and download config files
  // 3. UNCOMMENT the two lines below ⬇️

  bool firebaseInitialized = false;
  try {
    // 🔥 UNCOMMENT THESE TWO LINES AFTER FIREBASE SETUP:
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // firebaseInitialized = true;
  } catch (e) {
    print("ℹ️  Firebase not connected yet - showing welcome page");
    firebaseInitialized = false;
  }

  // =====================================================
  // STEP 2: REVENUECAT SETUP (OPTIONAL - FOR SUBSCRIPTIONS $$)
  // =====================================================
  // RevenueCat handles paid subscriptions. Skip this if you don't need subscriptions.
  // To enable: Replace "YOUR_REVENUECAT_API_KEY_HERE" in revenuecat_constants.dart

  // configure revenue cat
  //await RevenuecatService.configureRevenueCat(appleApiKey);

  // =====================================================
  // START THE APP
  // =====================================================
  runApp(MyApp(firebaseEnabled: firebaseInitialized));
}

// =====================================================
// APP WIDGET - HANDLES ROUTING & STATE MANAGEMENT
// =====================================================

class MyApp extends StatelessWidget {
  final bool firebaseEnabled;

  const MyApp({super.key, this.firebaseEnabled = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YourLeague',
      theme: lightMode,
      darkTheme: darkMode,

      // ROUTING LOGIC:
      // If Firebase is connected → Full app with authentication
      // If Firebase is NOT connected → Welcome page with setup instructions
      home: firebaseEnabled ? _buildFullApp() : const WelcomePage(),
    );
  }

  // =====================================================
  // FULL APP - ONLY LOADS WHEN FIREBASE IS CONNECTED
  // =====================================================
  Widget _buildFullApp() {
    return MultiBlocProvider(
      // Set up all state management (BLoC pattern)
      providers: [
        // Handles user authentication (login/register/logout)
        BlocProvider<AuthCubit>(
          create: (context) =>
              AuthCubit(authRepo: FirebaseAuthRepo())..checkAuth(),
        ),

        // Handles blocking users & reporting content
       /* BlocProvider<ModerationCubit>(
          create: (context) =>
              ModerationCubit(moderationRepo: FirebaseModerationRepo()),
        ),

        // Handles posts & comments
        BlocProvider<PostCubit>(
          create: (context) => PostCubit(
            postRepo: FirebasePostRepo(),
            moderationCubit: context.read<ModerationCubit>(),
          ),
        ),

        // Handles checking if user has pro subscription
        BlocProvider<SubscriptionCubit>(
          create: (context) => SubscriptionCubit(),
        ),

        // Handles subscription purchase flow
        BlocProvider<OfferingsCubit>(
          create: (context) => OfferingsCubit(),
        ),*/
      ],

      // Main app navigation based on authentication state
      child: BlocConsumer<AuthCubit, AuthState>(
        builder: (context, state) {
          // User not logged in → Show login/register pages
          if (state is Unauthenticated) return const AuthPage();

          // User logged in → Show main app (home page)
          if (state is Authenticated) return const HomePage();

          // Loading → Show loading spinner
          return const LoadingScreen();
        },

        // Listen for state changes to show errors or check subscription
        listener: (context, state) {
          // Show error messages to user
          if (state is AuthError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }

          // When user logs in, check if they have pro subscription
         /* if (state is Authenticated) {
            context.read<SubscriptionCubit>().checkProStatus();
          }*/
        },
      ),
    );
  }
}
