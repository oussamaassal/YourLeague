import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class MyRentalsPage extends StatefulWidget {
  const MyRentalsPage({super.key});

  @override
  State<MyRentalsPage> createState() => _MyRentalsPageState();
}

class _MyRentalsPageState extends State<MyRentalsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
  TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rentals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Offered'),
            Tab(text: 'Booked'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OfferedStadiumsTab(),
          _BookedStadiumsTab(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ===============================================================
// OFFERED STADIUMS TAB (Edit + Delete + View Rentals)
// ===============================================================
class _OfferedStadiumsTab extends StatefulWidget {
  const _OfferedStadiumsTab();

  @override
  State<_OfferedStadiumsTab> createState() => _OfferedStadiumsTabState();
}

class _OfferedStadiumsTabState extends State<_OfferedStadiumsTab> {
  final _stadiumsRef = FirebaseFirestore.instance.collection('stadiums');
  final _storage = FirebaseStorage.instance;

  Future<void> _deleteStadium(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stadium'),
        content: const Text(
            'Are you sure you want to permanently delete this stadium?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _stadiumsRef.doc(id).delete();
      try {
        await _storage.ref('stadiums/$id/cover.jpg').delete();
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stadium deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete stadium: $e')),
      );
    }
  }

  Future<void> _editStadium(
      BuildContext context, String id, Map<String, dynamic> data) async {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: data['name']);
    final cityController = TextEditingController(text: data['city']);
    final addressController = TextEditingController(text: data['address']);
    final priceController =
    TextEditingController(text: data['pricePerHour'].toString());
    File? imageFile;
    bool saving = false;

    await showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Edit Stadium',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration:
                        const InputDecoration(labelText: 'Stadium Name'),
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter name' : null,
                      ),
                      TextFormField(
                        controller: cityController,
                        decoration: const InputDecoration(labelText: 'City'),
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter city' : null,
                      ),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter address'
                            : null,
                      ),
                      TextFormField(
                        controller: priceController,
                        decoration:
                        const InputDecoration(labelText: 'Price per hour'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter price';
                          }
                          final p = double.tryParse(v);
                          if (p == null || p <= 0) return 'Invalid price';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      imageFile != null
                          ? Image.file(imageFile!, height: 120)
                          : (data['imageUrl'] != ''
                          ? Image.network(data['imageUrl'],
                          height: 120, fit: BoxFit.cover)
                          : const Icon(Icons.image_outlined, size: 60)),
                      TextButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Change Image'),
                        onPressed: () async {
                          final picked = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            setState(() => imageFile = File(picked.path));
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => saving = true);

                          try {
                            String newImageUrl = data['imageUrl'];
                            if (imageFile != null) {
                              final ref = _storage
                                  .ref()
                                  .child('stadiums/$id/cover.jpg');
                              await ref.putFile(
                                  imageFile!,
                                  SettableMetadata(
                                      contentType: 'image/jpeg'));
                              newImageUrl = await ref.getDownloadURL();
                            }

                            await _stadiumsRef.doc(id).update({
                              'name': nameController.text.trim(),
                              'city': cityController.text.trim(),
                              'address': addressController.text.trim(),
                              'pricePerHour':
                              double.parse(priceController.text.trim()),
                              'imageUrl': newImageUrl,
                            });

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                  Text('Stadium updated successfully.')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          } finally {
                            setState(() => saving = false);
                          }
                        },
                        child: saving
                            ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                            CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _viewRentals(BuildContext context, String stadiumId) async {
    await showModalBottomSheet(
      isScrollControlled: false,
      showDragHandle: true,
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final rentalsRef = FirebaseFirestore.instance
            .collection('stadium_rentals')
            .where('stadiumId', isEqualTo: stadiumId)
            .orderBy('createdAt', descending: true);

        QuerySnapshot? cachedSnapshot;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                // ---- Header Bar ----
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Rentals',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                const Divider(thickness: 1),

                // ---- Rentals List ----
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: rentalsRef.snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting &&
                            cachedSnapshot == null) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasData) {
                          cachedSnapshot = snapshot.data;
                        }

                        final dataToShow = cachedSnapshot;
                        if (dataToShow == null || dataToShow.docs.isEmpty) {
                          return const Center(
                            child: Text('No rentals found for this stadium.'),
                          );
                        }

                        final rentals = dataToShow.docs;

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: rentals.length,
                          itemBuilder: (context, index) {
                            final doc = rentals[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final id = doc.id;
                            final status = data['status'] ?? 'pending';
                            final hours = data['hours'] ?? 0;
                            final ts = data['rentalDateTime'] as Timestamp?;
                            final date = ts?.toDate();
                            final formatted = date != null
                                ? DateFormat('yMMMd • HH:mm').format(date)
                                : 'Unknown date';

                            Color color;
                            switch (status) {
                              case 'confirmed':
                                color = Colors.green;
                                break;
                              case 'cancelled':
                                color = Colors.red;
                                break;
                              default:
                                color = Colors.orange;
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 1,
                              child: ListTile(
                                title: Text('Date: $formatted'),
                                subtitle: Text('Hours: $hours'),
                                trailing: PopupMenuButton<String>(
                                  icon: Chip(
                                    label: Text(
                                      status.toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: color,
                                  ),
                                  onSelected: (newStatus) async {
                                    await FirebaseFirestore.instance
                                        .collection('stadium_rentals')
                                        .doc(id)
                                        .update({'status': newStatus});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Status updated to $newStatus')),
                                    );
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'pending',
                                      child: Text('Mark as Pending'),
                                    ),
                                    PopupMenuItem(
                                      value: 'confirmed',
                                      child: Text('Mark as Confirmed'),
                                    ),
                                    PopupMenuItem(
                                      value: 'cancelled',
                                      child: Text('Mark as Cancelled'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stadiumsRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('You have not offered any stadiums yet.'));
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id;
            final name = data['name'] ?? 'Unknown';
            final city = data['city'] ?? '';
            final price = data['pricePerHour'] ?? 0;
            final imageUrl = data['imageUrl'] ?? '';

            return Dismissible(
              key: ValueKey(id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white, size: 28),
              ),
              confirmDismiss: (_) async {
                await _deleteStadium(context, id);
                return false;
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  onLongPress: () => _deleteStadium(context, id),
                  leading: imageUrl != ''
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Icon(Icons.stadium_outlined, size: 40),
                  title: Text(name),
                  subtitle: Text('$city\nPrice: \$${price.toString()} / hr'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                        const Icon(Icons.edit_outlined, color: Colors.blue),
                        tooltip: 'Edit',
                        onPressed: () => _editStadium(context, id, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        tooltip: 'Delete',
                        onPressed: () => _deleteStadium(context, id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.list_alt_outlined,
                            color: Colors.green),
                        tooltip: 'View Rentals',
                        onPressed: () => _viewRentals(context, id),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ===============================================================
// BOOKED STADIUMS TAB
// ===============================================================
class _BookedStadiumsTab extends StatelessWidget {
  const _BookedStadiumsTab();

  @override
  Widget build(BuildContext context) {
    final rentalsRef = FirebaseFirestore.instance.collection('stadium_rentals');

    return StreamBuilder<QuerySnapshot>(
      stream: rentalsRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('You haven’t booked any stadiums yet.'));
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data['stadiumName'] ?? 'Unknown';
            final hours = data['hours'] ?? 1;
            final status = data['status'] ?? 'pending';
            final ts = data['rentalDateTime'] as Timestamp?;
            final date = ts?.toDate();
            final formattedDate = date != null
                ? DateFormat('yMMMd • HH:mm').format(date)
                : 'Unknown date';

            Color color;
            switch (status) {
              case 'confirmed':
                color = Colors.green;
                break;
              case 'cancelled':
                color = Colors.red;
                break;
              default:
                color = Colors.orange;
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: Icon(Icons.sports_soccer, color: color, size: 40),
                title: Text(name),
                subtitle:
                Text('$formattedDate\nHours: $hours\nStatus: $status'),
              ),
            );
          },
        );
      },
    );
  }
}
