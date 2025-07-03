import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'fundi_profile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'fundi_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final User? user = FirebaseAuth.instance.currentUser;

  void _showConfirmation(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Payment Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  void _showReviewDialog(BuildContext context, String fundiId) {
    final TextEditingController commentController = TextEditingController();
    double rating = 3;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Rate this Fundi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(labelText: 'Write a comment'),
                ),
                const SizedBox(height: 10),
                Text('Rating: [4m${rating.toInt()}[0m'),
                Slider(
                  min: 1,
                  max: 5,
                  divisions: 4,
                  value: rating,
                  label: rating.toString(),
                  onChanged: (value) {
                    setState(() {
                      rating = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  await FirebaseFirestore.instance
                      .collection('fundis')
                      .doc(fundiId)
                      .collection('reviews')
                      .add({
                    'rating': rating.toInt(),
                    'comment': commentController.text,
                    'user': user.email,
                    'timestamp': Timestamp.now(),
                  });

                  Navigator.pop(context);
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fundis Hub'),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.email ?? 'Guest'}!',
              style: const TextStyle(
                fontSize: 18,
                color:Colors.black,
                ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/fundi');
              },
              child: const Text('Go to Fundi Dashboard'),
            ),
            const SizedBox(height: 20),

            const Text(
              'Nearby Fundis:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('fundis').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No fundis available at the moment.'),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final fundi = docs[index].data() as Map<String, dynamic>;
                      final name = fundi['name'] ?? 'Unknown';
                      final distance = fundi['distance'] ?? 'Unknown';
                      final available = fundi['available'] ?? false;
                      final phone = fundi['phone'] ?? '';
                      final whatsapp = fundi['whatsapp'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FundiProfileScreen(
                                  fundiId: docs[index].id,
                                  name: name,
                                  available: available,
                                  phoneNumber: fundi['phone'] ?? '',
                                ),
                              ),
                            );
                          },
                          leading: Icon(
                            Icons.build,
                            color: available ? Colors.green : Colors.grey,
                          ),
                          title: Text(name),
                          subtitle: Text('Distance: $distance'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: available ? Colors.green : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              available ? 'Available' : 'Busy',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
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
      ),
    );
  }
}
