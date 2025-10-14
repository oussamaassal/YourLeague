import 'package:flutter/material.dart';
import 'package:yourleague/User/Pages/register_page.dart';
import 'package:yourleague/User/Services/auth/login_or_register.dart';

import 'User/Pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginOrRegister(),
    );
  }
}

