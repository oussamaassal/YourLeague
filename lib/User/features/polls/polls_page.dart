import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'poll_widget.dart';
import 'create_poll_dialog.dart';

class PollsPage extends StatelessWidget {
  const PollsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sondages'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'En cours'),
              Tab(text: 'Terminés'),
              Tab(text: 'Tous'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Ajouter un sondage',
              icon: const Icon(Icons.add),
              onPressed: () async {
                // Sélectionner d'abord un match
                final matchId = await showDialog<String>(
                  context: context,
                  builder: (context) => const _SelectMatchForPollDialog(),
                );
                if (matchId == null) return;
                // Puis créer le sondage pour ce match
                await showDialog(
                  context: context,
                  builder: (context) => CreatePollDialog(matchId: matchId),
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collectionGroup('polls')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            var docs = snapshot.data?.docs ?? [];
            // Tri côté client par createdAt desc pour ne pas nécessiter d'index Firestore
            docs.sort((a, b) {
              final ta = a.data()['createdAt'];
              final tb = b.data()['createdAt'];
              DateTime da;
              DateTime db;
              if (ta is Timestamp) {
                da = ta.toDate();
              } else {
                da = DateTime.fromMillisecondsSinceEpoch(0);
              }
              if (tb is Timestamp) {
                db = tb.toDate();
              } else {
                db = DateTime.fromMillisecondsSinceEpoch(0);
              }
              return db.compareTo(da); // desc
            });

            bool isClosed(Map<String, dynamic> data) {
              final closedFlag = data['isClosed'] == true;
              final closesAt = data['closesAt'];
              DateTime? close;
              if (closesAt is Timestamp) {
                close = closesAt.toDate();
              } else if (closesAt is DateTime) {
                close = closesAt;
              }
              final timeClosed = close != null && DateTime.now().isAfter(close);
              return closedFlag || timeClosed;
            }

            Widget buildList(List<QueryDocumentSnapshot<Map<String, dynamic>>> list) {
              if (list.isEmpty) {
                return const Center(child: Text('Aucun sondage'));
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final d = list[index];
                  // matches/{matchId}/polls/{pollId}
                  final matchId = d.reference.parent.parent!.id;
                  final pollId = d.id;
                  return PollWidget(matchId: matchId, pollId: pollId);
                },
              );
            }

            final ongoing = docs.where((d) => !isClosed(d.data())).toList();
            final finished = docs.where((d) => isClosed(d.data())).toList();
            final all = docs;

            return TabBarView(
              children: [
                buildList(ongoing),
                buildList(finished),
                buildList(all),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Dialog to pick a match for which to create a poll
class _SelectMatchForPollDialog extends StatefulWidget {
  const _SelectMatchForPollDialog();

  @override
  State<_SelectMatchForPollDialog> createState() => _SelectMatchForPollDialogState();
}

class _SelectMatchForPollDialogState extends State<_SelectMatchForPollDialog> {
  String? _selectedMatchId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir un match'),
      content: SizedBox(
        width: 420,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('matches')
              .orderBy('matchDate', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Erreur: ${snapshot.error}');
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return const Text('Aucun match disponible');

            return DropdownButtonFormField<String>(
              value: _selectedMatchId,
              decoration: const InputDecoration(labelText: 'Match'),
              items: docs.map((d) {
                final data = d.data();
                final title = '${data['team1Name'] ?? ''} vs ${data['team2Name'] ?? ''}';
                return DropdownMenuItem<String>(
                  value: d.id,
                  child: Text(title),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedMatchId = v),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _selectedMatchId == null
              ? null
              : () {
                  Navigator.pop(context, _selectedMatchId);
                },
          child: const Text('Suivant'),
        ),
      ],
    );
  }
}