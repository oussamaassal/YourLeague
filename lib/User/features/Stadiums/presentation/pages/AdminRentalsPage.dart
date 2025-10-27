import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminRentalsPage extends StatefulWidget {
  const AdminRentalsPage({super.key});

  @override
  State<AdminRentalsPage> createState() => _AdminRentalsPageState();
}

class _AdminRentalsPageState extends State<AdminRentalsPage> {
  final rentalsRef = FirebaseFirestore.instance.collection('stadium_rentals');

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stadium Rentals')),
      body: StreamBuilder<QuerySnapshot>(
        stream: rentalsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No rentals yet.'));
          }

          final rentals = snapshot.data!.docs;

          return ListView.builder(
            itemCount: rentals.length,
            itemBuilder: (context, index) {
              final rental = rentals[index];
              final data = rental.data() as Map<String, dynamic>;

              final timestamp = data['rentalDateTime'] as Timestamp?;
              final formattedDate = timestamp != null
                  ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
                  : '-';

              final status = data['status'] ?? '-';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(data['stadiumName'] ?? 'Unknown Stadium'),
                  subtitle: Text(
                      'Date: $formattedDate\nHours: ${data['hours']?.toString() ?? '-'}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Change status?'),
                          content: Text('Change status to $value?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('No')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Yes')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await rentalsRef.doc(rental.id).update({'status': value});
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update status: $e')),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'pending', child: Text('Pending')),
                      PopupMenuItem(value: 'confirmed', child: Text('Confirmed')),
                      PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
                    ],
                    child: Chip(
                      label: Text(status),
                      backgroundColor: _getStatusColor(status),
                    ),
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
