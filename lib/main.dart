import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:yourleague/User/Components/welcome_page.dart';
import 'package:yourleague/User/features/auth/data/firebase_auth_repo.dart';
import 'package:yourleague/User/features/auth/presentation/components/loading.dart';
import 'package:yourleague/User/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:yourleague/User/features/auth/presentation/cubits/auth_states.dart';
import 'package:yourleague/User/features/auth/presentation/pages/auth_page.dart';
import 'package:yourleague/User/features/chat/data/firebase_chat_repo.dart';
import 'package:yourleague/User/features/chat/presentation/cubits/chat_cubits.dart';
import 'package:yourleague/User/features/home/presentation/pages/home_page.dart';
import 'package:yourleague/User/features/moderation/data/firebase_moderation_repo.dart';
import 'package:yourleague/User/features/moderation/presentation/cubits/moderation_cubit.dart';
import 'package:yourleague/User/features/shop/data/firebase_shop_repo.dart';
import 'package:yourleague/User/features/shop/presentation/cubits/shop_cubit.dart';
import 'package:yourleague/User/features/shop/presentation/cubits/cart_cubit.dart';

import 'package:yourleague/User/features/shop/data/stripe_payment_service.dart';
import 'package:yourleague/User/themes/dark_mode.dart';
import 'package:yourleague/User/themes/light_mode.dart';
import 'package:yourleague/User/themes/theme_cubit.dart';
import 'package:yourleague/User/features/matches/data/firebase_matches_repo.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_cubit.dart';
import 'package:yourleague/User/features/settings/presentation/cubits/theme_cubit.dart';
import 'package:yourleague/User/themes/dark_mode.dart';
import 'package:yourleague/User/themes/light_mode.dart';
import 'package:yourleague/User/services/notification_service.dart';
import 'firebase_options.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe
  await StripePaymentService.initialize();

  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseInitialized = true;
  } catch (e) {
    print("ℹ️  Firebase not connected yet - showing welcome page");
    firebaseInitialized = false;
  }

  // Initialize local notifications (timezone, channels)
  await NotificationService.instance.init();

  runApp(MyApp(firebaseEnabled: firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool firebaseEnabled;

  const MyApp({super.key, this.firebaseEnabled = false});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // Set up all state management (BLoC pattern)
      providers: [
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(),
        ),

        BlocProvider<AuthCubit>(
          create: (context) =>
          AuthCubit(authRepo: FirebaseAuthRepo())..checkAuth(),
        ),

        BlocProvider<ModerationCubit>(
          create: (context) =>
              ModerationCubit(moderationRepo: FirebaseModerationRepo()),
        ),

        BlocProvider<ChatCubit>(
            create: (context) => ChatCubit(chatRepo: FirebaseChatRepo())
        ),


        // Handles shop operations (products, orders, transactions)

        BlocProvider<ShopCubit>(
          create: (context) => ShopCubit(shopRepo: FirebaseShopRepo()),
        ),

  
  
        // Handles shopping cart
 
        BlocProvider<CartCubit>(
          create: (context) => CartCubit(),
        ),

  
  
        // Handles matches and tournaments
        BlocProvider<MatchesCubit>(
          create: (context) => MatchesCubit(matchesRepo: FirebaseMatchesRepo()),
        ),

        // Handles theme mode switching
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(),
        ),

 
      ],

      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
  
            title: 'Your League',
  
          title: 'Your League',
 
            theme: lightMode,
            darkTheme: darkMode,
            themeMode: themeMode,
            home: firebaseEnabled ? _buildAppBody() : const WelcomePage(),
          );
        },
      ),

    );
  }



  Widget _buildAppBody() {
    return BlocConsumer<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is Unauthenticated) return const AuthPage();
        if (state is Authenticated) return const HomePage();
        return const LoadingScreen();
      },
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }

      },
    );
  }
}
