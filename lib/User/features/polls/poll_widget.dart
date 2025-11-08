import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'poll_service.dart';

class PollWidget extends StatefulWidget {
  final String matchId;
  final String pollId;
  const PollWidget({super.key, required this.matchId, required this.pollId});

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  List<String> _selected = [];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('polls')
          .doc(widget.pollId)
          .snapshots(),
      builder: (context, pollSnap) {
        if (!pollSnap.hasData) return const SizedBox.shrink();
        final poll = pollSnap.data!;
        final data = poll.data() ?? {};
        final title = data['title'] ?? '';
        final allowMultiple = data['allowMultiple'] ?? false;
        final options = (data['options'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    if (data['createdBy'] == FirebaseAuth.instance.currentUser?.uid)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Supprimer le sondage'),
                              content: const Text('Êtes-vous sûr de vouloir supprimer ce sondage ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await PollService.deletePoll(
                                matchId: widget.matchId,
                                pollId: widget.pollId,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erreur: ${e.toString()}')),
                                );
                              }
                            }
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Options + vote controls
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: PollService.streamVotes(matchId: widget.matchId, pollId: widget.pollId),
                  builder: (context, votesSnap) {
                    final votes = votesSnap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                    // count votes per option id
                    final counts = <String, int>{};
                    for (final opt in options) {
                      counts[opt['id'] as String] = 0;
                    }
                    for (final v in votes) {
                      final vo = v.data()['optionIds'] as List<dynamic>?;
                      if (vo == null) continue;
                      for (final id in vo) {
                        counts[id as String] = (counts[id as String] ?? 0) + 1;
                      }
                    }

                    final total = counts.values.fold<int>(0, (s, e) => s + e);

                    // find current user vote (safe loop, avoid returning null from orElse)
                    QueryDocumentSnapshot<Map<String, dynamic>>? userVoteDoc;
                    for (final d in votes) {
                      try {
                        final data = d.data();
                        if (data['userId'] == uid) {
                          userVoteDoc = d;
                          break;
                        }
                      } catch (_) {
                        // ignore malformed vote docs
                      }
                    }
                    final alreadyVoted = userVoteDoc != null;
                    final userSelected = alreadyVoted
                        ? List<String>.from(userVoteDoc!.data()['optionIds'] as List<dynamic>)
                        : <String>[];

                    // build options list
                    return Column(
                      children: [
                        ...options.map((opt) {
                          final id = opt['id'] as String;
                          final label = opt['label'] as String;
                          final count = counts[id] ?? 0;
                          final pct = total == 0 ? 0.0 : (count / total);

                          if (allowMultiple) {
                            final checked = _selected.contains(id) || userSelected.contains(id);
                            return Column(
                              children: [
                                CheckboxListTile(
                                  value: checked,
                                  title: Text('$label'),
                                  onChanged: alreadyVoted
                                      ? null
                                      : (val) {
                                          setState(() {
                                            if (val == true) {
                                              if (!_selected.contains(id)) _selected.add(id);
                                            } else {
                                              _selected.remove(id);
                                            }
                                          });
                                        },
                                ),
                                LinearProgressIndicator(value: pct),
                                const SizedBox(height: 6),
                                Align(alignment: Alignment.centerRight, child: Text('$count votes')),
                                const SizedBox(height: 8),
                              ],
                            );
                          }

                          final checked = (_selected.isNotEmpty ? _selected.first == id : userSelected.contains(id));
                          return Column(
                            children: [
                              RadioListTile<String>(
                                value: id,
                                groupValue: _selected.isEmpty ? (userSelected.isEmpty ? null : userSelected.first) : _selected.first,
                                title: Text(label),
                                onChanged: alreadyVoted
                                    ? null
                                    : (val) {
                                        setState(() {
                                          _selected = [val!];
                                        });
                                      },
                              ),
                              LinearProgressIndicator(value: pct),
                              const SizedBox(height: 6),
                              Align(alignment: Alignment.centerRight, child: Text('$count votes')),
                              const SizedBox(height: 8),
                            ],
                          );
                        }),

                        // Vote button
                        if (!alreadyVoted)
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: _selected.isEmpty
                                  ? null
                                  : () async {
                                      await PollService.vote(
                                        matchId: widget.matchId,
                                        pollId: widget.pollId,
                                        optionIds: _selected,
                                      );
                                      setState(() {});
                                    },
                              child: const Text('Vote'),
                            ),
                          )
                        else
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text('You voted • ${userSelected.length} option(s)'),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
