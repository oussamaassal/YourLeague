import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/firebase_teams_repo.dart';

class QrScanJoinPage extends StatefulWidget {
  const QrScanJoinPage({super.key});

  @override
  State<QrScanJoinPage> createState() => _QrScanJoinPageState();
}

class _QrScanJoinPageState extends State<QrScanJoinPage> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  final _repo = FirebaseTeamsRepo();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePayload(String raw) async {
    if (_handled) return;
    _handled = true;

    try {
      // Expecting yl://team/<teamId>
      final prefix = 'yl://team/';
      if (!raw.startsWith(prefix)) {
        throw Exception('Invalid QR format');
      }
      final teamId = raw.substring(prefix.length);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not signed in');

      // Join logic:
      // - If team is Public -> add as member immediately
      // - If team is Private -> create join_request
      await _repo.joinViaQuickPath(teamId: teamId, userId: uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request sent (or joined if public).')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scan failed: $e')),
      );
      // Allow retry
      _handled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR to Join')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;
              _handlePayload(raw);
            },
          ),
          // simple overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Align the QR within the frame',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
