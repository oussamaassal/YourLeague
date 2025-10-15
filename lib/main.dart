import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yourleague/User/Pages/register_page.dart';
import 'package:yourleague/User/Services/auth/auth_gate.dart';
import 'package:yourleague/User/Services/auth/auth_service.dart';
import 'package:yourleague/User/Services/auth/login_or_register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


import 'User/Pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

