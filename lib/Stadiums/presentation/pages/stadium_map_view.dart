import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class StadiumMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String stadiumName;

  const StadiumMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.stadiumName,
  });

  @override
  State<StadiumMapView> createState() => _StadiumMapViewState();
}

class _StadiumMapViewState extends State<StadiumMapView> {
  // Replace with your MapTiler API key
  final String mapTilerKey = 'ZfU0cdEoyRLyxX6gNxeA';

  @override
  Widget build(BuildContext context) {
    final LatLng stadiumLocation = LatLng(widget.latitude, widget.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: stadiumLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key={key}',
                additionalOptions: {
                  'key': mapTilerKey,
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: stadiumLocation,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: _openInMaps,
                      child: Column(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 30),
                          Text(
                            widget.stadiumName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: FloatingActionButton.small(
              onPressed: _openInMaps,
              tooltip: 'Open in Maps',
              child: const Icon(Icons.directions),
            ),
          ),
        ],
      ),
    );
  }

  void _openInMaps() async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${widget.latitude}&mlon=${widget.longitude}&zoom=15',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

