import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/firebase_teams_repo.dart';
import '../../domain/entities.dart';
import '../cubits/teams_cubit.dart';
import 'team_detail_page.dart';

class BrowseTeamsPage extends StatefulWidget {
  const BrowseTeamsPage({super.key});
  @override
  State<BrowseTeamsPage> createState() => _BrowseTeamsPageState();
}

class _BrowseTeamsPageState extends State<BrowseTeamsPage> {
  TeamCategory cat = TeamCategory.football;
  final repo = FirebaseTeamsRepo();
  List<Team> data = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Teams')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: DropdownButton<TeamCategory>(
              value: cat,
              items: TeamCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(teamCategoryToString(c)))).toList(),
              onChanged: (v) => setState(() => cat = v ?? cat),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Team>>(
              stream: repo.browseTeamsByCategory(cat),
              builder: (_, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final teams = snap.data!;
                if (teams.isEmpty) return const Center(child: Text('No public teams for this category'));
                return ListView.builder(
                  itemCount: teams.length,
                  itemBuilder: (_, i) {
                    final t = teams[i];
                    return ListTile(
                      leading: const Icon(Icons.groups_2),
                      title: Text(t.name),
                      subtitle: Text('Category: ${teamCategoryToString(t.category)}'),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeamDetailPage(teamId: t.id, ownerUid: t.ownerUid))),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
