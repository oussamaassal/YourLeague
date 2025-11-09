import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_cubit.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_states.dart';
import 'package:yourleague/User/features/matches/domain/entities/leaderboard.dart';
import 'package:yourleague/User/features/matches/presentation/pages/bracket_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:yourleague/User/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:yourleague/common/services/weather_service.dart';

class LeaderboardsPage extends StatefulWidget {
  final String tournamentId;
  const LeaderboardsPage({super.key, required this.tournamentId});

  @override
  State<LeaderboardsPage> createState() => _LeaderboardsPageState();
}

class _LeaderboardsPageState extends State<LeaderboardsPage> {
  String get tournamentName => widget.tournamentId.replaceAll('tournament', 'Tournament ');

  List<Leaderboard> _lastLeaderboards = const [];
  bool _isOrganizer = false;
  WeatherInfo? _weather;
  String? _weatherError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<MatchesCubit>().getLeaderboardsByTournament(widget.tournamentId);
      await _loadOrganizer();
      await _loadWeather();
    });
  }

  Future<void> _loadOrganizer() async {
    try {
      final currentUid = context.read<AuthCubit>().currentUser?.uid;
      if (currentUid == null) return;
      final doc = await fs.FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      final organizerRef = data['organizer'];
      String? organizerUid;
      if (organizerRef is fs.DocumentReference) organizerUid = organizerRef.id;
      if (organizerRef is String) {
        final parts = organizerRef.split('/');
        organizerUid = parts.isNotEmpty ? parts.last : null;
      }
      setState(() {
        _isOrganizer = organizerUid != null && organizerUid == currentUid;
      });
    } catch (_) {}
  }

  Future<void> _loadWeather() async {
    try {
      final doc = await fs.FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      final geo = data['location'];
      if (geo is fs.GeoPoint && WeatherService.isEnabled) {
        final info = await WeatherService.getCurrent(lat: geo.latitude, lon: geo.longitude);
        if (!mounted) return;
        setState(() { _weather = info; _weatherError = WeatherService.lastError; });
      } else if (!(WeatherService.isEnabled)) {
        setState(() { _weatherError = 'Weather disabled (no API key)'; });
      } else {
        setState(() { _weatherError = 'No location set for tournament'; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _weatherError = 'Weather error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _isOrganizer;

    return Scaffold(
      appBar: AppBar(
        title: Text(tournamentName),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: 'Bracket',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BracketPage(tournamentId: widget.tournamentId),
                ),
              );
            },
          ),
          if (canAdd)
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
        listener: (context, state) async {
          if (state is OperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is MatchesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            // keep showing last loaded data
          }
          if (state is LeaderboardsLoaded) {
            setState(() {
              _lastLeaderboards = state.leaderboards;
            });
          }
        },
        builder: (context, state) {
          final leaderboards = (state is LeaderboardsLoaded) ? state.leaderboards : _lastLeaderboards;

          // Weather header (if any)
          final weatherHeader = (_weather != null)
              ? Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Image.network(_weather!.iconUrl, width: 48, height: 48, errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_weather!.tempC.toStringAsFixed(1)}°C • ${_weather!.description}'),
                            const SizedBox(height: 4),
                            Text('Wind ${_weather!.windSpeed.toStringAsFixed(1)} m/s • Humidity ${_weather!.humidity}%'),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh weather',
                        onPressed: _loadWeather,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                )
              : (_weatherError != null)
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_weatherError!, style: TextStyle(color: Theme.of(context).hintColor))),
                          IconButton(onPressed: _loadWeather, icon: const Icon(Icons.refresh))
                        ],
                      ),
                    )
                  : const SizedBox.shrink();

          if (leaderboards.isEmpty) {
            return Column(
              children: [
                weatherHeader,
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.leaderboard, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No leaderboard entries', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          canAdd ? 'Add teams to see tournament standings' : 'Waiting for organizer to add teams',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              weatherHeader,
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
                          Text('Tournament Standings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text('${leaderboards.length} / 8 teams', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (canAdd)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showModifierDialog(context, leaderboards),
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
                    rows: leaderboards.asMap().entries.map((entry) {
                      final index = entry.key;
                      final lb = entry.value;
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                Text('${index + 1}'),
                                if (canAdd) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _showDeleteConfirmation(context, lb),
                                    tooltip: 'Delete team',
                                  ),
                                ],
                              ],
                            ),
                          ),
                          DataCell(
                            GestureDetector(
                              onTap: canAdd ? () => _showEditTeamDialog(context, lb) : null,
                              child: Text(lb.teamName),
                            ),
                          ),
                          DataCell(
                            GestureDetector(
                              onTap: canAdd ? () => _showEditTeamDialog(context, lb) : null,
                              child: Text(lb.matchesPlayed.toString()),
                            ),
                          ),
                          DataCell(
                            GestureDetector(
                              onTap: canAdd ? () => _showEditTeamDialog(context, lb) : null,
                              child: Text(lb.wins.toString()),
                            ),
                          ),
                          DataCell(Text(lb.draws.toString())),
                          DataCell(Text(lb.losses.toString())),
                          DataCell(Text(lb.goalsFor.toString())),
                          DataCell(Text(lb.goalsAgainst.toString())),
                          DataCell(Text(lb.goalDifference.toString())),
                          DataCell(
                            Text(
                              lb.points.toString(),
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
              ...leaderboards.map((leaderboard) => ListTile(
                    title: Text(leaderboard.teamName),
                    subtitle: Text('Pts: ${leaderboard.points} | MP: ${leaderboard.matchesPlayed}'),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditTeamDialog(context, leaderboard);
                    },
                  )),
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
      title: const Text('Add Team to Leaderboard (max 8)'),
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
