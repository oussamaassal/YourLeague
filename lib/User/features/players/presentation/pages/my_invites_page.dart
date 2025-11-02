// lib/User/features/players/presentation/pages/my_invites_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyInvitesPage extends StatelessWidget {
  const MyInvitesPage({super.key});

  CollectionReference<Map<String, dynamic>> get _teams =>
      FirebaseFirestore.instance.collection('teams');

  CollectionReference<Map<String, dynamic>> _userInvites(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('team_invites');

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Team invites')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _userInvites(uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          if (docs.isEmpty) {
            return const Center(child: Text('No invites'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i];
              final m = d.data();
              final teamId = (m['teamId'] ?? '') as String;
              final roleOffered = (m['roleOffered'] ?? 'player') as String;

              // Use a FutureBuilder, but DO NOT chain nullable calls.
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: _teams.doc(teamId).get(),
                builder: (context, teamSnap) {
                  // Compute teamName safely with local variables (no chained ?.data()).
                  String teamName = teamId; // fallback
                  if (teamSnap.hasData) {
                    final docSnap = teamSnap.data; // DocumentSnapshot<Map<String,dynamic>>?
                    if (docSnap != null) {
                      final dataMap = docSnap.data(); // Map<String,dynamic>?
                      final n = dataMap != null ? dataMap['name'] : null;
                      if (n is String && n.trim().isNotEmpty) {
                        teamName = n;
                      }
                    }
                  }

                  return ListTile(
                    leading: const Icon(Icons.group_add),
                    title: Text(teamName),
                    subtitle: Text('Role: $roleOffered'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Decline',
                          icon: const Icon(Icons.close),
                          onPressed: () async {
                            await _declineInvite(uid: uid, teamId: teamId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invite declined')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Accept',
                          icon: const Icon(Icons.check),
                          onPressed: () async {
                            await _acceptInvite(
                              uid: uid,
                              teamId: teamId,
                              roleOffered: roleOffered,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Joined team')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Accept: add to /teams/{teamId}/members, remove mirrors in both places.
  Future<void> _acceptInvite({
    required String uid,
    required String teamId,
    required String roleOffered, // "player" | "organizer" | "owner"
  }) async {
    final db = FirebaseFirestore.instance;
    final teamRef = _teams.doc(teamId);
    final teamInvRef = teamRef.collection('invites').doc(uid);
    final userInvRef = _userInvites(uid).doc(teamId);

    await db.runTransaction((tx) async {
      final teamSnap = await tx.get(teamRef);
      if (!teamSnap.exists) return;

      final membersRef = teamRef.collection('members').doc(); // auto-id
      tx.set(membersRef, {
        'userId': uid,
        'role': roleOffered,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.delete(teamInvRef);
      tx.delete(userInvRef);
    });
  }

  /// Decline: just delete both invite mirrors.
  Future<void> _declineInvite({
    required String uid,
    required String teamId,
  }) async {
    final db = FirebaseFirestore.instance;
    final teamInvRef = _teams.doc(teamId).collection('invites').doc(uid);
    final userInvRef = _userInvites(uid).doc(teamId);

    await db.runTransaction((tx) async {
      tx.delete(teamInvRef);
      tx.delete(userInvRef);
    });
  }
}
