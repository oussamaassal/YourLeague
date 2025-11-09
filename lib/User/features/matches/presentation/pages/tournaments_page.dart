import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:yourleague/User/features/matches/presentation/pages/leaderboards_page.dart';
import 'package:yourleague/User/features/matches/presentation/pages/bracket_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yourleague/User/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:yourleague/common/widgets/map_picker_page.dart';
import 'package:yourleague/User/features/shop/data/cloudinary_service.dart';

class TournamentsPage extends StatefulWidget {
  const TournamentsPage({super.key});

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  Future<void> _addTournamentDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    ll.LatLng? pickedLatLng;
    String selectedType = 'football';
    File? logoFile; // NEW: picked file
    String? logoUrl; // NEW: uploaded Cloudinary URL
    bool uploadingLogo = false; // NEW: progress flag
    final cloudinary = CloudinaryService();
    final imagePicker = ImagePicker();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          String? dateError;
          if (startDate != null && endDate != null && endDate!.isBefore(startDate!)) {
            dateError = 'End date must be after start date';
          }
          return AlertDialog(
            title: const Text('Create Tournament'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description (optional)'),
                  ),
                  const SizedBox(height: 12),
                  // NEW: Logo selector using Cloudinary
                  Text('Logo', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: uploadingLogo ? null : () async {
                          try {
                            final XFile? picked = await imagePicker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1024,
                              maxHeight: 1024,
                              imageQuality: 85,
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                logoFile = File(picked.path);
                                uploadingLogo = true;
                              });
                              final url = await cloudinary.uploadImage(logoFile!);
                              setStateDialog(() {
                                logoUrl = url;
                                uploadingLogo = false;
                              });
                              if (url == null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Logo upload failed')),
                                );
                              }
                            }
                          } catch (e) {
                            setStateDialog(() { uploadingLogo = false; });
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: Text(logoUrl == null ? 'Pick logo' : 'Change logo'),
                      ),
                      if (uploadingLogo)
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      if (logoUrl != null && !uploadingLogo)
                        IconButton(
                          tooltip: 'Clear logo',
                          onPressed: () => setStateDialog(() {
                            logoFile = null;
                            logoUrl = null;
                          }),
                          icon: const Icon(Icons.close),
                        ),
                      const SizedBox(width: 8),
                      if (logoUrl != null && !uploadingLogo)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.network(
                            logoUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => CircleAvatar(
                              radius: 22,
                              child: Text(nameCtrl.text.isNotEmpty ? nameCtrl.text[0].toUpperCase() : '?'),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // NEW: Type selector
                  Text('Type', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    items: const [
                      DropdownMenuItem(value: 'football', child: Text('Football')),
                      DropdownMenuItem(value: 'volleyball', child: Text('Volleyball')),
                      DropdownMenuItem(value: 'pong pong', child: Text('Pong Pong')),
                      DropdownMenuItem(value: 'rugby', child: Text('Rugby')),
                      DropdownMenuItem(value: 'basketball', child: Text('Basketball')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setStateDialog(() => selectedType = v ?? 'football'),
                  ),
                  const SizedBox(height: 12),
                  Text('Dates', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              startDate = picked;
                              if (endDate != null && endDate!.isBefore(startDate!)) endDate = null; // reset invalid end
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(startDate == null
                            ? 'Start date'
                            : 'Start: ${DateFormat('yyyy-MM-dd').format(startDate!)}'),
                      ),
                      OutlinedButton.icon(
                        onPressed: startDate == null
                            ? null
                            : () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ?? (startDate ?? DateTime.now()).add(const Duration(days: 1)),
                                  firstDate: startDate!,
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setStateDialog(() => endDate = picked);
                                }
                              },
                        icon: const Icon(Icons.event),
                        label: Text(endDate == null
                            ? (startDate == null ? 'End date (pick start first)' : 'End date')
                            : 'End: ${DateFormat('yyyy-MM-dd').format(endDate!)}'),
                      ),
                      if (startDate != null || endDate != null)
                        IconButton(
                          tooltip: 'Clear dates',
                          onPressed: () => setStateDialog(() {
                            startDate = null;
                            endDate = null;
                          }),
                          icon: const Icon(Icons.clear),
                        ),
                    ],
                  ),
                  if (dateError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(dateError, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 16),
                  Text('Stadium Location', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                minimumSize: const Size(0, 44),
                              ),
                              onPressed: () async {
                                final sel = await Navigator.push<ll.LatLng>(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MapPickerPage()),
                                );
                                if (sel != null) {
                                  setStateDialog(() => pickedLatLng = sel);
                                }
                              },
                              icon: const Icon(Icons.map, size: 20),
                              label: Text(pickedLatLng == null ? 'Pick location' : 'Change location'),
                            ),
                          ),
                          if (pickedLatLng != null)
                            IconButton(
                              tooltip: 'Clear location',
                              onPressed: () => setStateDialog(() => pickedLatLng = null),
                              icon: const Icon(Icons.clear),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: pickedLatLng == null
                            ? Text('No location selected', key: const ValueKey('loc_none'), style: const TextStyle(color: Colors.grey))
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: Chip(
                                  key: const ValueKey('loc_chip'),
                                  avatar: const Icon(Icons.location_on, color: Colors.green),
                                  label: Text(
                                    '${pickedLatLng!.latitude.toStringAsFixed(5)}, ${pickedLatLng!.longitude.toStringAsFixed(5)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Create'),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty || uploadingLogo) return;
                  if (dateError != null) return;
                  final currentUid = context.read<AuthCubit>().currentUser?.uid;
                  if (currentUid == null) return;
                  final doc = fs.FirebaseFirestore.instance.collection('tournaments').doc();
                  final Map<String, dynamic> data = {
                    'name': name,
                    'description': descCtrl.text.trim(),
                    'status': 'inProgress',
                    'type': selectedType,
                    'organizer': fs.FirebaseFirestore.instance.collection('users').doc(currentUid),
                    'matches': <fs.DocumentReference>[],
                    'createdAt': fs.Timestamp.now(),
                  };
                  if (startDate != null) data['startDate'] = fs.Timestamp.fromDate(startDate!);
                  if (endDate != null) data['endDate'] = fs.Timestamp.fromDate(endDate!);
                  if (pickedLatLng != null) data['location'] = fs.GeoPoint(pickedLatLng!.latitude, pickedLatLng!.longitude);
                  if (logoUrl != null && logoUrl!.isNotEmpty) data['logoUrl'] = logoUrl;
                  await doc.set(data);
                  if (!mounted) return;
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteTournamentCascade(BuildContext context, String tournamentId) async {
    final firestore = fs.FirebaseFirestore.instance;

    // Blocking progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1) Delete match events per match, then matches
      final matchesSnap = await firestore
          .collection('matches')
          .where('tournamentId', isEqualTo: tournamentId)
          .get();

      for (final mDoc in matchesSnap.docs) {
        // Delete events for this match
        final eventsSnap = await firestore
            .collection('match_events')
            .where('matchId', isEqualTo: mDoc.id)
            .get();
        // Delete events in chunks
        final eventsDocs = eventsSnap.docs;
        for (var i = 0; i < eventsDocs.length; i += 400) {
          final batch = firestore.batch();
          final chunk = eventsDocs.skip(i).take(400);
          for (final e in chunk) {
            batch.delete(e.reference);
          }
          await batch.commit();
        }
      }
      // Delete matches in chunks
      final matchDocs = matchesSnap.docs;
      for (var i = 0; i < matchDocs.length; i += 400) {
        final batch = firestore.batch();
        final chunk = matchDocs.skip(i).take(400);
        for (final m in chunk) {
          batch.delete(m.reference);
        }
        await batch.commit();
      }

      // 2) Delete leaderboards
      final lbsSnap = await firestore
          .collection('leaderboards')
          .where('tournamentId', isEqualTo: tournamentId)
          .get();
      final lbDocs = lbsSnap.docs;
      for (var i = 0; i < lbDocs.length; i += 400) {
        final batch = firestore.batch();
        final chunk = lbDocs.skip(i).take(400);
        for (final lb in chunk) {
          batch.delete(lb.reference);
        }
        await batch.commit();
      }

      // 3) Finally delete the tournament document
      await firestore.collection('tournaments').doc(tournamentId).delete();

      if (mounted) {
        Navigator.of(context).pop(); // close progress
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // close progress
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete tournament: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteTournament(BuildContext context, String tournamentId, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete tournament?'),
        content: Text('This will delete "$title" and all its matches, events and leaderboards.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _deleteTournamentCascade(context, tournamentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy');
    final currentUid = context.read<AuthCubit>().currentUser?.uid; // for organizer check
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addTournamentDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<fs.QuerySnapshot<Map<String, dynamic>>>(
        stream: fs.FirebaseFirestore.instance
            .collection('tournaments')
            .orderBy('startDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No tournaments yet'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data();
              final name = (data['name'] as String?)?.trim();
              final title = (name != null && name.isNotEmpty) ? name : d.id;
              final organizerRef = data['organizer'];
              String? organizerUid;
              if (organizerRef is fs.DocumentReference) organizerUid = organizerRef.id;
              if (organizerRef is String) {
                final parts = organizerRef.split('/');
                organizerUid = parts.isNotEmpty ? parts.last : null;
              }
              final isOrganizer = organizerUid != null && organizerUid == currentUid;

              final status = (data['status'] as String?) ?? 'unknown';
              final tsStart = data['startDate'];
              final tsEnd = data['endDate'];
              final typeRaw = (data['type'] as String?)?.trim();
              String typeText = '';
              if (typeRaw != null && typeRaw.isNotEmpty) {
                typeText = typeRaw.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
              }
              String dateText = '';
              if (tsStart is fs.Timestamp) {
                final s = tsStart.toDate();
                final e = tsEnd is fs.Timestamp ? tsEnd.toDate() : null;
                dateText = e == null ? df.format(s) : '${df.format(s)} - ${df.format(e)}';
              }
              String locText = '';
              final geo = data['location'];
              if (geo is fs.GeoPoint) {
                locText = '(${geo.latitude.toStringAsFixed(3)}, ${geo.longitude.toStringAsFixed(3)})';
              }

              return Card(
                child: ListTile(
                  leading: _TournamentAvatar(
                    title: title,
                    logoUrl: (data['logoUrl'] as String?),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (typeText.isNotEmpty) Text('Type: $typeText'),
                      Text('Status: $status'),
                      if (dateText.isNotEmpty) Text('Dates: $dateText'),
                      if (locText.isNotEmpty) Text('Location: $locText'),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      if (isOrganizer)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDeleteTournament(context, d.id, title),
                        ),
                      IconButton(
                        icon: const Icon(Icons.account_tree),
                        tooltip: 'Bracket',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BracketPage(
                                tournamentId: d.id,
                                organizerUid: organizerUid,
                              ),
                            ),
                          );
                        },
                      ),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LeaderboardsPage(tournamentId: d.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Helper: avatar that shows logo or initial
class _TournamentAvatar extends StatelessWidget {
  final String title;
  final String? logoUrl;
  final Color color;
  const _TournamentAvatar({required this.title, required this.logoUrl, required this.color});
  @override
  Widget build(BuildContext context) {
    final double size = 44;
    final borderColor = Theme.of(context).dividerColor.withOpacity(0.4);
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceVariant, // visible background
          border: Border.all(color: borderColor, width: 0.75),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          logoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            // Fallback to initial if loading fails
            return Center(
              child: Text(
                title.isNotEmpty ? title[0].toUpperCase() : '#',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      );
    }
    return CircleAvatar(
      backgroundColor: color,
      child: Text(title.isNotEmpty ? title[0].toUpperCase() : '#', style: const TextStyle(color: Colors.white)),
    );
  }
}
