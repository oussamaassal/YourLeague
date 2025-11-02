import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TeamQrPage extends StatelessWidget {
  final String teamId;
  const TeamQrPage({super.key, required this.teamId});

  // QR payload format — keep it simple and app-specific
  // Example content: yl://team/<teamId>
  String get _payload => 'yl://team/$teamId';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Team QR')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: _payload,
              version: QrVersions.auto,
              size: 240,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'Scan to join this team',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _payload,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
