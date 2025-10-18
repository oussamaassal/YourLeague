import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/presentation/cubits/auth_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // auth cubit
    final authCubit = context.read<AuthCubit>();
    // current user
    final currentUser = authCubit.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: Center(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Icon(
                Icons.person,
                size: 80,
              ),
            ),
            Text(currentUser!.email),
          ],
        ),
      ),
    );
  }
}
