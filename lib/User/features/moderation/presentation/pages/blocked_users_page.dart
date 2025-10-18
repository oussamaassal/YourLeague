import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/moderation_cubit.dart';
import '../cubits/moderation_states.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // get moderation cubit
    final moderationCubit = context.read<ModerationCubit>();
    // ensure blocked users are loaded
    moderationCubit.loadBlockedUsers();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Blocked Users"),
      ),
      body: BlocBuilder<ModerationCubit, ModerationState>(
        builder: (context, state) {
          // loading..
          if (state is ModerationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // loaded
          final blockedUsers = moderationCubit.blockedUsers;

          // no blocked users..
          if (blockedUsers.isEmpty) {
            return const Center(
              child: Text("You have no blocked users."),
            );
          }

          // show blocked users
          return ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              // get each blocked user
              final blockedUser = blockedUsers[index];
              final displayName = blockedUser.blockedEmail.split('@').first;

              // list tile UI
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(displayName),
                trailing: IconButton(
                  onPressed: () {
                    // unblock user
                    moderationCubit.unblockUser(blockedUser.blockedUid);

                    // show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$displayName unblocked!")));
                  },
                  icon: const Icon(Icons.cancel),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
