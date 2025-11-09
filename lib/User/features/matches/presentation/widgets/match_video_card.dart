import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MatchVideoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const MatchVideoCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? '') as String;
    final source = (data['source'] ?? '') as String;
    final url = source == 'youtube' ? (data['youtubeUrl'] ?? '') as String : (data['downloadUrl'] ?? '') as String;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(source == 'youtube' ? Icons.ondemand_video : Icons.play_circle_fill, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Cliquez pour ouvrir et lire'),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton.icon(
                onPressed: url.isEmpty
                    ? null
                    : () async {
                        final uri = Uri.parse(url);
                        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d’ouvrir la vidéo.')));
                        }
                      },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Lire'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}