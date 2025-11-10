import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yourleague/User/features/auth/presentation/cubits/auth_cubit.dart';

class FindFriendsPage extends StatefulWidget {
  const FindFriendsPage({super.key});

  @override
  State<FindFriendsPage> createState() => _FindFriendsPageState();
}

class _FindFriendsPageState extends State<FindFriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Add Friend Logic ---
  // You need to implement how a friend request is sent or stored.
  // This could involve writing to a 'friend_requests' collection in Firestore
  // or updating a 'friends' subcollection in the user's document.
  void _addFriend(String friendUid, String friendEmail) {
    print('Sending friend request to: $friendEmail (UID: $friendUid)');
    // Example: Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Friend request sent to $friendEmail')),
    );
    // TODO: Implement your actual backend logic for adding a friend here.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Friends'),
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for users by email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
              ),
            ),
          ),
          // --- User List ---
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  // Build a list of users, excluding the current logged-in user
  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      // Listen to the 'users' collection in Firestore
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get the current user's email to exclude them from the list
        final currentUserEmail = context.read<AuthCubit>().currentUser!.email;

        // Filter the list of users based on the search query
        final filteredDocs = snapshot.data!.docs.where((doc) {
          Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
          final userEmail = data['email'].toString().toLowerCase();
          final searchQueryLower = _searchQuery.toLowerCase();

          // Only show users who are NOT the current user and match the search query
          return userEmail != currentUserEmail && userEmail.contains(searchQueryLower);
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) => _buildUserListItem(filteredDocs[index]),
        );
      },
    );
  }

  // Build an individual user list item with an "Add Friend" button
  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

    return ListTile(
      title: Text(data['email']),
      trailing: ElevatedButton.icon(
        icon: const Icon(Icons.person_add, size: 18),
        label: const Text('Add'),
        style: ElevatedButton.styleFrom(
          // Making the button less intrusive
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: () {
          // Call the add friend method when the button is pressed
          _addFriend(data['uid'], data['email']);
        },
      ),
    );
  }
}
