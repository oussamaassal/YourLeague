// lib/User/features/players/presentation/pages/find_players_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../teams/domain/entities.dart';
import '../../data/firebase_players_repo.dart';
import '../cubits/players_search_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FindPlayersPage extends StatefulWidget {
  final String teamId;
  final TeamCategory teamCategory;
  final Set<String> currentMemberUserIds;

  const FindPlayersPage({
    super.key,
    required this.teamId,
    required this.teamCategory,
    required this.currentMemberUserIds,
  });

  @override
  State<FindPlayersPage> createState() => _FindPlayersPageState();
}

class _FindPlayersPageState extends State<FindPlayersPage> {
  final _repo = FirebasePlayersRepo();
  final _searchCtrl = TextEditingController();
  late final PlayersSearchCubit _cubit;

  // track invited players
  Set<String> invitedPlayerIds = {};

  @override
  void initState() {
    super.initState();
    _cubit = PlayersSearchCubit(_repo);

    // initial search
    _cubit.search(
      category: teamCategoryToString(widget.teamCategory),
      handlePrefixLower: '',
    );

    // live search
    _searchCtrl.addListener(() {
      _cubit.search(
        category: teamCategoryToString(widget.teamCategory),
        handlePrefixLower: _searchCtrl.text.trim().toLowerCase(),
      );
    });

    _loadInvitedPlayers();
  }

  Future<void> _loadInvitedPlayers() async {
    final snap = await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('invites')
        .get();

    setState(() {
      invitedPlayerIds = snap.docs.map((d) => d.id).toSet();
    });
  }

  Future<void> _sendInvite(String playerId, String handle) async {
    await _repo.sendInvite(
      teamId: widget.teamId,
      playerId: playerId,
      roleOffered: 'player',
    );
    setState(() {
      invitedPlayerIds.add(playerId);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invite sent to $handle')),
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Find players (${teamCategoryToString(widget.teamCategory)})'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search handle…',
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<PlayersSearchCubit, PlayersSearchState>(
                builder: (_, s) {
                  if (s is PlayersSearchLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (s is PlayersSearchError) {
                    return Center(child: Text(s.message));
                  }
                  final players = (s as PlayersSearchLoaded)
                      .players
                      .where((p) => !widget.currentMemberUserIds.contains(p.userId))
                      .toList();

                  if (players.isEmpty) {
                    return const Center(child: Text('No players found'));
                  }

                  return ListView.separated(
                    itemCount: players.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = players[i];
                      final alreadyInvited = invitedPlayerIds.contains(p.userId);

                      return ListTile(
                        leading: const Icon(Icons.person_add_alt_1),
                        title: Text(p.handle),
                        subtitle: Text(
                          'Cats: ${p.categories.join(", ")} • Recs: ${p.recommendations}',
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: alreadyInvited
                              ? null
                              : () async => await _sendInvite(p.userId, p.handle),
                          child: Text(alreadyInvited ? 'Invited' : 'Invite'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
