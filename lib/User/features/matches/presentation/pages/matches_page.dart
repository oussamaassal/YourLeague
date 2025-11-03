import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_cubit.dart';
import 'package:yourleague/User/features/matches/presentation/cubits/matches_states.dart';
import 'package:yourleague/User/features/matches/domain/entities/match.dart';
import 'package:yourleague/User/features/matches/presentation/pages/match_events_page.dart';
import 'package:intl/intl.dart';
import 'package:yourleague/User/services/notification_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchesCubit>().getAllMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddMatchDialog(),
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
            context.read<MatchesCubit>().getAllMatches();
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

          if (state is MatchesLoaded) {
            if (state.matches.isEmpty) {
              return const Center(
                child: Text('No matches found'),
              );
            }

            return ListView.builder(
              itemCount: state.matches.length,
              itemBuilder: (context, index) {
                final match = state.matches[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(match.status[0].toUpperCase()),
                    ),
                    title: Text('${match.team1Name} vs ${match.team2Name}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Score: ${match.score1} - ${match.score2}'),
                        Text('Status: ${match.status}'),
                        Text('Date: ${DateFormat('MMM dd, yyyy HH:mm').format(match.matchDate.toDate())}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_active),
                          tooltip: 'Rappel 15 min avant',
                          onPressed: () async {
                            final int notifId = match.id.hashCode & 0x7fffffff;
                            final success = await NotificationService.instance.scheduleMatchReminder(
                              matchDateTime: match.matchDate.toDate(),
                              notificationId: notifId,
                              matchId: match.id,
                              matchTitle: '${match.team1Name} vs ${match.team2Name}',
                              title: 'Rappel de match',
                              reminderMinutes: 15,
                            );
                            if (!context.mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Rappel programmé 15 min avant le match')),
                              );
                            } else {
                              final msg = kIsWeb
                                  ? 'Les rappels locaux ne sont pas disponibles sur le web dans cette build.'
                                  : 'Rappel non programmé (match trop proche ou passé).';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.event_note),
                          tooltip: 'Match Events',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MatchEventsPage(matchId: match.id),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => EditMatchDialog(match: match),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            context.read<MatchesCubit>().deleteMatch(match.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const Center(child: Text('No data'));
        },
      ),
    );
  }
}

class AddMatchDialog extends StatefulWidget {
  const AddMatchDialog({super.key});

  @override
  State<AddMatchDialog> createState() => _AddMatchDialogState();
}

class _AddMatchDialogState extends State<AddMatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tournamentIdController = TextEditingController();
  final _team1IdController = TextEditingController();
  final _team1NameController = TextEditingController();
  final _team2IdController = TextEditingController();
  final _team2NameController = TextEditingController();
  final _refereeIdController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _tournamentIdController.dispose();
    _team1IdController.dispose();
    _team1NameController.dispose();
    _team2IdController.dispose();
    _team2NameController.dispose();
    _refereeIdController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Match'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tournamentIdController,
                decoration: const InputDecoration(labelText: 'Tournament ID'),
                validator: (value) => value?.isEmpty ?? true ? 'Enter tournament ID' : null,
              ),
              TextFormField(
                controller: _team1NameController,
                decoration: const InputDecoration(labelText: 'Team 1 Name'),
                validator: (value) => value?.isEmpty ?? true ? 'Enter team name' : null,
              ),
              TextFormField(
                controller: _team2NameController,
                decoration: const InputDecoration(labelText: 'Team 2 Name'),
                validator: (value) => value?.isEmpty ?? true ? 'Enter team name' : null,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => _selectDate(context),
                child: Text('Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}'),
              ),
              TextButton(
                onPressed: () => _selectTime(context),
                child: Text('Time: ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location (Optional)'),
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
              final combinedDateTime = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              );
              context.read<MatchesCubit>().createMatch(
                tournamentId: _tournamentIdController.text,
                team1Id: 'team1_${DateTime.now().millisecondsSinceEpoch}',
                team1Name: _team1NameController.text,
                team2Id: 'team2_${DateTime.now().millisecondsSinceEpoch}',
                team2Name: _team2NameController.text,
                location: _locationController.text.isEmpty ? null : _locationController.text,
                matchDate: combinedDateTime,
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

class EditMatchDialog extends StatefulWidget {
  final Match match;
  const EditMatchDialog({super.key, required this.match});

  @override
  State<EditMatchDialog> createState() => _EditMatchDialogState();
}

class _EditMatchDialogState extends State<EditMatchDialog> {
  late final _score1Controller = TextEditingController(text: widget.match.score1.toString());
  late final _score2Controller = TextEditingController(text: widget.match.score2.toString());
  late String _selectedStatus = widget.match.status;

  @override
  void dispose() {
    _score1Controller.dispose();
    _score2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Match'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(labelText: 'Status'),
            items: ['scheduled', 'ongoing', 'completed', 'cancelled']
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
          TextFormField(
            controller: _score1Controller,
            decoration: const InputDecoration(labelText: 'Team 1 Score'),
            keyboardType: TextInputType.number,
          ),
          TextFormField(
            controller: _score2Controller,
            decoration: const InputDecoration(labelText: 'Team 2 Score'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedMatch = Match(
              id: widget.match.id,
              tournamentId: widget.match.tournamentId,
              team1Id: widget.match.team1Id,
              team1Name: widget.match.team1Name,
              team2Id: widget.match.team2Id,
              team2Name: widget.match.team2Name,
              score1: int.tryParse(_score1Controller.text) ?? widget.match.score1,
              score2: int.tryParse(_score2Controller.text) ?? widget.match.score2,
              status: _selectedStatus,
              matchDate: widget.match.matchDate,
              createdAt: widget.match.createdAt,
            );
            context.read<MatchesCubit>().updateMatch(updatedMatch);
            Navigator.pop(context);
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

