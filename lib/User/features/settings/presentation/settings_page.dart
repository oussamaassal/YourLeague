import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/presentation/cubits/auth_cubit.dart';
import '../../moderation/presentation/pages/blocked_users_page.dart';
import 'settings_tile.dart';

/*

SETTINGS PAGE

--------------------------------------------------------------------------------

- Apple requires that users can delete their account to be approved.

*/

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // confirm with user account deletion
  void confirmAccountDeletion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        actions: [
          // cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          // yes button
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              handleAccountDeletion();
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  // handle account deletion
  void handleAccountDeletion() async {
    try {
      // show loading..
      showDialog(
        context: context,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // delete account
      final authCubit = context.read<AuthCubit>();
      await authCubit.deleteAccount();

      // done loading -> after deletion -> navigated to auth page
      if (mounted) {
        Navigator.pop(context); // remove loading circle
        Navigator.pop(context); // remove settings page
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Column(
        children: [
          // delete account
          MySettingsTile(
            title: "Delete Account",
            action: IconButton(
              onPressed: confirmAccountDeletion,
              icon: const Icon(Icons.delete_forever),
            ),
          ),

          // blocked users
          MySettingsTile(
            title: "Blocked Users",
            action: IconButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlockedUsersPage(),
                  )),
              icon: const Icon(Icons.block),
            ),
          ),
        ],
      ),
    );
  }
}
