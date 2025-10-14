import 'package:flutter/material.dart';
import 'package:yourleague/User/Components/my_text_field.dart';

import '../Components/my_buton.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  // text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // sign up user
  void signUp() {

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[300],
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  // logo
                  Icon(Icons.message,
                    size: 100,),

                  const SizedBox(height: 50),

                  //welcome back message
                  Text(
                    "Let's create an account for you!",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 50),

                  //email texfield
                  MyTextField(
                      controller: emailController,
                      hintText: 'Email',
                      obscureText: false
                  ),
                  const SizedBox(height: 10),

                  //password textfield
                  MyTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: true
                  ),
                  const SizedBox(height: 10),

                  //confirm password
                  MyTextField(
                      controller: confirmPasswordController,
                      hintText: 'Confirm password',
                      obscureText: true
                  ),

                  const SizedBox(height: 30),

                  //sign in button
                  MyButton(onTap: signUp, text: 'Sign up',),

                  const SizedBox(height: 30),

                  //not a member? register now
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already a member?'),
                      const SizedBox(width: 4,),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: const Text(
                            'Login now',
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
