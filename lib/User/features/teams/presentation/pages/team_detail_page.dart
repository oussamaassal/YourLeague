import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/firebase_teams_repo.dart';
import '../../domain/entities.dart';
import '../cubits/members_cubit.dart';
import '../cubits/requests_cubit.dart';

// ⬇️ Players finder page
import '../../../players/presentation/pages/find_players_page.dart';

class TeamDetailPage extends StatelessWidget {
  final String teamId;
  final String ownerUid;

  const TeamDetailPage({
    super.key,
    required this.teamId,
    required this.ownerUid,
  });

  @override
  Widget build(BuildContext context) {
    final repo = FirebaseTeamsRepo();
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MembersCubit(repo)..watch(teamId)),
        BlocProvider(create: (_) => RequestsCubit(repo)..watch(teamId)),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Team'),
          actions: [
            // Show "Find Players" if current user is owner or organizer
            BlocBuilder<MembersCubit, MembersState>(
              buildWhen: (p, c) => c is MembersLoaded || c is MembersLoading,
              builder: (context, state) {
                if (state is! MembersLoaded) return const SizedBox.shrink();

                final members = state.members;
                // Determine if current user is owner or organizer in THIS team
                final me = members.firstWhere(
                      (m) => m.userId == myUid,
                  orElse: () => Member(
                    id: '',
                    userId: '',
                    role: MemberRole.player,
                    createdAt: DateTime(1970),
                  ),
                );
                final isManager =
                    me.role == MemberRole.owner || me.role == MemberRole.organizer;

                if (!isManager) return const SizedBox.shrink();

                return IconButton(
                  tooltip: 'Find players',
                  icon: const Icon(Icons.person_search),
                  onPressed: () async {
                    // 1) Fetch team category once (we only have teamId here)
                    final snap = await FirebaseFirestore.instance
                        .collection('teams')
                        .doc(teamId)
                        .get();

                    if (!snap.exists || snap.data() == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Team not found')),
                        );
                      }
                      return;
                    }

                    final catStr = (snap.data()!['category'] ?? 'other') as String;
                    final teamCat = teamCategoryFromString(catStr);

                    // 2) Collect current member userIds to exclude from search results
                    final currentState = context.read<MembersCubit>().state;
                    final userIds = <String>{};
                    if (currentState is MembersLoaded) {
                      for (final m in currentState.members) {
                        userIds.add(m.userId);
                      }
                    }

                    // 3) Navigate to FindPlayersPage
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FindPlayersPage(
                            teamId: teamId,
                            teamCategory: teamCat,
                            currentMemberUserIds: userIds,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // ───────── Members list ─────────
            Expanded(
              child: BlocBuilder<MembersCubit, MembersState>(
                builder: (_, s) {
                  if (s is MembersLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (s is MembersError) {
                    return Center(child: Text(s.message));
                  }

                  final members = (s as MembersLoaded).members;
                  if (members.isEmpty) {
                    return const Center(child: Text('No members yet'));
                  }

                  return ListView.separated(
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final m = members[i];

                      final display =
                      m.userId.contains('@') ? m.userId.split('@').first : m.userId;

                      final isOwner = m.role == MemberRole.owner;
                      final amOwner = myUid == ownerUid;

                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(display),
                        subtitle: Text(memberRoleToString(m.role)),
                        trailing: amOwner && !isOwner
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<MemberRole>(
                              value: m.role,
                              items: MemberRole.values
                                  .map(
                                    (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(memberRoleToString(r)),
                                ),
                              )
                                  .toList(),
                              onChanged: (r) {
                                if (r != null) {
                                  context
                                      .read<MembersCubit>()
                                      .changeRole(teamId, m.id, r);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => context
                                  .read<MembersCubit>()
                                  .remove(teamId, m.id),
                            ),
                          ],
                        )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // ───────── Join requests (owner only) ─────────
            Expanded(
              child: _RequestsPanel(teamId: teamId, ownerUid: ownerUid),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsPanel extends StatefulWidget {
  final String teamId;
  final String ownerUid;
  const _RequestsPanel({required this.teamId, required this.ownerUid});

  @override
  State<_RequestsPanel> createState() => _RequestsPanelState();
}

class _RequestsPanelState extends State<_RequestsPanel> {
  // Persist selections per requester uid
  final Map<String, MemberRole> _selectedRole = {};

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final amOwner = myUid == widget.ownerUid;

    return BlocBuilder<RequestsCubit, RequestsState>(
      builder: (_, s) {
        if (s is RequestsLoading) return const Center(child: CircularProgressIndicator());
        if (s is RequestsError) return Center(child: Text(s.message));
        final pending = (s as RequestsLoaded).userIds;

        // Remove selections for uids no longer pending
        _selectedRole.removeWhere((k, v) => !pending.contains(k));

        if (!amOwner) {
          return const SizedBox.shrink();
        }

        if (pending.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child:
            Align(alignment: Alignment.centerLeft, child: Text('No pending requests')),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Join requests', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: pending.length,
                itemBuilder: (_, i) {
                  final uid = pending[i];
                  final role = _selectedRole[uid] ?? MemberRole.player;

                  return ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: Text(uid.contains('@') ? uid.split('@').first : uid),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<MemberRole>(
                          value: role,
                          items: MemberRole.values
                              .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(memberRoleToString(r)),
                          ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedRole[uid] = v);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Decline',
                          onPressed: () async {
                            await context
                                .read<RequestsCubit>()
                                .respond(widget.teamId, uid, false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Request declined')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.check),
                          tooltip: 'Accept',
                          onPressed: () async {
                            final picked = _selectedRole[uid] ?? MemberRole.player;
                            await context.read<RequestsCubit>().respond(
                              widget.teamId,
                              uid,
                              true,
                              roleIfAccept: picked,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Accepted as ${memberRoleToString(picked)}',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
