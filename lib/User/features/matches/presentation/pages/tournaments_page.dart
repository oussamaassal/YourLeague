import 'package:flutter/material.dart';
import 'package:yourleague/User/features/matches/presentation/pages/leaderboards_page.dart';
import 'package:yourleague/User/features/matches/presentation/pages/bracket_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yourleague/User/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:intl/intl.dart';

class TournamentsPage extends StatefulWidget {
  const TournamentsPage({super.key});

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  Future<void> _addTournamentDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Tournament'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => startDate = picked);
                        }
                      },
                      child: Text(startDate == null ? 'Pick start date' : 'Start: ${startDate!.toLocal().toString().split(' ').first}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => endDate = picked);
                        }
                      },
                      child: Text(endDate == null ? 'Pick end date' : 'End: ${endDate!.toLocal().toString().split(' ').first}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final currentUid = context.read<AuthCubit>().currentUser?.uid;
              if (currentUid == null) return;

              final doc = fs.FirebaseFirestore.instance.collection('tournaments').doc();

              final Map<String, dynamic> data = {
                'name': name,
                'description': descCtrl.text.trim(),
                'status': 'inProgress',
                'organizer': fs.FirebaseFirestore.instance.collection('users').doc(currentUid),
                'matches': <fs.DocumentReference>[],
                'createdAt': fs.Timestamp.now(),
              };
              if (startDate != null) {
                data['startDate'] = fs.Timestamp.fromDate(startDate!);
              }
              if (endDate != null) {
                data['endDate'] = fs.Timestamp.fromDate(endDate!);
              }
              // Do not include 'location' key if it's not set; avoid FieldValue.delete()

              await doc.set(data);

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addTournamentDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<fs.QuerySnapshot<Map<String, dynamic>>>(
        stream: fs.FirebaseFirestore.instance
            .collection('tournaments')
            .orderBy('startDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No tournaments yet'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data();
              final name = (data['name'] as String?)?.trim();
              final title = (name != null && name.isNotEmpty) ? name : d.id;
              final organizerRef = data['organizer'];
              String? organizerUid;
              if (organizerRef is fs.DocumentReference) organizerUid = organizerRef.id;
              if (organizerRef is String) {
                final parts = organizerRef.split('/');
                organizerUid = parts.isNotEmpty ? parts.last : null;
              }

              final status = (data['status'] as String?) ?? 'unknown';
              final tsStart = data['startDate'];
              final tsEnd = data['endDate'];
              String dateText = '';
              if (tsStart is fs.Timestamp) {
                final s = tsStart.toDate();
                final e = tsEnd is fs.Timestamp ? tsEnd.toDate() : null;
                dateText = e == null ? df.format(s) : '${df.format(s)} - ${df.format(e)}';
              }
              String locText = '';
              final geo = data['location'];
              if (geo is fs.GeoPoint) {
                locText = '(${geo.latitude.toStringAsFixed(3)}, ${geo.longitude.toStringAsFixed(3)})';
              }

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(title.isNotEmpty ? title[0].toUpperCase() : '#', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: $status'),
                      if (dateText.isNotEmpty) Text('Dates: $dateText'),
                      if (locText.isNotEmpty) Text('Location: $locText'),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.account_tree),
                        tooltip: 'Bracket',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BracketPage(
                                tournamentId: d.id,
                                organizerUid: organizerUid,
                              ),
                            ),
                          );
                        },
                      ),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LeaderboardsPage(tournamentId: d.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
