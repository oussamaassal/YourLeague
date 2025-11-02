// lib/User/features/teams/presentation/pages/teams_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/firebase_teams_repo.dart';
import '../../domain/entities.dart';
import '../cubits/teams_cubit.dart';
import 'team_detail_page.dart';

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});
  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  final repo = FirebaseTeamsRepo();

  // Discover tab state
  TeamCategory? _selectedCat; // null = All
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 🔑 Make search reactive on every keystroke
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return DefaultTabController(
      length: 2,
      child: BlocProvider(
        create: (_) => TeamsCubit(repo)..watchForUser(uid),
        child: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Teams'),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.bookmark_added_outlined), text: 'My Teams'),
                  Tab(icon: Icon(Icons.explore_outlined), text: 'Discover'),
                ],
              ),
            ),
            floatingActionButton: _buildCreateFab(context, uid),
            body: TabBarView(
              children: [
                // ─── My Teams ────────────────────────────────────────────────
                BlocBuilder<TeamsCubit, TeamsState>(
                  builder: (_, state) {
                    if (state is TeamsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is TeamsError) {
                      return Center(child: Text(state.message));
                    }
                    final teams = (state as TeamsLoaded).teams;
                    if (teams.isEmpty) {
                      return const _EmptyView(
                        icon: Icons.bookmark_added_outlined,
                        title: 'No teams yet',
                        subtitle: 'Create a team or join one from Discover',
                      );
                    }
                    return ListView.separated(
                      itemCount: teams.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final t = teams[i];
                        final isOwner = t.ownerUid == uid;
                        return ListTile(
                          leading: const Icon(Icons.groups),
                          title: Text(t.name),
                          subtitle: Text('Category: ${teamCategoryToString(t.category)}'),
                          trailing: isOwner
                              ? IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => context.read<TeamsCubit>().deleteTeam(t.id),
                          )
                              : null,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TeamDetailPage(teamId: t.id, ownerUid: t.ownerUid),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // ─── Discover ────────────────────────────────────────────────
                Column(
                  children: [
                    _DiscoverFilters(
                      selected: _selectedCat,
                      onChanged: (c) => setState(() => _selectedCat = c),
                      searchCtrl: _searchCtrl,
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: StreamBuilder<List<Team>>(
                        stream: repo.watchPublicTeams(category: _selectedCat),
                        builder: (_, snap) {
                          if (!snap.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          var teams = snap.data!;
                          final q = _searchCtrl.text
                              .replaceAll(RegExp(r'\s+'), ' ')
                              .trim()
                              .toLowerCase();

                          if (q.isNotEmpty) {
                            teams = teams
                                .where((t) => t.name.toLowerCase().contains(q))
                                .toList();
                          }

                          if (teams.isEmpty) {
                            return const _EmptyView(
                              icon: Icons.search_off,
                              title: 'No teams found',
                              subtitle: 'Try another category or search',
                            );
                          }

                          final uid = FirebaseAuth.instance.currentUser!.uid;
                          return ListView.separated(
                            itemCount: teams.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final t = teams[i];
                              return ListTile(
                                leading: const Icon(Icons.public),
                                title: Text(t.name),
                                subtitle: Text('Category: ${teamCategoryToString(t.category)}'),
                                trailing: _ApplyButton(teamId: t.id, myUid: uid, repo: repo),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeamDetailPage(teamId: t.id, ownerUid: t.ownerUid),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Floating action button only visible on "My Teams" tab
  Widget _buildCreateFab(BuildContext context, String uid) {
    return Builder(builder: (context) {
      final tabIndex = DefaultTabController.of(context).index;
      if (tabIndex != 0) return const SizedBox.shrink();

      return FloatingActionButton(
        onPressed: () async {
          final nameCtrl = TextEditingController();
          TeamCategory selected = TeamCategory.other;
          final formKey = GlobalKey<FormState>();

          final ok = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: const Text('Create Team'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Team name',
                          hintText: 'e.g. Red Tigers',
                        ),
                        validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Please enter a team name' : null,
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Category:'),
                          const SizedBox(width: 12),
                          DropdownButton<TeamCategory>(
                            value: selected,
                            items: TeamCategory.values
                                .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(teamCategoryToString(c)),
                            ))
                                .toList(),
                            onChanged: (v) => setState(() => selected = v ?? selected),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text('Create'),
                  ),
                ],
              ),
            ),
          );

          if (ok == true) {
            await context.read<TeamsCubit>().create(uid, nameCtrl.text.trim(), selected);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Team created')),
              );
            }
          }
        },
        child: const Icon(Icons.add),
      );
    });
  }
}

class _DiscoverFilters extends StatelessWidget {
  final TeamCategory? selected;
  final void Function(TeamCategory?) onChanged;
  final TextEditingController searchCtrl;
  const _DiscoverFilters({
    required this.selected,
    required this.onChanged,
    required this.searchCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by team name',
              ),
              // no onChanged needed; listener in initState() handles rebuilds
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<TeamCategory?>(
            value: selected,
            hint: const Text('All'),
            items: <TeamCategory?>[null, ...TeamCategory.values]
                .map((c) => DropdownMenuItem(
              value: c,
              child: Text(c == null ? 'All' : teamCategoryToString(c)),
            ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyView({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Discover-tab trailing button: only "Apply" or "Applied".
/// - If already a member -> no button.
/// - If request exists -> "Applied" disabled.
/// - If no request -> "Apply" sends join request and shows snackbar.
class _ApplyButton extends StatelessWidget {
  final String teamId;
  final String myUid;
  final FirebaseTeamsRepo repo;
  const _ApplyButton({required this.teamId, required this.myUid, required this.repo});

  @override
  Widget build(BuildContext context) {
    final teamRef = FirebaseFirestore.instance.collection('teams').doc(teamId);

    // Already a member?
    final memberStream = teamRef
        .collection('members')
        .where('userId', isEqualTo: myUid)
        .limit(1)
        .snapshots();

    // Existing pending request?
    final reqStream = teamRef
        .collection('join_requests')
        .doc(myUid)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: memberStream,
      builder: (context, memberSnap) {
        final isMember = memberSnap.hasData && memberSnap.data!.docs.isNotEmpty;
        if (isMember) {
          // Already in the team → no button
          return const SizedBox.shrink();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: reqStream,
          builder: (context, reqSnap) {
            final pending = reqSnap.hasData && reqSnap.data!.exists;

            if (pending) {
              // Request exists (pending) → show disabled "Applied"
              return const FilledButton.tonal(
                onPressed: null,
                child: Text('Applied'),
              );
            }

            // No request doc → can apply
            return FilledButton.tonalIcon(
              icon: const Icon(Icons.how_to_reg),
              label: const Text('Apply'),
              onPressed: () async {
                await repo.requestJoin(teamId: teamId, userId: myUid, message: '');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request sent')),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
