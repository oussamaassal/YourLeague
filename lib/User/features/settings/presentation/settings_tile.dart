import 'package:flutter/material.dart';

/*

SETTINGS LIST TILE

This is a simple tile for each item in the settings page.

--------------------------------------------------------------------------------

To use this widget, you need:

- title (e.g. "Delete Account")
- action (e.g. deleteAccount())

*/

class MySettingsTile extends StatelessWidget {
  final String title;
  final Widget action;

  const MySettingsTile({
    super.key,
    required this.title,
    required this.action,
  });

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    // Container
    return Container(
      decoration: BoxDecoration(
        // color
        color: Theme.of(context).colorScheme.tertiary,

        // curver corners
        borderRadius: BorderRadius.circular(12),
      ),

      // Padding inside
      padding: const EdgeInsets.all(25),

      // Padding outside
      margin: const EdgeInsets.only(left: 25, right: 25, top: 10),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          action,
        ],
      ),
    );
  }
}
