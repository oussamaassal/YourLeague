import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/stadium.dart';
import '../../domain/entities/stadium_rental.dart';
import '../cubits/rental_cubit.dart';
import '../cubits/rental_states.dart';
import '../../../../User/features/auth/presentation/cubits/auth_cubit.dart';

class BookingCalendarPage extends StatefulWidget {
  final Stadium stadium;

  const BookingCalendarPage({super.key, required this.stadium});

  @override
  State<BookingCalendarPage> createState() => _BookingCalendarPageState();
}

class _BookingCalendarPageState extends State<BookingCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<StadiumRental>> _rentalsByDate = {};
  List<StadiumRental> _selectedRentals = [];

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  void _loadRentals() {
    context.read<RentalCubit>().getRentalsByStadium(widget.stadium.id);
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<StadiumRental> _getRentalsForDay(DateTime day) {
    return _rentalsByDate.entries
        .where((entry) => _isSameDay(entry.key, day))
        .expand((entry) => entry.value)
        .where((rental) =>
            rental.status == 'pending' || rental.status == 'confirmed')
        .toList();
  }

  bool _isDayBooked(DateTime day) {
    final rentals = _getRentalsForDay(day);
    return rentals.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.stadium.name} - Booking Calendar'),
      ),
      body: BlocConsumer<RentalCubit, RentalState>(
        listener: (context, state) {
          if (state is RentalsLoaded) {
            // Organize rentals by date
            final Map<DateTime, List<StadiumRental>> rentalsMap = {};
            for (final rental in state.rentals) {
              final date = DateTime(
                rental.rentalStartDate.year,
                rental.rentalStartDate.month,
                rental.rentalStartDate.day,
              );
              rentalsMap[date] ??= [];
              rentalsMap[date]!.add(rental);
            }
            setState(() {
              _rentalsByDate = rentalsMap;
              _selectedRentals = _getRentalsForDay(_selectedDay);
            });
          }
        },
        builder: (context, state) {
          if (state is RentalLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Calendar
              TableCalendar<StadiumRental>(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => _isSameDay(day, _selectedDay),
                eventLoader: _getRentalsForDay,
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedRentals = _getRentalsForDay(selectedDay);
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const Divider(),
              // Selected Day Rentals
              Expanded(
                child: _selectedRentals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No bookings on ${DateFormat('MMM d, y').format(_selectedDay)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This day is available',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _selectedRentals.length,
                        itemBuilder: (context, index) {
                          final rental = _selectedRentals[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(
                                _isDayBooked(_selectedDay)
                                    ? Icons.event_busy
                                    : Icons.event_available,
                                color: rental.status == 'confirmed'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              title: Text(
                                '${DateFormat('HH:mm').format(rental.rentalStartDate)} - ${DateFormat('HH:mm').format(rental.rentalEndDate)}',
                              ),
                              subtitle: Text(
                                '${rental.hours} hour${rental.hours > 1 ? 's' : ''} • Status: ${rental.status}',
                              ),
                              trailing: Chip(
                                label: Text(
                                  rental.status.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: rental.status == 'confirmed'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

