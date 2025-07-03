import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FundiDashboard extends StatefulWidget {
  const FundiDashboard({Key? key}) : super(key: key);

  @override
  State<FundiDashboard> createState() => _FundiDashboardState();
}

class _FundiDashboardState extends State<FundiDashboard> {
  bool isAvailable = false;
  String role = 'fundi';
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    getAvailabilityStatus();
    getUserRole();
  }

  void getAvailabilityStatus() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('fundis').doc(user!.uid).get();
    if (doc.exists) {
      setState(() {
        isAvailable = doc['available'] ?? false;
      });
    }
  }

  void getUserRole() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      setState(() {
        role = doc['role'] ?? 'fundi';
      });
    }
  }

  void toggleAvailability(bool value) async {
    if (user == null) return;
    await FirebaseFirestore.instance.collection('fundis').doc(user!.uid).update({
      'available': value,
    });
    setState(() {
      isAvailable = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String fundiUid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Fundi Dashboard')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text(
                'Fundis Hub',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Welcome $role', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Row(
            children: [
              const Text('Available:'),
              Switch(
                value: isAvailable,
                onChanged: toggleAvailability,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Bookings:', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(fundiUid)
                  .collection('bookings')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final bookings = snapshot.data?.docs ?? [];
                if (bookings.isEmpty) {
                  return const Center(child: Text('No bookings yet.'));
                }
                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final doc = bookings[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(data['clientName'] ?? data['clientId'] ?? 'Unknown Client'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${data['date'] ?? 'N/A'}\nStatus: ${data['status'] ?? 'pending'}'),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    doc.reference.update({'status': 'deposit_paid'});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Deposit paid (simulated)')),
                                    );
                                  },
                                  child: const Text('Pay Deposit'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    doc.reference.update({'status': 'balance_paid'});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Balance paid (simulated)')),
                                    );
                                  },
                                  child: const Text('Pay Balance'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                doc.reference.update({'status': 'accepted'});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                doc.reference.update({'status': 'rejected'});
                              },
                            ),
                          ],
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
    );
  }
}
