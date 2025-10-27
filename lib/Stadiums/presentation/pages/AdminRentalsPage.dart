import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRentalsPage extends StatelessWidget {
  const AdminRentalsPage({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _updateStatus(BuildContext context, String docId, String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Status Change'),
        content: Text('Are you sure you want to change the status to "$newStatus"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('stadium_rentals')
            .doc(docId)
            .update({'status': newStatus});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to "$newStatus"')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rentals Management'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stadium_rentals')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No rentals found.'));
          }

          final rentals = snapshot.data!.docs;

          return ListView.builder(
            itemCount: rentals.length,
            itemBuilder: (context, index) {
              final doc = rentals[index];
              final data = doc.data() as Map<String, dynamic>;

              final stadiumName = data['stadiumName'] ?? 'Unknown Stadium';
              final status = data['status'] ?? 'pending';
              final hours = data['hours'] ?? 0;

              // ✅ FIXED DATE HANDLING — supports both Timestamp and String
              final dateField = data['date'];
              DateTime? dateTime;

              if (dateField is Timestamp) {
                dateTime = dateField.toDate();
              } else if (dateField is String) {
                dateTime = DateTime.tryParse(dateField);
              }

              String formattedDate = dateTime != null
                  ? '${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
                  : 'Unknown date';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(stadiumName),
                  subtitle: Text('Date: $formattedDate\nHours: $hours'),
                  trailing: PopupMenuButton<String>(
                    icon: Chip(
                      label: Text(
                        status.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: _getStatusColor(status),
                    ),
                    onSelected: (newStatus) =>
                        _updateStatus(context, doc.id, newStatus),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'confirmed', child: Text('Mark as Confirmed')),
                      const PopupMenuItem(value: 'cancelled', child: Text('Mark as Cancelled')),
                      const PopupMenuItem(value: 'pending', child: Text('Mark as Pending')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
