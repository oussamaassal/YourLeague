import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_cubit.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_states.dart';
import 'package:yourleague/User/features/matches/domain/entities/match_event.dart';

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
        title: Text('Match Events - ${widget.matchId.substring(0, 8)}...'),
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
            if (state.events.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No events found for this match',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add events to track goals, cards, and more',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
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

