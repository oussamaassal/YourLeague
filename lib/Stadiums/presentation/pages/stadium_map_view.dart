import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final LatLng stadiumLocation = LatLng(widget.latitude, widget.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: stadiumLocation,
              zoom: 15.0,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('stadium'),
                position: stadiumLocation,
                infoWindow: InfoWindow(
                  title: widget.stadiumName,
                  snippet: 'Tap to open in Maps',
                  onTap: () => _openInMaps(),
                ),
              ),
            },
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            mapType: MapType.normal,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            onTap: (_) => _openInMaps(),
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
      'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

