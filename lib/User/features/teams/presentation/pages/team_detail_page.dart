import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/firebase_teams_repo.dart';
import '../../domain/entities.dart';
import '../cubits/members_cubit.dart';
import '../cubits/requests_cubit.dart';

class TeamDetailPage extends StatelessWidget {
  final String teamId;
  final String ownerUid;
  const TeamDetailPage({super.key, required this.teamId, required this.ownerUid});

  @override
  Widget build(BuildContext context) {
    final repo = FirebaseTeamsRepo();
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final isOwner = myUid == ownerUid;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MembersCubit(repo)..watch(teamId)),
        if (isOwner) BlocProvider(create: (_) => RequestsCubit(repo)..watch(teamId)),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Team')),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<MembersCubit, MembersState>(
                builder: (_, s) {
                  if (s is MembersLoading) return const Center(child: CircularProgressIndicator());
                  if (s is MembersError) return Center(child: Text(s.message));
                  final members = (s as MembersLoaded).members;
                  return ListView.separated(
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final m = members[i];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(m.userId), // TODO: replace with display name
                        subtitle: Text(memberRoleToString(m.role)),
                        trailing: isOwner && m.role != MemberRole.owner
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<MemberRole>(
                              value: m.role,
                              items: MemberRole.values
                                  .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(memberRoleToString(r)),
                              ))
                                  .toList(),
                              onChanged: (r) {
                                if (r != null) {
                                  context.read<MembersCubit>().changeRole(teamId, m.id, r);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => context.read<MembersCubit>().remove(teamId, m.id),
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
            if (isOwner) const Divider(),
            if (isOwner) Expanded(child: _RequestsPanel(teamId: teamId)),
          ],
        ),
      ),
    );
  }
}

class _RequestsPanel extends StatefulWidget {
  final String teamId;
  const _RequestsPanel({required this.teamId});

  @override
  State<_RequestsPanel> createState() => _RequestsPanelState();
}

class _RequestsPanelState extends State<_RequestsPanel> {
  // Persist selections per requester uid
  final Map<String, MemberRole> _selectedRole = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RequestsCubit, RequestsState>(
      builder: (_, s) {
        if (s is RequestsLoading) return const Center(child: CircularProgressIndicator());
        if (s is RequestsError) return Center(child: Text(s.message));
        final pending = (s as RequestsLoaded).userIds;

        // Remove selections for uids no longer pending
        _selectedRole.removeWhere((k, v) => !pending.contains(k));

        if (pending.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Align(alignment: Alignment.centerLeft, child: Text('No pending requests')),
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
                            await context.read<RequestsCubit>().respond(widget.teamId, uid, false);
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
                            await context
                                .read<RequestsCubit>()
                                .respond(widget.teamId, uid, true, roleIfAccept: picked);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Accepted as ${memberRoleToString(picked)}')),
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
