import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/stadium.dart';
import '../../domain/entities/stadium_rental.dart';
import '../cubits/stadium_cubit.dart';
import '../cubits/stadium_states.dart';
import '../cubits/rental_cubit.dart';
import '../cubits/rental_states.dart';
import '../../../../User/features/auth/presentation/cubits/auth_cubit.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MyRentalsPage extends StatefulWidget {
  const MyRentalsPage({super.key});

  @override
  State<MyRentalsPage> createState() => _MyRentalsPageState();
}

class _MyRentalsPageState extends State<MyRentalsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    final authCubit = context.read<AuthCubit>();
    final currentUser = authCubit.currentUser;
    if (currentUser != null) {
      context.read<StadiumCubit>().getStadiumsByUser(currentUser.uid);
      context.read<RentalCubit>().getRentalsByRenter(currentUser.uid);
    }
  }

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
class _OfferedStadiumsTab extends StatelessWidget {
  const _OfferedStadiumsTab();

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final currentUser = authCubit.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Please log in to view your stadiums'));
    }

    return BlocBuilder<StadiumCubit, StadiumState>(
      builder: (context, state) {
        if (state is StadiumLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is StadiumError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${state.message}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<StadiumCubit>().getStadiumsByUser(currentUser.uid),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is StadiumsLoaded) {
          if (state.stadiums.isEmpty) {
            return const Center(child: Text('You have not offered any stadiums yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.stadiums.length,
            itemBuilder: (context, index) {
              final stadium = state.stadiums[index];
              return Dismissible(
                key: ValueKey(stadium.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white, size: 28),
                ),
                confirmDismiss: (_) async {
                  await _deleteStadium(context, stadium);
                  return false;
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    onLongPress: () => _deleteStadium(context, stadium),
                    leading: stadium.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              stadium.imageUrl, // Using getter for first image
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.stadium_outlined, size: 40),
                            ),
                          )
                        : const Icon(Icons.stadium_outlined, size: 40),
                    title: Text(stadium.name),
                    subtitle: Text('${stadium.city}\nPrice: \$${stadium.pricePerHour.toStringAsFixed(2)} / hr'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                          tooltip: 'Edit',
                          onPressed: () => _editStadium(context, stadium),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Delete',
                          onPressed: () => _deleteStadium(context, stadium),
                        ),
                        IconButton(
                          icon: const Icon(Icons.list_alt_outlined, color: Colors.green),
                          tooltip: 'View Rentals',
                          onPressed: () => _viewRentals(context, stadium.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }

        return const Center(child: Text('You have not offered any stadiums yet.'));
      },
    );
  }

  Future<void> _deleteStadium(BuildContext context, Stadium stadium) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stadium'),
        content: const Text('Are you sure you want to permanently delete this stadium?'),
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
      // Delete image from Firebase Storage if exists
      try {
        await FirebaseStorage.instance.ref('stadiums/${stadium.id}/cover.jpg').delete();
      } catch (_) {}

      context.read<StadiumCubit>().deleteStadium(stadium.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete stadium: $e')),
      );
    }
  }

  Future<void> _editStadium(BuildContext context, Stadium stadium) async {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: stadium.name);
    final cityController = TextEditingController(text: stadium.city);
    final addressController = TextEditingController(text: stadium.address);
    final priceController = TextEditingController(text: stadium.pricePerHour.toString());
    final capacityController = TextEditingController(text: stadium.capacity.toString());
    String selectedType = stadium.type;
    File? imageFile;
    bool saving = false;

    // Cloudinary credentials
    const String cloudName = 'dcqs7fphe';
    const String uploadPreset = 'YourLeague';

    Future<String> _uploadToCloudinary(File imageFile) async {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(resBody);
        return data['secure_url'];
      } else {
        throw Exception('Cloudinary upload failed: ${response.statusCode}');
      }
    }

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
            return BlocConsumer<StadiumCubit, StadiumState>(
              listener: (context, state) {
                if (state is StadiumOperationSuccess) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                } else if (state is StadiumError) {
                  setState(() => saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is StadiumLoading;
                if (isLoading && saving) {
                  return const Center(child: CircularProgressIndicator());
                }

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
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: 'Stadium Name'),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Enter name' : null,
                          ),
                          DropdownButtonFormField<String>(
                            value: selectedType,
                            decoration: const InputDecoration(labelText: 'Stadium Type'),
                            items: ['football', 'volleyball', 'handball', 'basketball']
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type.substring(0, 1).toUpperCase() + type.substring(1)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedType = value;
                                });
                              }
                            },
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
                            controller: capacityController,
                            decoration: const InputDecoration(labelText: 'Capacity'),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter capacity';
                              final c = int.tryParse(v);
                              if (c == null || c <= 0) return 'Invalid capacity';
                              return null;
                            },
                          ),
                          TextFormField(
                            controller: priceController,
                            decoration: const InputDecoration(labelText: 'Price per hour'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter price';
                              final p = double.tryParse(v);
                              if (p == null || p <= 0) return 'Invalid price';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          imageFile != null
                              ? Image.file(imageFile!, height: 120)
                              : (stadium.imageUrls.isNotEmpty
                                  ? Image.network(stadium.imageUrl, // Using getter
                                      height: 120, fit: BoxFit.cover)
                                  : const Icon(Icons.image_outlined, size: 60)),
                          TextButton.icon(
                            icon: const Icon(Icons.image),
                            label: const Text('Change Image'),
                            onPressed: () async {
                              final picked =
                                  await ImagePicker().pickImage(source: ImageSource.gallery);
                              if (picked != null) {
                                setState(() => imageFile = File(picked.path));
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: saving || isLoading
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate()) return;
                                    setState(() => saving = true);

                                    try {
                                      List<String> imageUrls = List.from(stadium.imageUrls);
                                      if (imageFile != null) {
                                        final newImageUrl = await _uploadToCloudinary(imageFile!);
                                        // Replace first image or add if empty
                                        if (imageUrls.isEmpty) {
                                          imageUrls.add(newImageUrl);
                                        } else {
                                          imageUrls[0] = newImageUrl;
                                        }
                                      }

                                      final updatedStadium = Stadium(
                                        id: stadium.id,
                                        name: nameController.text.trim(),
                                        city: cityController.text.trim(),
                                        address: addressController.text.trim(),
                                        type: selectedType,
                                        capacity: int.parse(capacityController.text.trim()),
                                        pricePerHour: double.parse(priceController.text.trim()),
                                        imageUrls: imageUrls,
                                        userId: stadium.userId,
                                        latitude: stadium.latitude,
                                        longitude: stadium.longitude,
                                        phoneNumber: stadium.phoneNumber,
                                        description: stadium.description,
                                        createdAt: stadium.createdAt,
                                      );

                                      context.read<StadiumCubit>().updateStadium(updatedStadium);
                                    } catch (e) {
                                      setState(() => saving = false);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  },
                            child: saving || isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2))
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
      },
    );
  }

  void _viewRentals(BuildContext context, String stadiumId) {
    showModalBottomSheet(
      isScrollControlled: false,
      showDragHandle: true,
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return BlocProvider.value(
          value: context.read<RentalCubit>(),
          child: _RentalsListView(stadiumId: stadiumId),
        );
      },
    );
  }
}

class _RentalsListView extends StatelessWidget {
  final String stadiumId;

  const _RentalsListView({required this.stadiumId});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<List<StadiumRental>>(
                  stream: context.read<RentalCubit>().watchRentalsByStadium(stadiumId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No rentals found for this stadium.'),
                      );
                    }

                    final rentals = snapshot.data!;

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: rentals.length,
                      itemBuilder: (context, index) {
                        final rental = rentals[index];
                        final formatted = DateFormat('yMMMd • HH:mm')
                            .format(rental.rentalStartDate);

                        Color color;
                        switch (rental.status) {
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
                            subtitle: Text('Hours: ${rental.hours}'),
                            trailing: PopupMenuButton<String>(
                              icon: Chip(
                                label: Text(
                                  rental.status.toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: color,
                              ),
                              onSelected: (newStatus) async {
                                context
                                    .read<RentalCubit>()
                                    .updateRentalStatus(rental.id, newStatus);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Status updated to $newStatus')),
                                );
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'pending', child: Text('Mark as Pending')),
                                PopupMenuItem(
                                    value: 'confirmed', child: Text('Mark as Confirmed')),
                                PopupMenuItem(
                                    value: 'cancelled', child: Text('Mark as Cancelled')),
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
  }
}

// ===============================================================
// BOOKED STADIUMS TAB
// ===============================================================
class _BookedStadiumsTab extends StatelessWidget {
  const _BookedStadiumsTab();

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final currentUser = authCubit.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Please log in to view your bookings'));
    }

    return BlocBuilder<RentalCubit, RentalState>(
      builder: (context, state) {
        if (state is RentalLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is RentalError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${state.message}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<RentalCubit>().getRentalsByRenter(currentUser.uid),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is RentalsLoaded) {
          if (state.rentals.isEmpty) {
            return const Center(child: Text('You haven\'t booked any stadiums yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.rentals.length,
            itemBuilder: (context, index) {
              final rental = state.rentals[index];
              final formattedDate = DateFormat('yMMMd • HH:mm').format(rental.rentalStartDate);

              Color color;
              switch (rental.status) {
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: Icon(Icons.sports_soccer, color: color, size: 40),
                  title: Text(rental.stadiumName),
                  subtitle: Text(
                      '$formattedDate\nHours: ${rental.hours}\nStatus: ${rental.status}'),
                ),
              );
            },
          );
        }

        return const Center(child: Text('You haven\'t booked any stadiums yet.'));
      },
    );
  }
}
