import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yourleague/User/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:yourleague/User/features/chat/presentation/pages/chat_page.dart';
// Import the new page you created
import 'package:yourleague/User/features/chat/presentation/pages/find_friends_page.dart';


class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends List'),
        actions: [
          // --- Add button to navigate to the FindFriendsPage ---
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Find Friends',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FindFriendsPage()),
              );
            },
          ),
        ],
      ),
      // The body now shows the user's current friends.
      body: _buildUserList(),
    );
  }

  // build a list of users except for the current logged in user
  Widget _buildUserList() {
    // TODO: This should be updated to fetch from the current user's 'friends' subcollection
    // instead of the general 'users' collection.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot){
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading users.'));
        }

        if(snapshot.connectionState == ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator());
        }

        // This list currently shows all users, not just friends.
        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildUserListItem(doc))
          // Filter out any empty containers that were returned for invalid users
              .where((widget) => widget is ListTile).toList(),
        );
      },
    );
  }

  // build individual user list items
  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    // --- FIX: Safely get email and uid ---
    final String? userEmail = data['email'];
    final String? userID = data['uid'];

    // --- FIX: Check if email or uid is null before proceeding ---
    if (userEmail == null || userID == null) {
      // If data is invalid, return an empty container so it doesn't show in the list.
      return Container();
    }

    final authCubit = context.read<AuthCubit>();
    final currentUserEmail = authCubit.currentUser?.email;

    // Display all users except current user
    if (currentUserEmail != null && currentUserEmail != userEmail) {
      return ListTile(
        title: Text(userEmail),
        onTap: () {
          // Pass the clicked user's UID to the chat page
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  // We already confirmed these are not null
                  receiverUserEmail: userEmail,
                  receiverUserID: userID,
                ),
              ));
        },
      );
    } else {
      // Return empty container for the current user or if something is wrong
      return Container();
    }
  }
}
