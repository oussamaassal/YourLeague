import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yourleague/User/Services/auth/auth_service.dart';
/*import '../features/profile/profile_page.dart';
import '../features/settings/presentation/settings_page.dart';*/
import 'drawer_tile.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  // sign user out
  void signOut(BuildContext context) {
    // get auth service
    final authService = Provider.of<AuthService>(context, listen: false);

    authService.signOut();
  }

  // confirm logout
  void confirmLogout(BuildContext context) {
    // pop drawer first
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout?"),
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
              signOut(context);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    // DRAWER
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // header icon
            Container(
              padding: const EdgeInsets.symmetric(vertical: 25),
              child: const Icon(Icons.phone),
            ),

            Divider(
              color: Theme.of(context).colorScheme.tertiary,
              indent: 25,
              endIndent: 25,
            ),

            const SizedBox(height: 25),

            // home tile
            MyDrawerTile(
              text: "Home",
              icon: Icons.home,
              onTap: () => Navigator.pop(context),
            ),

            // profile tile
            /*MyDrawerTile(
              text: "Profile",
              icon: Icons.person,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfilePage(),
                  ),
                );
              },
            ),

            // settings tile
            MyDrawerTile(
              text: "Settings",
              icon: Icons.settings,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
            ),*/

            const Spacer(),

            // logout tile
            MyDrawerTile(
              text: "Logout",
              icon: Icons.logout,
              onTap: () => confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}
