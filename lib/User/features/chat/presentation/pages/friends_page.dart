// In D:/Flutter Projects/yourleague/lib/User/features/chat/presentation/pages/friends_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yourleague/User/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:yourleague/User/features/chat/presentation/pages/chat_page.dart';
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
        title: Text('Friends'), // Updated title
        actions: [
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
      body: _buildFriendsList(), // Renamed for clarity
    );
  }

  // Build a list of the current user's friends
  Widget _buildFriendsList() {
    // Get the current user's UID to fetch their friends list
    final currentUserUid = context.watch<AuthCubit>().currentUser?.uid;

    // If there is no logged-in user, show a message.
    if (currentUserUid == null) {
      return const Center(child: Text('Please log in to see your friends.'));
    }

    return StreamBuilder<QuerySnapshot>(
      // Listen to the 'friends' subcollection of the current user
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('friends')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading friends.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("You haven't added any friends yet. Tap the '+' icon to find friends!"),
          );
        }

        // Build the list using the documents from the 'friends' subcollection
        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildFriendListItem(doc))
              .toList(),
        );
      },
    );
  }

  // Build an individual list item for a friend
  Widget _buildFriendListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

    final String friendID = data['uid'];
    // Keep email as a fallback for the ChatPage navigation
    final String friendEmail = data['email'] ?? 'No Email';

    // Use a FutureBuilder to fetch the friend's latest data
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(friendID).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // You can return a placeholder or an empty container while loading
          return const SizedBox.shrink(); // A non-visible widget
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // If the user document was deleted, show nothing
          return const SizedBox.shrink();
        }

        // --- MODIFIED DISPLAY LOGIC ---
        Map<String, dynamic> friendData = snapshot.data!.data() as Map<String, dynamic>;

        // If the friend has no name, don't display them in the list.
        if (friendData['name'] == null) {
          return const SizedBox.shrink(); // Return an empty widget
        }

        final String displayName = friendData['name'];

        return ListTile(
          title: Text(displayName), // Display only the name
          onTap: () {
            // Navigate to the chat page with this friend
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  receiverUserName: displayName,
                  receiverUserEmail: friendEmail, // Pass email to chat page
                  receiverUserID: friendID,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
