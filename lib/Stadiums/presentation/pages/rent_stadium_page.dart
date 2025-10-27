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

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _hours = 1;
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _rentStadium(DocumentSnapshot stadium) async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final rentalDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    setState(() => _isLoading = true);
    try {
      await rentalsRef.add({
        'stadiumId': stadium.id,
        'stadiumName': stadium['name'],
        'rentalDateTime': Timestamp.fromDate(rentalDateTime),
        'hours': _hours,
        'createdAt': Timestamp.now(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stadium "${stadium['name']}" rented!')),
      );

      // Reset after rental
      setState(() {
        _selectedDate = null;
        _selectedTime = null;
        _hours = 1;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to rent stadium: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rent a Stadium')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: stadiumsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No stadiums available'));
          }

          final stadiums = snapshot.data!.docs;

          return ListView.builder(
            itemCount: stadiums.length,
            itemBuilder: (context, index) {
              final stadium = stadiums[index];
              final name = stadium['name'] ?? '';
              final city = stadium['city'] ?? '';
              final address = stadium['address'] ?? '';
              final price = stadium['pricePerHour'] ?? 0.0;
              final imageUrl = stadium['imageUrl'] ?? '';

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, width: 80, fit: BoxFit.cover)
                      : const Icon(Icons.sports_soccer, size: 50),
                  title: Text(name),
                  subtitle: Text(
                      '$city • $address\nPrice: \$${price.toString()} per hour'),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    child: const Text('Rent'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Rent $name'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: _pickDate,
                                child: Text(_selectedDate == null
                                    ? 'Pick Date'
                                    : DateFormat('yyyy-MM-dd')
                                    .format(_selectedDate!)),
                              ),
                              TextButton(
                                onPressed: _pickTime,
                                child: Text(_selectedTime == null
                                    ? 'Pick Time'
                                    : _selectedTime!.format(context)),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Hours:'),
                                  DropdownButton<int>(
                                    value: _hours,
                                    items: List.generate(8, (i) => i + 1)
                                        .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text('$e ${e > 1 ? 'hours' : 'hour'}'),
                                    ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _hours = val);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _rentStadium(stadium);
                                Navigator.pop(context);
                              },
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                    },
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
