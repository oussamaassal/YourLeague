import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:yourleague/User/features/matches/services/match_video_service.dart';

class AddMatchVideoUploadDialog extends StatefulWidget {
  final String matchId;
  const AddMatchVideoUploadDialog({super.key, required this.matchId});

  @override
  State<AddMatchVideoUploadDialog> createState() => _AddMatchVideoUploadDialogState();
}

class _AddMatchVideoUploadDialogState extends State<AddMatchVideoUploadDialog> {
  final _titleCtrl = TextEditingController();
  bool _uploading = false;
  PlatformFile? _file;

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    if (res != null && res.files.isNotEmpty) {
      setState(() => _file = res.files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Uploader une vidéo'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _uploading ? null : _pickFile,
                  icon: const Icon(Icons.video_file),
                  label: const Text('Choisir le fichier'),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(_file?.name ?? 'Aucun fichier sélectionné')),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Formats supportés via navigateur (web): mp4, webm, etc.'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _uploading ? null : () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _uploading
              ? null
              : () async {
                  final title = _titleCtrl.text.trim();
                  if (title.isEmpty || _file?.bytes == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez saisir un titre et choisir un fichier vidéo.')),
                    );
                    return;
                  }
                  setState(() => _uploading = true);
                  try {
                    await MatchVideoService.uploadVideoBytes(
                      matchId: widget.matchId,
                      title: title,
                      bytes: _file!.bytes as Uint8List,
                      filename: _file!.name,
                      contentType: _file!.extension != null ? 'video/${_file!.extension}' : 'video/mp4',
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur upload: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _uploading = false);
                  }
                },
          child: _uploading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Uploader'),
        ),
      ],
    );
  }
}