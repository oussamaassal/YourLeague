import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final void Function(LatLng location) onLocationPicked;

  const MapLocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationPicked,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final String mapTilerKey = 'ZfU0cdEoyRLyxX6gNxeA';
  LatLng? selectedLocation;
  late final MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 400,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: selectedLocation ?? const LatLng(36.8065, 10.1815),
                initialZoom: 13.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    selectedLocation = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key={key}',
                  additionalOptions: {'key': mapTilerKey},
                ),
                if (selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: selectedLocation == null
                      ? null
                      : () {
                          widget.onLocationPicked(selectedLocation!);
                          Navigator.of(context).pop();
                        },
                  child: const Text('Confirm Location'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}