import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:yourleague/User/features/matches/data/firebase_matches_repo.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_cubit.dart';
import 'package:yourleague/User/themes/dark_mode.dart';
import 'package:yourleague/User/themes/light_mode.dart';
import 'firebase_options.dart';

import 'package:yourleague/TeamsAndPlayers/notifications/notification_service.dart';
import 'package:yourleague/TeamsAndPlayers/notifications/fcm_setup.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final n = message.notification;
  if (n != null) await NotificationService.show(n);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseInitialized = true;

    await NotificationService.init();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    print("ℹ️ Firebase not connected yet - showing welcome page");
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
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(authRepo: FirebaseAuthRepo())..checkAuth(),
        ),
        BlocProvider<ModerationCubit>(
          create: (context) =>
              ModerationCubit(moderationRepo: FirebaseModerationRepo()),
        ),
        BlocProvider<ChatCubit>(
          create: (context) => ChatCubit(chatRepo: FirebaseChatRepo()),
        ),
        BlocProvider<ShopCubit>(
          create: (context) => ShopCubit(shopRepo: FirebaseShopRepo()),
        ),
        BlocProvider<CartCubit>(
          create: (context) => CartCubit(),
        ),
        BlocProvider<MatchesCubit>(
          create: (context) =>
              MatchesCubit(matchesRepo: FirebaseMatchesRepo()),
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
        if (state is Authenticated) {
          setupFCM(state.user.uid);
          return const HomePage();
        }
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
