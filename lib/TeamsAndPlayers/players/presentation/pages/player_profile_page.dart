import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repos/players_repo.dart';
import '../../data/firebase_players_repo.dart';
import '../cubits/player_profile_cubit.dart';

class PlayerProfilePage extends StatefulWidget {
  const PlayerProfilePage({super.key});

  @override
  State<PlayerProfilePage> createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends State<PlayerProfilePage> {
  final _repo = FirebasePlayersRepo();
  final _handleCtrl = TextEditingController();
  bool _available = false;
  final Set<String> _categories = {};

  @override
  void dispose() {
    _handleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return BlocProvider(
      create: (_) => PlayerProfileCubit(_repo)..watch(uid),
      child: Scaffold(
        appBar: AppBar(title: const Text('Player Profile')),
        body: BlocBuilder<PlayerProfileCubit, PlayerProfileState>(
          builder: (context, state) {
            if (state is PlayerProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PlayerProfileError) {
              return Center(child: Text(state.message));
            }
            final me = (state as PlayerProfileLoaded).me;
            if (me != null && _handleCtrl.text.isEmpty) {
              _handleCtrl.text = me.handle;
              _available = me.available;
              _categories
                ..clear()
                ..addAll(me.categories);
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _handleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Handle',
                    hintText: 'e.g. ahmed.gamer',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                  title: const Text('Available for invites'),
                ),
                const SizedBox(height: 8),
                const Text('Categories'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final c in const ['football','basketball','volleyball','other'])
                      FilterChip(
                        label: Text(c),
                        selected: _categories.contains(c),
                        onSelected: (s) => setState(() {
                          if (s) _categories.add(c);
                          else _categories.remove(c);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    await context.read<PlayerProfileCubit>().save(
                      userId: uid,
                      handle: _handleCtrl.text.trim().isEmpty
                          ? FirebaseAuth.instance.currentUser!.email!.split('@').first
                          : _handleCtrl.text.trim(),
                      available: _available,
                      categories: _categories.toList(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile saved')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
