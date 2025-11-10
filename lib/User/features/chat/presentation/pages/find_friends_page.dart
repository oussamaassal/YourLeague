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
  // --- Add Friend Logic ---
  void _addFriend(String friendUid, String friendEmail) async {
    // Get the current user's UID from AuthCubit
    final currentUserUid = context.read<AuthCubit>().currentUser!.uid;

    // Don't allow users to add themselves
    if (currentUserUid == friendUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot add yourself as a friend.")),
      );
      return;
    }

    try {
      // Add the friend to the current user's 'friends' subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('friends')
          .doc(friendUid) // Use the friend's UID as the document ID
          .set({
        'email': friendEmail,
        'uid': friendUid,
        'addedOn': Timestamp.now(), // Optional: store when the friend was added
      });

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$friendEmail has been added to your friends!')),
      );
    } catch (e) {
      // Handle potential errors, e.g., network issues or permissions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add friend: $e')),
      );
    }
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
                labelText: 'Search for users by name',
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
    final currentUser = context.read<AuthCubit>().currentUser;
    if (currentUser == null) {
      return const Center(child: Text("You must be logged in to find friends."));
    }
    final currentUserUid = currentUser.uid;

    // 1. First, get the list of current friends' UIDs
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('friends')
          .snapshots(),
      builder: (context, friendsSnapshot) {
        if (friendsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (friendsSnapshot.hasError) {
          return const Center(child: Text('Could not load friends list.'));
        }

        final friendUids = friendsSnapshot.data?.docs.map((doc) => doc.id).toSet() ?? {};

        // 2. Then, build the list of all users, applying filters
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, usersSnapshot) {
            if (usersSnapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            }
            if (usersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // --- MODIFIED FILTERING LOGIC ---
            final filteredDocs = usersSnapshot.data!.docs.where((doc) {
              Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
              final userUid = doc.id;

              // Filter out users without a name
              if (data['name'] == null) {
                return false;
              }

              // Exclude the current user and existing friends
              if (userUid == currentUserUid || friendUids.contains(userUid)) {
                return false;
              }

              // Apply the text search filter on the name
              final userName = data['name'].toString().toLowerCase();
              final searchQueryLower = _searchQuery.trim().toLowerCase();

              // If the search query is empty, include the user (show all non-friend users)
              if (searchQueryLower.isEmpty) return true;

              return userName.contains(searchQueryLower);
            }).toList();

            if (filteredDocs.isEmpty) {
              return Center(child: Text(_searchQuery.isEmpty ? 'No users found.' : 'No users match your search.'));
            }

            return ListView.builder(
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) =>
                  _buildUserListItem(filteredDocs[index]),
            );
          },
        );
      },
    );
  }

// --- SIMPLIFIED to only show name ---
  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

    // Prefer the document ID as the UID (that's how we filtered earlier), fallback to any stored 'uid' field
    final String friendUid = document.id.isNotEmpty ? document.id : (data['uid']?.toString() ?? '');
    final String displayName = data['name']?.toString() ?? 'No name'; // We already filtered out null names
    final String friendEmail = data['email']?.toString() ?? '';

    return ListTile(
      title: Text(displayName), // Display only the name
      trailing: ElevatedButton.icon(
        icon: const Icon(Icons.person_add, size: 18),
        label: const Text('Add'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: () {
          _addFriend(friendUid, friendEmail);
        },
      ),
    );
  }

}
