import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/stadium.dart';
import '../cubits/stadium_cubit.dart';
import '../cubits/stadium_states.dart';
import '../cubits/rental_cubit.dart';
import 'booking_calendar_page.dart';
import 'stadium_map_view.dart';

class StadiumDetailsPage extends StatelessWidget {
  final Stadium stadium;

  const StadiumDetailsPage({super.key, required this.stadium});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(stadium.name),
              background: stadium.imageUrl.isNotEmpty
                  ? Image.network(
                      stadium.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.stadium_outlined, size: 100),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.stadium_outlined, size: 100),
                    ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info
                  _buildInfoSection(
                    context,
                    'Location',
                    '${stadium.city}, ${stadium.address}',
                    Icons.location_on,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Price',
                          '\$${stadium.pricePerHour.toStringAsFixed(2)}',
                          '/hour',
                          Icons.attach_money,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          'Capacity',
                          stadium.capacity.toString(),
                          'people',
                          Icons.people,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  if (stadium.description != null && stadium.description!.isNotEmpty)
                    _buildSection(
                      context,
                      'Description',
                      Text(stadium.description!),
                    ),
                  
                  // Contact Info
                  if (stadium.phoneNumber != null && stadium.phoneNumber!.isNotEmpty)
                    _buildSection(
                      context,
                      'Contact',
                      Row(
                        children: [
                          Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(stadium.phoneNumber!),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.call),
                            onPressed: () async {
                              final uri = Uri.parse('tel:${stadium.phoneNumber}');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  
                  // Map View
                  if (stadium.latitude != null && stadium.longitude != null)
                    _buildSection(
                      context,
                      'Location Map',
                      SizedBox(
                        height: 200,
                        child: StadiumMapView(
                          latitude: stadium.latitude!,
                          longitude: stadium.longitude!,
                          stadiumName: stadium.name,
                        ),
                      ),
                    ),
                  
                  // Images Gallery
                  if (stadium.imageUrls.length > 1)
                    _buildSection(
                      context,
                      'More Images',
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: stadium.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  stadium.imageUrls[index],
                                  width: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 150,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingCalendarPage(
                                  stadium: stadium,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('View Calendar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showBookingSheet(context, stadium),
                          icon: const Icon(Icons.book_online),
                          label: const Text('Book Now'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        content,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoSection(
      BuildContext context, String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, String unit, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$title $unit',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingSheet(BuildContext context, Stadium stadium) {
    // This will reuse the booking sheet from rent_stadium_page
    // For now, navigate to calendar page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingCalendarPage(stadium: stadium),
      ),
    );
  }
}

