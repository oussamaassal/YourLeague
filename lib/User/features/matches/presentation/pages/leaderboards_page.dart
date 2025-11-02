import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_cubit.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_states.dart';
import 'package:yourleague/User/features/matches/domain/entities/leaderboard.dart';

class LeaderboardsPage extends StatefulWidget {
  final String tournamentId;
  const LeaderboardsPage({super.key, required this.tournamentId});

  @override
  State<LeaderboardsPage> createState() => _LeaderboardsPageState();
}

class _LeaderboardsPageState extends State<LeaderboardsPage> {
  String get tournamentName => widget.tournamentId.replaceAll('tournament', 'Tournament ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchesCubit>().getLeaderboardsByTournament(widget.tournamentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tournamentName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddLeaderboardDialog(tournamentId: widget.tournamentId),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<MatchesCubit, MatchesState>(
        listener: (context, state) {
          if (state is OperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            // Ne pas recharger ici car c'est déjà fait dans le cubit
          }
          if (state is MatchesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is LeaderboardsLoaded) {
            if (state.leaderboards.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.leaderboard, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No leaderboard entries',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add teams to see tournament standings',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Header avec info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tournament Standings',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${state.leaderboards.length} teams',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showModifierDialog(context, state.leaderboards);
                        },
                        tooltip: 'Modify Leaderboard',
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          context.read<MatchesCubit>().getLeaderboardsByTournament(widget.tournamentId);
                        },
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),
                // DataTable
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                columns: const [
                  DataColumn(label: Text('Rank')),
                  DataColumn(label: Text('Team')),
                  DataColumn(label: Text('MP')),
                  DataColumn(label: Text('W')),
                  DataColumn(label: Text('D')),
                  DataColumn(label: Text('L')),
                  DataColumn(label: Text('GF')),
                  DataColumn(label: Text('GA')),
                  DataColumn(label: Text('GD')),
                  DataColumn(label: Text('Pts')),
                ],
                rows: state.leaderboards.asMap().entries.map((entry) {
                  final index = entry.key;
                  final leaderboard = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Text('${index + 1}'),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _showDeleteConfirmation(context, leaderboard),
                              tooltip: 'Delete team',
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        GestureDetector(
                          onTap: () => _showEditTeamDialog(context, leaderboard),
                          child: Text(leaderboard.teamName),
                        ),
                      ),
                      DataCell(
                        GestureDetector(
                          onTap: () => _showEditTeamDialog(context, leaderboard),
                          child: Text(leaderboard.matchesPlayed.toString()),
                        ),
                      ),
                      DataCell(
                        GestureDetector(
                          onTap: () => _showEditTeamDialog(context, leaderboard),
                          child: Text(leaderboard.wins.toString()),
                        ),
                      ),
                      DataCell(Text(leaderboard.draws.toString())),
                      DataCell(Text(leaderboard.losses.toString())),
                      DataCell(Text(leaderboard.goalsFor.toString())),
                      DataCell(Text(leaderboard.goalsAgainst.toString())),
                      DataCell(Text(leaderboard.goalDifference.toString())),
                      DataCell(
                        Text(
                          leaderboard.points.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                    ),
                  ),
                ),
              ],
            );
          }

          // État par défaut - loading
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _showEditTeamDialog(BuildContext context, Leaderboard leaderboard) {
    final teamNameController = TextEditingController(text: leaderboard.teamName);
    final winsController = TextEditingController(text: leaderboard.wins.toString());
    final drawsController = TextEditingController(text: leaderboard.draws.toString());
    final lossesController = TextEditingController(text: leaderboard.losses.toString());
    final goalsForController = TextEditingController(text: leaderboard.goalsFor.toString());
    final goalsAgainstController = TextEditingController(text: leaderboard.goalsAgainst.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Team Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: teamNameController,
                decoration: const InputDecoration(labelText: 'Team Name'),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: winsController,
                      decoration: const InputDecoration(labelText: 'Wins'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: drawsController,
                      decoration: const InputDecoration(labelText: 'Draws'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: lossesController,
                decoration: const InputDecoration(labelText: 'Losses'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: goalsForController,
                      decoration: const InputDecoration(labelText: 'Goals For'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: goalsAgainstController,
                      decoration: const InputDecoration(labelText: 'Goals Against'),
                      keyboardType: TextInputType.number,
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
            onPressed: () {
              final teamName = teamNameController.text;
              final wins = int.tryParse(winsController.text) ?? leaderboard.wins;
              final draws = int.tryParse(drawsController.text) ?? leaderboard.draws;
              final losses = int.tryParse(lossesController.text) ?? leaderboard.losses;
              final goalsFor = int.tryParse(goalsForController.text) ?? leaderboard.goalsFor;
              final goalsAgainst = int.tryParse(goalsAgainstController.text) ?? leaderboard.goalsAgainst;
              final matchesPlayed = wins + draws + losses;
              final points = wins * 3 + draws;
              final goalDifference = goalsFor - goalsAgainst;

              final updatedLeaderboard = Leaderboard(
                id: leaderboard.id,
                tournamentId: leaderboard.tournamentId,
                teamId: leaderboard.teamId,
                teamName: teamName,
                matchesPlayed: matchesPlayed,
                wins: wins,
                draws: draws,
                losses: losses,
                goalsFor: goalsFor,
                goalsAgainst: goalsAgainst,
                points: points,
                goalDifference: goalDifference,
                updatedAt: leaderboard.updatedAt,
              );

              context.read<MatchesCubit>().updateLeaderboard(updatedLeaderboard);
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Leaderboard leaderboard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete ${leaderboard.teamName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<MatchesCubit>().deleteLeaderboard(leaderboard.id, widget.tournamentId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _showModifierDialog(BuildContext context, List<Leaderboard> leaderboards) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modify Leaderboard'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text('Select a team to modify:'),
              const SizedBox(height: 16),
              ...leaderboards.map((leaderboard) => 
                ListTile(
                  title: Text(leaderboard.teamName),
                  subtitle: Text('Pts: ${leaderboard.points} | MP: ${leaderboard.matchesPlayed}'),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditTeamDialog(context, leaderboard);
                  },
                )
              ).toList(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AddLeaderboardDialog(tournamentId: widget.tournamentId),
                  );
                },
                child: const Text('Add New Team'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class AddLeaderboardDialog extends StatefulWidget {
  final String tournamentId;
  const AddLeaderboardDialog({super.key, required this.tournamentId});

  @override
  State<AddLeaderboardDialog> createState() => _AddLeaderboardDialogState();
}

class _AddLeaderboardDialogState extends State<AddLeaderboardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Team to Leaderboard'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _teamNameController,
                decoration: const InputDecoration(labelText: 'Team Name'),
                validator: (value) => value?.isEmpty ?? true ? 'Enter team name' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              context.read<MatchesCubit>().createLeaderboard(
                tournamentId: widget.tournamentId,
                teamId: DateTime.now().millisecondsSinceEpoch.toString(),
                teamName: _teamNameController.text,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

