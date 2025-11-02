import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repos/players_repo.dart';
import '../../data/firebase_players_repo.dart';
import '../cubits/invites_cubit.dart';

class PlayerInvitesPage extends StatelessWidget {
  const PlayerInvitesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final repo = FirebasePlayersRepo();
    return BlocProvider(
      create: (_) => UserInvitesCubit(repo)..watch(uid),
      child: Scaffold(
        appBar: AppBar(title: const Text('My Invites')),
        body: BlocBuilder<UserInvitesCubit, UserInvitesState>(
          builder: (_, s) {
            if (s is UserInvitesLoading) return const Center(child: CircularProgressIndicator());
            if (s is UserInvitesError) return Center(child: Text(s.message));
            final invites = (s as UserInvitesLoaded).invites;
            if (invites.isEmpty) return const Center(child: Text('No pending invites'));
            return ListView.separated(
              itemCount: invites.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final inv = invites[i];
                return ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: Text('Team: ${inv.teamId}'),
                  subtitle: Text('Role: ${inv.roleOffered}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.read<UserInvitesCubit>().decline(inv.teamId, uid),
                        child: const Text('Decline'),
                      ),
                      FilledButton(
                        onPressed: () => context.read<UserInvitesCubit>().accept(inv.teamId, uid),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
