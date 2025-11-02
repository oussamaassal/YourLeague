import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RentStadiumPage extends StatefulWidget {
  const RentStadiumPage({super.key});

  @override
  State<RentStadiumPage> createState() => _RentStadiumPageState();
}

class _RentStadiumPageState extends State<RentStadiumPage> {
  final CollectionReference stadiumsRef =
  FirebaseFirestore.instance.collection('stadiums');
  final CollectionReference rentalsRef =
  FirebaseFirestore.instance.collection('stadium_rentals');

  bool _isLoading = false;

  Future<bool> _hasConflict(String stadiumId, DateTime start, DateTime end) async {
    final snapshot = await rentalsRef
        .where('stadiumId', isEqualTo: stadiumId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['rentalDateTime'];
      if (ts is! Timestamp) continue;
      final existingStart = ts.toDate();
      final hours = (data['hours'] as int?) ?? 1;
      final existingEnd = existingStart.add(Duration(hours: hours));
      final overlap = start.isBefore(existingEnd) && end.isAfter(existingStart);
      if (overlap) return true;
    }
    return false;
  }

  Future<void> _createRental(DocumentSnapshot stadium, DateTime start, int hours) async {
    setState(() => _isLoading = true);
    try {
      await rentalsRef.add({
        'stadiumId': stadium.id,
        'stadiumName': stadium['name'],
        'rentalDateTime': Timestamp.fromDate(start),
        'hours': hours,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stadium "${stadium['name']}" rented successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to rent stadium: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Stadiums')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: stadiumsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No stadiums available.'));
          }

          final stadiums = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: stadiums.length,
            itemBuilder: (context, index) {
              final stadium = stadiums[index];
              final name = stadium['name'] ?? '';
              final city = stadium['city'] ?? '';
              final address = stadium['address'] ?? '';
              final price = (stadium['pricePerHour'] ?? 0.0) as num;
              final imageUrl = stadium['imageUrl'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: imageUrl.isNotEmpty
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
                  subtitle: Text('$city • $address\nPrice: \$${price.toString()} / hr'),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: () => _showRentSheet(context, stadium, price.toDouble()),
                    child: const Text('Rent'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRentSheet(BuildContext context, DocumentSnapshot stadium, double pricePerHour) {
    showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        DateTime? localDate;
        TimeOfDay? localTime;
        int localHours = 1;
        bool submitting = false;
        String? errorText;

        return StatefulBuilder(builder: (context, setState) {
          final now = DateTime.now();
          DateTime? start;
          DateTime? end;
          if (localDate != null && localTime != null) {
            start = DateTime(
              localDate!.year,
              localDate!.month,
              localDate!.day,
              localTime!.hour,
              localTime!.minute,
            );
            end = start.add(Duration(hours: localHours));
          }

          final total = (pricePerHour * localHours);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Rent ${stadium['name']}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => localDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(localDate == null
                      ? 'Pick Date'
                      : DateFormat('yyyy-MM-dd').format(localDate!)),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => localTime = picked);
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(localTime == null
                      ? 'Pick Time'
                      : localTime!.format(context)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Hours:'),
                    DropdownButton<int>(
                      value: localHours,
                      items: List.generate(8, (i) => i + 1)
                          .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text('$e ${e > 1 ? 'hours' : 'hour'}'),
                      ))
                          .toList(),
                      onChanged: submitting
                          ? null
                          : (val) {
                        if (val != null) setState(() => localHours = val);
                      },
                    ),
                  ],
                ),
                if (start != null) ...[
                  const SizedBox(height: 8),
                  Text('Start: ${DateFormat('yMMMd • HH:mm').format(start)}'),
                  Text('End:   ${DateFormat('yMMMd • HH:mm').format(end!)}'),
                  Text('Total: \$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(errorText!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                    if (localDate == null || localTime == null) {
                      setState(() => errorText = 'Please select date and time');
                      return;
                    }
                    final proposedStart = DateTime(
                      localDate!.year,
                      localDate!.month,
                      localDate!.day,
                      localTime!.hour,
                      localTime!.minute,
                    );
                    if (proposedStart.isBefore(now)) {
                      setState(() => errorText = 'Selected time must be in the future');
                      return;
                    }
                    final proposedEnd = proposedStart.add(Duration(hours: localHours));

                    setState(() {
                      submitting = true;
                      errorText = null;
                    });

                    final hasConflict = await _hasConflict(
                        stadium.id, proposedStart, proposedEnd);
                    if (hasConflict) {
                      setState(() {
                        submitting = false;
                        errorText = 'This time overlaps with an existing booking.';
                      });
                      return;
                    }

                    await _createRental(stadium, proposedStart, localHours);
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  child: submitting
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Confirm Booking'),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
