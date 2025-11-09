import 'package:flutter/material.dart';
import 'poll_service.dart';

class CreatePollDialog extends StatefulWidget {
  final String matchId;
  const CreatePollDialog({super.key, required this.matchId});

  @override
  State<CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends State<CreatePollDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _optionsController = TextEditingController();
  bool _allowMultiple = false;
  int? _closesInMinutes;

  @override
  void dispose() {
    _titleController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Poll'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Question / Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _optionsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Options (one per line)',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter at least one option';
                  final lines = v.split('\n').where((l) => l.trim().isNotEmpty).toList();
                  if (lines.length < 2) return 'Enter at least two options';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Allow multiple options'),
                value: _allowMultiple,
                onChanged: (v) => setState(() => _allowMultiple = v),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Closes in (minutes, optional)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _closesInMinutes = int.tryParse(v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final title = _titleController.text.trim();
            final options = _optionsController.text
                .split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();

            DateTime? closesAt;
            if (_closesInMinutes != null && _closesInMinutes! > 0) {
              closesAt = DateTime.now().add(Duration(minutes: _closesInMinutes!));
            }

            await PollService.createPoll(
              matchId: widget.matchId,
              title: title,
              options: options,
              allowMultiple: _allowMultiple,
              closesAt: closesAt,
            );

            Navigator.pop(context);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
