import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yourleague/User/Components/Logo.dart';
import 'package:yourleague/User/Components/my_text_field.dart';
import 'package:yourleague/User/Services/auth/auth_service.dart';

import '../Components/my_buton.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  // text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // sign in user
  void SignIn() async {
    // get the auth service
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.signInWithEmailandPassword(
          emailController.text,
          passwordController.text,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              e.toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                // logo
                Logo(),

                const SizedBox(height: 50),

                //welcome back message
                Text(
                    "Welcome back you\'ve been missed!",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                ),
                const SizedBox(height: 50),

                //email texfield
                MyTextfield(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false
                ),
                const SizedBox(height: 10),

                //password textfield
                MyTextfield(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true
                ),

                const SizedBox(height: 30),

                //sign in button
                MyButton(onTap: SignIn, text: 'Sign in',),

                const SizedBox(height: 30),

                //not a member? register now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Not a member?'),
                    const SizedBox(width: 4,),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Register now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        )
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      )
    );
  }
}
