import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yourleague/User/Components/drawer.dart';
import 'package:yourleague/User/Pages/chat_page.dart';
import 'package:yourleague/User/Services/auth/auth_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  // instance of auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // sign user out
  void signOut() {
    // get auth service
    final authService = Provider.of<AuthService>(context, listen: false);

    authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends List'),
      ),
      body: _buildUserList(),
      // DRAWER
      drawer: const MyDrawer(),
    );
  }

  // build a list of users except for the current loged in user
  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot){
        if (snapshot.hasError) {
          return const Text('error');
        }

        if(snapshot.connectionState == ConnectionState.waiting){
          return const Text('Loading..');
        }

        return ListView(
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildUserListItem(doc)).toList(),
        );
      },
    );
  }

  // build indivisual user list items
  // build individual user list items
  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

    // display all users except current user
    if (_auth.currentUser!.email != data['email']) {
      return ListTile(
        // The fix is here: Wrap the string in a Text widget
        title: Text(data['email']),
        onTap: () {
          // pass the clicked user's UID to the chat page
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  receiverUserEmail: data['email'],
                  receiverUserID: data['uid'],
                ),
              ));
        },
      );
    } else {
      // return empty container for the current user
      return Container();
    }
  }

}
