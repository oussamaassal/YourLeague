import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/stadium_rental.dart';
import '../cubits/rental_cubit.dart';
import '../cubits/rental_states.dart';

class AdminRentalsPage extends StatelessWidget {
  const AdminRentalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Load all rentals when page opens
    context.read<RentalCubit>().getAllRentals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rentals Management'),
      ),
      body: BlocConsumer<RentalCubit, RentalState>(
        listener: (context, state) {
          if (state is RentalOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is RentalError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
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
                    onPressed: () => context.read<RentalCubit>().getAllRentals(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is RentalsLoaded) {
            if (state.rentals.isEmpty) {
              return const Center(child: Text('No rentals found.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.rentals.length,
              itemBuilder: (context, index) {
                final rental = state.rentals[index];
                final formattedDate = DateFormat('dd/MM/yyyy • HH:mm')
                    .format(rental.rentalStartDate);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(rental.stadiumName),
                    subtitle: Text('Date: $formattedDate\nHours: ${rental.hours}'),
                    trailing: PopupMenuButton<String>(
                      icon: Chip(
                        label: Text(
                          rental.status.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _getStatusColor(rental.status),
                      ),
                      onSelected: (newStatus) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Status Change'),
                            content:
                                Text('Are you sure you want to change the status to "$newStatus"?'),
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
                          context.read<RentalCubit>().updateRentalStatus(rental.id, newStatus);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'confirmed', child: Text('Mark as Confirmed')),
                        const PopupMenuItem(value: 'cancelled', child: Text('Mark as Cancelled')),
                        const PopupMenuItem(value: 'pending', child: Text('Mark as Pending')),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          // Use stream as fallback for real-time updates
          return StreamBuilder<List<StadiumRental>>(
            stream: context.read<RentalCubit>().watchAllRentals(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No rentals found.'));
              }

              final rentals = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: rentals.length,
                itemBuilder: (context, index) {
                  final rental = rentals[index];
                  final formattedDate = DateFormat('dd/MM/yyyy • HH:mm')
                      .format(rental.rentalStartDate);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(rental.stadiumName),
                      subtitle: Text('Date: $formattedDate\nHours: ${rental.hours}'),
                      trailing: PopupMenuButton<String>(
                        icon: Chip(
                          label: Text(
                            rental.status.toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _getStatusColor(rental.status),
                        ),
                        onSelected: (newStatus) async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Status Change'),
                              content: Text(
                                  'Are you sure you want to change the status to "$newStatus"?'),
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
                            context.read<RentalCubit>().updateRentalStatus(rental.id, newStatus);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'confirmed', child: Text('Mark as Confirmed')),
                          const PopupMenuItem(
                              value: 'cancelled', child: Text('Mark as Cancelled')),
                          const PopupMenuItem(value: 'pending', child: Text('Mark as Pending')),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

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
}
