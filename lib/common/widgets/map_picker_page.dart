import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Simple OpenStreetMap picker page.
/// Returns a LatLng via Navigator.pop when user hits confirm.
class MapPickerPage extends StatefulWidget {
  // Stade Olympique de Radès, Tunisia
  static const LatLng radesStadium = LatLng(36.7440, 10.2730);
  final LatLng initialCenter;
  const MapPickerPage({super.key, this.initialCenter = radesStadium});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? _picked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick stadium location')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: widget.initialCenter,
          initialZoom: 14, // closer view around the stadium
          onTap: (tapPos, latLng) => setState(() => _picked = latLng),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.yourleague.app',
          ),
          if (_picked != null)
            MarkerLayer(markers: [
              Marker(
                point: _picked!,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_on, color: Colors.red, size: 36),
              )
            ]),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                '© OpenStreetMap contributors',
                onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _picked == null ? null : () => Navigator.pop(context, _picked),
            icon: const Icon(Icons.check),
            label: Text(_picked == null
                ? 'Tap map to choose'
                : 'Use this location (${_picked!.latitude.toStringAsFixed(5)}, ${_picked!.longitude.toStringAsFixed(5)})'),
          ),
        ),
      ),
    );
  }
}
