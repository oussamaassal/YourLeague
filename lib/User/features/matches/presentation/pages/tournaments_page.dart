import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_cubit.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_states.dart';
import 'package:yourleague/User/features/matches/presentation/pages/leaderboards_page.dart';

class TournamentsPage extends StatefulWidget {
  const TournamentsPage({super.key});

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  final List<String> _tournaments = [
    'tournament1',
    'tournament2',
    'tournament3',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddTournamentDialog(context);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _tournaments.length,
        itemBuilder: (context, index) {
          final tournamentId = _tournaments[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  (index + 1).toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text('Tournament ${index + 1}'),
              subtitle: Text('ID: $tournamentId'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeaderboardsPage(tournamentId: tournamentId),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddTournamentDialog(BuildContext context) {
    final TextEditingController tournamentIdController = TextEditingController();
    final TextEditingController tournamentNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tournament'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tournamentIdController,
              decoration: const InputDecoration(labelText: 'Tournament ID'),
            ),
            TextField(
              controller: tournamentNameController,
              decoration: const InputDecoration(labelText: 'Tournament Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tournamentIdController.text.isNotEmpty) {
                setState(() {
                  _tournaments.add(tournamentIdController.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

