import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/stadium.dart';
import '../../domain/entities/stadium_rental.dart';
import '../cubits/stadium_cubit.dart';
import '../cubits/stadium_states.dart';
import '../cubits/rental_cubit.dart';
import '../cubits/rental_states.dart';
import '../../../../User/features/auth/presentation/cubits/auth_cubit.dart';

class RentStadiumPage extends StatefulWidget {
  const RentStadiumPage({super.key});

  @override
  State<RentStadiumPage> createState() => _RentStadiumPageState();
}

class _RentStadiumPageState extends State<RentStadiumPage> {
  @override
  void initState() {
    super.initState();
    // Load all stadiums when page opens
    context.read<StadiumCubit>().getAllStadiums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Stadiums')),
      body: BlocBuilder<StadiumCubit, StadiumState>(
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
                    onPressed: () => context.read<StadiumCubit>().getAllStadiums(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is StadiumsLoaded) {
            if (state.stadiums.isEmpty) {
              return const Center(child: Text('No stadiums available.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.stadiums.length,
              itemBuilder: (context, index) {
                final stadium = state.stadiums[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: stadium.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              stadium.imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.stadium_outlined, size: 40),
                            ),
                          )
                        : const Icon(Icons.stadium_outlined, size: 40),
                    title: Text(stadium.name),
                    subtitle: Text(
                      '${stadium.city} • ${stadium.address}\nPrice: \$${stadium.pricePerHour.toStringAsFixed(2)} / hr',
                    ),
                    isThreeLine: true,
                    trailing: ElevatedButton(
                      onPressed: () => _showRentSheet(context, stadium),
                      child: const Text('Rent'),
                    ),
                  ),
                );
              },
            );
          }

          return const Center(child: Text('No stadiums available.'));
        },
      ),
    );
  }

  void _showRentSheet(BuildContext context, Stadium stadium) {
    showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return BlocProvider.value(
          value: context.read<RentalCubit>(),
          child: _RentSheetContent(stadium: stadium),
        );
      },
    );
  }
}

class _RentSheetContent extends StatefulWidget {
  final Stadium stadium;

  const _RentSheetContent({required this.stadium});

  @override
  State<_RentSheetContent> createState() => _RentSheetContentState();
}

class _RentSheetContentState extends State<_RentSheetContent> {
  DateTime? localDate;
  TimeOfDay? localTime;
  int localHours = 1;
  String? errorText;

  @override
  Widget build(BuildContext context) {
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

    final total = widget.stadium.pricePerHour * localHours;

    return BlocConsumer<RentalCubit, RentalState>(
      listener: (context, state) {
        if (state is RentalOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.pop(context);
        } else if (state is RentalConflictDetected) {
          setState(() => errorText = state.message);
        } else if (state is RentalError) {
          setState(() => errorText = state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is RentalLoading;

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
              Text(
                'Rent ${widget.stadium.name}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            localDate = picked;
                            errorText = null;
                          });
                        }
                      },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(localDate == null
                    ? 'Pick Date'
                    : DateFormat('yyyy-MM-dd').format(localDate!)),
              ),
              TextButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            localTime = picked;
                            errorText = null;
                          });
                        }
                      },
                icon: const Icon(Icons.access_time),
                label: Text(localTime == null ? 'Pick Time' : localTime!.format(context)),
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
                    onChanged: isLoading
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() {
                                localHours = val;
                                errorText = null;
                              });
                            }
                          },
                  ),
                ],
              ),
              if (start != null) ...[
                const SizedBox(height: 8),
                Text('Start: ${DateFormat('yMMMd • HH:mm').format(start)}'),
                Text('End:   ${DateFormat('yMMMd • HH:mm').format(end!)}'),
                Text(
                  'Total: \$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(errorText!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isLoading
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

                        final authCubit = context.read<AuthCubit>();
                        final currentUser = authCubit.currentUser;

                        context.read<RentalCubit>().createRental(
                              stadiumId: widget.stadium.id,
                              stadiumName: widget.stadium.name,
                              rentalDateTime: proposedStart,
                              hours: localHours,
                              renterId: currentUser?.uid,
                              ownerId: widget.stadium.userId,
                            );
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Confirm Booking'),
              ),
            ],
          ),
        );
      },
    );
  }
}
