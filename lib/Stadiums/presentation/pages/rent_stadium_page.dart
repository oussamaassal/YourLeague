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
import 'stadium_details_page.dart';

class RentStadiumPage extends StatefulWidget {
  const RentStadiumPage({super.key});

  @override
  State<RentStadiumPage> createState() => _RentStadiumPageState();
}

class _RentStadiumPageState extends State<RentStadiumPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOrder = 'none'; // 'none', 'priceLowToHigh', 'priceHighToLow', 'capacity'
  String? _selectedCity;
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    // Load all stadiums when page opens
    context.read<StadiumCubit>().getAllStadiums();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Stadium> _filterAndSortStadiums(List<Stadium> stadiums) {
    // Filter by search query
    List<Stadium> filtered = stadiums.where((stadium) {
      final searchLower = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          stadium.name.toLowerCase().contains(searchLower) ||
          stadium.city.toLowerCase().contains(searchLower) ||
          stadium.address.toLowerCase().contains(searchLower);
      
      final matchesCity = _selectedCity == null || stadium.city == _selectedCity;
      
      final matchesPrice = (_minPrice == null || stadium.pricePerHour >= _minPrice!) &&
          (_maxPrice == null || stadium.pricePerHour <= _maxPrice!);

      return matchesSearch && matchesCity && matchesPrice;
    }).toList();

    // Sort stadiums
    switch (_sortOrder) {
      case 'priceLowToHigh':
        filtered.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
        break;
      case 'priceHighToLow':
        filtered.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
        break;
      case 'capacity':
        filtered.sort((a, b) => b.capacity.compareTo(a.capacity));
        break;
      default:
        // Keep original order (newest first)
        break;
    }

    return filtered;
  }

  List<String> _getCities(List<Stadium> stadiums) {
    final cities = stadiums.map((s) => s.city).toSet().toList();
    cities.sort();
    return cities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Stadiums'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Sort Bar
          _buildSearchAndSortBar(),
          // Stadiums List
          Expanded(child: _buildStadiumsList()),
        ],
      ),
    );
  }

  Widget _buildSearchAndSortBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, city, address...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 8),
          // Sort Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip('none', 'Newest'),
                const SizedBox(width: 8),
                _buildSortChip('priceLowToHigh', 'Price: Low to High'),
                const SizedBox(width: 8),
                _buildSortChip('priceHighToLow', 'Price: High to Low'),
                const SizedBox(width: 8),
                _buildSortChip('capacity', 'Capacity'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String value, String label) {
    final isSelected = _sortOrder == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _sortOrder = selected ? value : 'none';
        });
      },
    );
  }

  Widget _buildStadiumsList() {
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

          final filteredAndSorted = _filterAndSortStadiums(state.stadiums);

          if (filteredAndSorted.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No stadiums found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredAndSorted.length,
            itemBuilder: (context, index) {
              final stadium = filteredAndSorted[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StadiumDetailsPage(stadium: stadium),
                    ),
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
                      '${stadium.city} • ${stadium.address}\nPrice: \$${stadium.pricePerHour.toStringAsFixed(2)} / hr • Capacity: ${stadium.capacity}',
                    ),
                    isThreeLine: true,
                    trailing: ElevatedButton(
                      onPressed: () => _showRentSheet(context, stadium),
                      child: const Text('Rent'),
                    ),
                  ),
                ),
              );
            },
          );
        }

        return const Center(child: Text('No stadiums available.'));
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    final stadiumState = context.read<StadiumCubit>().state;
    final cities = stadiumState is StadiumsLoaded 
        ? _getCities(stadiumState.stadiums) 
        : <String>[];
    
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        selectedCity: _selectedCity,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        cities: cities,
        onApply: (city, minPrice, maxPrice) {
          setState(() {
            _selectedCity = city;
            _minPrice = minPrice;
            _maxPrice = maxPrice;
          });
          Navigator.pop(context);
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

// Filter Dialog Widget
class _FilterDialog extends StatefulWidget {
  final String? selectedCity;
  final double? minPrice;
  final double? maxPrice;
  final List<String> cities;
  final Function(String?, double?, double?) onApply;

  const _FilterDialog({
    required this.selectedCity,
    required this.minPrice,
    required this.maxPrice,
    required this.cities,
    required this.onApply,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late String? _selectedCity;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.selectedCity;
    _minPriceController = TextEditingController(
      text: widget.minPrice?.toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.maxPrice?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Stadiums'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.cities.isNotEmpty) ...[
              const Text('City:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _selectedCity,
                isExpanded: true,
                hint: const Text('All Cities'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Cities'),
                  ),
                  ...widget.cities.map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            const Text('Price Range:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Min Price',
                      hintText: '0',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('-'),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Max Price',
                      hintText: '1000',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedCity = null;
              _minPriceController.clear();
              _maxPriceController.clear();
            });
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final minPrice = _minPriceController.text.isEmpty
                ? null
                : double.tryParse(_minPriceController.text);
            final maxPrice = _maxPriceController.text.isEmpty
                ? null
                : double.tryParse(_maxPriceController.text);
            widget.onApply(_selectedCity, minPrice, maxPrice);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
