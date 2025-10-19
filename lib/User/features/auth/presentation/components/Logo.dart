import 'package:flutter/material.dart';


class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.tertiary)),
      child: Image.asset(
        'lib/User/assets/logo.png',
        height: 100,
        color: Theme.of(context).colorScheme.inversePrimary,
      ),
    );
  }
}
