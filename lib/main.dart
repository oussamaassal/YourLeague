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
        // Handles user authentication (login/register/logout)
        BlocProvider<AuthCubit>(
          create: (context) =>
          AuthCubit(authRepo: FirebaseAuthRepo())..checkAuth(),
        ),

        // Handles blocking users & reporting content
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

      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Your League',
        theme: lightMode,
        darkTheme: darkMode,
        home: firebaseEnabled ? _buildAppBody() : const WelcomePage(),
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
