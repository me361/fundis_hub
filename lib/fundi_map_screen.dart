import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FundiMapScreen extends StatefulWidget {
  @override
  _FundiMapScreenState createState() => _FundiMapScreenState();
}

class _FundiMapScreenState extends State<FundiMapScreen> {
  GoogleMapController? mapController;
  final LatLng _center = const LatLng(-1.2921, 36.8219); // Example: Nairobi

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadFundis();
  }

  Future<void> _loadFundis() async {
    final snapshot = await FirebaseFirestore.instance.collection('fundis').get();
    final markers = snapshot.docs.map((doc) {
      final data = doc.data();
      final lat = data['latitude'];
      final lng = data['longitude'];
      if (lat == null || lng == null) return null;
      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: data['name'] ?? 'Fundi',
          snippet: data['service'] ?? '',
          onTap: () {
            // You can navigate to booking/contact here
          },
        ),
      );
    }).whereType<Marker>().toSet();

    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fundis Map')),
      body: GoogleMap(
        onMapCreated: (controller) => mapController = controller,
        initialCameraPosition: CameraPosition(target: _center, zoom: 12),
        markers: _markers,
      ),
    );
  }
} 