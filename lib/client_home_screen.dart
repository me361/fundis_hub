import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'fundi_map_screen.dart';
import 'auth_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'fundi_profile_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ClientHomeScreen extends StatefulWidget {
  @override
  _ClientHomeScreenState createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  String searchQuery = '';
  String filterService = '';
  String filterAvailability = '';
  double filterRating = 0;
  String role = 'client';
  String specializationFilter = '';
  List<String> specializations = [];
  Position? clientPosition;

  @override
  void initState() {
    super.initState();
    getUserRole();
    fetchSpecializations();
    insertDummyFundisIfNeeded();
    getClientLocation();
  }

  void getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        role = doc['role'] ?? 'client';
      });
    }
  }

  void fetchSpecializations() async {
    final query = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'fundi').get();
    final specs = query.docs
        .map((doc) => doc.data()?['specialization'] ?? '')
        .where((s) => s != null && s.toString().isNotEmpty)
        .toSet()
        .toList();
    setState(() {
      specializations = specs.cast<String>();
    });
  }

  void getClientLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        clientPosition = pos;
      });
    } catch (e) {
      // ignore location errors for now
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FC),
      appBar: AppBar(
        title: const Text('Nearby Fundis'),
        backgroundColor: Colors.teal,
        titleTextStyle: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.map),
            tooltip: 'View Map',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FundiMapScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text(
                'Fundis Hub',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.map),
              title: Text('Map'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FundiMapScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => AuthScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Welcome $role',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[800]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Search by name or specialization'),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: specializationFilter.isEmpty ? null : specializationFilter,
                  hint: const Text('Filter by specialization'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('All')),
                    ...specializations.map((spec) => DropdownMenuItem(value: spec, child: Text(spec))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      specializationFilter = value ?? '';
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'fundi').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toLowerCase();
                  final specialization = (data['specialization'] ?? '').toLowerCase();
                  return (searchQuery.isEmpty ||
                          name.contains(searchQuery.toLowerCase()) ||
                          specialization.contains(searchQuery.toLowerCase())) &&
                        (specializationFilter.isEmpty || specialization == specializationFilter.toLowerCase());
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No fundis found.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final fundiId = docs[index].id;
                    final fundiLat = data['lat'] ?? -1.286389;
                    final fundiLng = data['lng'] ?? 36.817223;
                    double? distanceKm;
                    if (clientPosition != null) {
                      distanceKm = Geolocator.distanceBetween(
                        clientPosition!.latitude,
                        clientPosition!.longitude,
                        fundiLat,
                        fundiLng,
                      ) / 1000.0;
                    }
                    return Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FundiProfileScreen(
                                fundiId: fundiId,
                                name: data['name'] ?? 'Unknown',
                                available: true,
                                phoneNumber: data['phone'] ?? '',
                                specialization: data['specialization'] ?? '',
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.teal[100],
                                radius: 32,
                                child: Icon(Icons.account_circle, color: Colors.teal[700], size: 40),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'] ?? 'Unknown',
                                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal[900]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Specialization: ${data['specialization'] ?? 'N/A'}',
                                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.teal[700]),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Phone: ${data['phone'] ?? 'N/A'}',
                                      style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[800]),
                                    ),
                                    if (distanceKm != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Text(
                                          'Approx. ${distanceKm.toStringAsFixed(2)} km away',
                                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.teal[700]),
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          icon: Icon(Icons.phone, color: Colors.white, size: 20),
                                          label: Text('Call'),
                                          onPressed: () async {
                                            final phone = data['phone'] ?? '';
                                            if (phone.isNotEmpty) {
                                              final uri = Uri.parse('tel:$phone');
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(uri);
                                              }
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          icon: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 20),
                                          label: Text('WhatsApp'),
                                          onPressed: () async {
                                            final phone = data['phone'] ?? '';
                                            if (phone.isNotEmpty) {
                                              final uri = Uri.parse('https://wa.me/$phone');
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(uri);
                                              }
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                          onPressed: () async {
                                            try {
                                              final user = FirebaseAuth.instance.currentUser;
                                              if (user == null) throw Exception('Not logged in');
                                              final clientDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                                              final clientName = clientDoc.data()?['name'] ?? user.email ?? 'Client';
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(fundiId)
                                                  .collection('bookings')
                                                  .add({
                                                'clientId': user.uid,
                                                'clientName': clientName,
                                                'date': DateTime.now().toIso8601String(),
                                                'status': 'pending',
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Booking request sent!')),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error: ' + e.toString())),
                                              );
                                            }
                                          },
                                          child: const Text('Book'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: 'Insert Demo Fundis',
        backgroundColor: Colors.teal,
        onPressed: () async {
          try {
            await insertDummyFundisIfNeeded(force: true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Demo fundis inserted!')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ' + e.toString())),
            );
          }
        },
      ),
    );
  }

  Future<void> insertDummyFundisIfNeeded({bool force = false}) async {
    final query = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'fundi').get();
    if (force || query.docs.isEmpty) {
      final dummyFundis = [
        {
          'email': 'plumber1@demo.com',
          'role': 'fundi',
          'specialization': 'Plumber',
          'phone': '0711000001',
          'name': 'Plumber One',
          'lat': -1.285,
          'lng': 36.82,
        },
        {
          'email': 'electrician1@demo.com',
          'role': 'fundi',
          'specialization': 'Electrician',
          'phone': '0711000002',
          'name': 'Electrician One',
          'lat': -1.29,
          'lng': 36.81,
        },
        {
          'email': 'carpenter1@demo.com',
          'role': 'fundi',
          'specialization': 'Carpenter',
          'phone': '0711000003',
          'name': 'Carpenter One',
          'lat': -1.28,
          'lng': 36.815,
        },
        {
          'email': 'painter1@demo.com',
          'role': 'fundi',
          'specialization': 'Painter',
          'phone': '0711000004',
          'name': 'Painter One',
          'lat': -1.287,
          'lng': 36.818,
        },
      ];
      for (final fundi in dummyFundis) {
        final docRef = FirebaseFirestore.instance.collection('users').doc();
        await docRef.set(fundi);
      }
      setState(() {}); // Refresh UI
    }
  }
} 