import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_cubit.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_states.dart';
import 'package:yourleague/User/features/matches/domain/entities/match_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yourleague/User/features/polls/poll_service.dart';
import 'package:yourleague/User/features/polls/poll_widget.dart';
import 'package:yourleague/User/features/polls/create_poll_dialog.dart';
import 'package:yourleague/User/features/polls/admin_service.dart';
import 'package:yourleague/User/features/matches/services/match_video_service.dart';
import 'package:yourleague/User/features/matches/presentation/widgets/match_video_card.dart';
import 'package:yourleague/User/features/matches/presentation/dialogs/add_match_video_link_dialog.dart';
import 'package:yourleague/User/features/matches/presentation/dialogs/add_match_video_upload_dialog.dart';
// External server-based video & notification services
import 'package:yourleague/User/services/video_service.dart';
import 'package:yourleague/User/services/match_notification_service.dart';
import 'package:yourleague/User/services/match_push_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class MatchEventsPage extends StatefulWidget {
  final String matchId;
  const MatchEventsPage({super.key, required this.matchId});

  @override
  State<MatchEventsPage> createState() => _MatchEventsPageState();
}

class _MatchEventsPageState extends State<MatchEventsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchesCubit>().getMatchEventsByMatch(widget.matchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddMatchEventDialog(matchId: widget.matchId),
              );
            },
          ),
          // Reminder button - sends email notification
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Send Match Reminder',
            onPressed: () => _sendMatchReminder(),
          ),
          // Vidéos: visible pour tout utilisateur authentifié
          Builder(
            builder: (context) {
              final isLoggedIn = FirebaseAuth.instance.currentUser != null;
              if (!isLoggedIn) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.video_library),
                tooltip: 'Upload vidéo',
                onPressed: () => _pickAndUploadServerVideo(),
              );
            },
          ),
          // Sondages: réservé aux admins
          FutureBuilder<bool>(
            future: AdminService.currentUserIsAdmin(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final isAdmin = snap.data ?? false;
              if (!isAdmin) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.how_to_vote),
                tooltip: 'Create Poll',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => CreatePollDialog(matchId: widget.matchId),
                  );
                },
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
          if (state is MatchesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MatchEventsLoaded) {
            // Show videos, then polls at the top, then events list or a compact placeholder
            return Column(
              children: [
                // Firebase videos
                SizedBox(
                  height: 160,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: MatchVideoService.streamVideosForMatch(widget.matchId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Text('Firebase Videos', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: docs.length,
                              itemBuilder: (context, i) {
                                final data = docs[i].data();
                                return MatchVideoCard(data: data);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Server videos
                SizedBox(
                  height: 160,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: VideoService.listMatchVideos(widget.matchId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final vids = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Text('Server Videos', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: vids.length,
                              itemBuilder: (context, i) {
                                final v = vids[i];
                                return Card(
                                  margin: const EdgeInsets.all(8),
                                  child: Container(
                                    width: 200,
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v['title'] ?? 'No title',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Uploaded: ${v['uploadedAt'] ?? ''}',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        const Spacer(),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final url = v['url'];
                                            if (url != null) {
                                              // Open in browser or player
                                              final uri = Uri.parse(url);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.play_arrow, size: 16),
                                          label: const Text('Play'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: PollService.streamPollsForMatch(widget.matchId),
                      builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) return const SizedBox.shrink();
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          itemBuilder: (context, i) {
                            final d = docs[i];
                            return SizedBox(
                              width: MediaQuery.of(context).size.width * 0.9,
                              child: PollWidget(matchId: widget.matchId, pollId: d.id),
                            );
                          },
                        );
                      },
                    ),
                ),
                const Divider(),
                if (state.events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: const [
                        Icon(Icons.event_available, size: 60, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Aucun événement pour ce match'),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.events.length,
                      itemBuilder: (context, index) {
                        final event = state.events[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: _getEventColor(event.type),
                                  width: 5,
                                ),
                              ),
                            ),
                            child: ListTile(
                              leading: _getEventIcon(event.type),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      event.type.replaceAll('_', ' ').toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getEventColor(event.type),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${event.minute}\'',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (event.playerName != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            event.playerName!,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (event.description != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        event.description!,
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  context.read<MatchesCubit>().deleteMatchEvent(event.id, widget.matchId);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Loading match events...',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<MatchesCubit>().getMatchEventsByMatch(widget.matchId);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getEventIcon(String type) {
    switch (type) {
      case 'goal':
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.sports_soccer, color: Colors.white),
        );
      case 'yellow_card':
        return const CircleAvatar(
          backgroundColor: Colors.yellow,
          child: Icon(Icons.warning_amber_rounded, color: Colors.white),
        );
      case 'red_card':
        return const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.dangerous, color: Colors.white),
        );
      case 'substitution':
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.swap_horiz, color: Colors.white),
        );
      case 'fault':
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.block, color: Colors.white),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.event, color: Colors.white),
        );
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'goal':
        return Colors.green;
      case 'yellow_card':
        return Colors.yellow;
      case 'red_card':
        return Colors.red;
      case 'substitution':
        return Colors.blue;
      case 'fault':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickAndUploadServerVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video, withReadStream: false);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;

      final titleController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Titre vidéo (optionnel)'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: 'Ex: Highlights 2ème mi-temps'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuer')),
          ],
        ),
      );
      if (confirmed != true) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload en cours...')));
      final record = await VideoService.uploadMatchVideo(
        matchId: widget.matchId,
        file: File(file.path!),
        title: titleController.text.isEmpty ? null : titleController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vidéo uploadée sur serveur: ${record['title'] ?? 'Sans titre'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur upload serveur: $e')));
    }
  }

  Future<void> _openNotificationDialog() async {
    final recipientsController = TextEditingController();
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notifier par email'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: recipientsController,
                decoration: const InputDecoration(
                  labelText: 'Emails (séparés par des virgules)',
                ),
              ),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Sujet (optionnel)'),
              ),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message HTML (optionnel)'),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Envoyer')),
        ],
      ),
    );
    if (send != true) return;
    final raw = recipientsController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun destinataire.')));
      return;
    }
    final recipients = raw.split(',').map((e) => e.trim()).where((e) => e.contains('@')).toList();
    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emails invalides.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Envoi des notifications...')));
    try {
      final ok = await MatchNotificationService.notifyMatch(
        matchId: widget.matchId,
        recipients: recipients,
        subject: subjectController.text.isEmpty ? null : subjectController.text,
        message: messageController.text.isEmpty ? null : messageController.text,
      );
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notifications envoyées (${recipients.length})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur notification: $e')));
    }
  }

  Future<void> _sendMatchReminder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour recevoir des rappels.')),
      );
      return;
    }

    try {
      final ok = await MatchNotificationService.notifyMatch(
        matchId: widget.matchId,
        recipients: [user!.email!],
        subject: 'Match Reminder - YourLeague',
        message: '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #333;">⚽ Match Starting Soon!</h2>
            <p>Hi there,</p>
            <p>This is a friendly reminder that your match is about to start.</p>
            <div style="background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
              <h3 style="margin-top: 0;">Match ID: ${widget.matchId}</h3>
              <p><strong>Don't forget to:</strong></p>
              <ul>
                <li>Check the lineup</li>
                <li>Arrive on time</li>
                <li>Bring your gear</li>
              </ul>
            </div>
            <p>Good luck and have a great game!</p>
            <p style="color: #666; font-size: 12px; margin-top: 30px;">
              This is an automated reminder from YourLeague.
            </p>
          </div>
        ''',
      );
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rappel envoyé à ${user.email}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur envoi rappel: $e')),
        );
      }
    }
  }

  Future<void> _openPushDialog() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Envoyer notification (Push)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Envoyer')),
        ],
      ),
    );
    if (send != true) return;
    if (titleController.text.trim().isEmpty || bodyController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Titre et message requis.')));
      }
      return;
    }
    try {
      final ok = await MatchPushService.sendMatchPush(
        matchId: widget.matchId,
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
      );
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification push envoyée.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur envoi push: $e')));
      }
    }
  }
}

class AddMatchEventDialog extends StatefulWidget {
  final String matchId;
  const AddMatchEventDialog({super.key, required this.matchId});

  @override
  State<AddMatchEventDialog> createState() => _AddMatchEventDialogDialogState();
}

class _AddMatchEventDialogDialogState extends State<AddMatchEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _minuteController = TextEditingController();
  final _playerNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'goal';

  @override
  void dispose() {
    _minuteController.dispose();
    _playerNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Match Event'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Event Type'),
                items: ['goal', 'yellow_card', 'red_card', 'substitution', 'fault', 'other']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.replaceAll('_', ' ').toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              TextFormField(
                controller: _minuteController,
                decoration: const InputDecoration(labelText: 'Minute'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Enter minute' : null,
              ),
              TextFormField(
                controller: _playerNameController,
                decoration: const InputDecoration(labelText: 'Player Name (Optional)'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
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
              context.read<MatchesCubit>().createMatchEvent(
                matchId: widget.matchId,
                type: _selectedType,
                playerName: _playerNameController.text.isEmpty ? null : _playerNameController.text,
                description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                minute: int.tryParse(_minuteController.text) ?? 0,
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

