import 'package:flutter/material.dart';
import 'package:yourleague/User/features/matches/services/match_video_service.dart';

class AddMatchVideoLinkDialog extends StatefulWidget {
  final String matchId;
  const AddMatchVideoLinkDialog({super.key, required this.matchId});

  @override
  State<AddMatchVideoLinkDialog> createState() => _AddMatchVideoLinkDialogState();
}

class _AddMatchVideoLinkDialogState extends State<AddMatchVideoLinkDialog> {
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _saving = false;

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com/') || url.contains('youtu.be/');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une vidéo (YouTube)'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(labelText: 'Lien YouTube'),
            ),
            const SizedBox(height: 8),
            const Text('Ex: https://youtu.be/xxxx ou https://www.youtube.com/watch?v=xxxx'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  final title = _titleCtrl.text.trim();
                  final url = _urlCtrl.text.trim();
                  if (title.isEmpty || url.isEmpty || !_isYouTubeUrl(url)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez saisir un titre et un lien YouTube valide.')),
                    );
                    return;
                  }
                  setState(() => _saving = true);
                  try {
                    await MatchVideoService.addYouTubeVideo(matchId: widget.matchId, title: title, url: url);
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Ajouter'),
        ),
      ],
    );
  }
}