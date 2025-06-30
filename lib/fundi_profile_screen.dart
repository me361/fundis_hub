import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class FundiProfileScreen extends StatelessWidget {
  final String fundiId;
  final String name;
  final bool available;
  final String phoneNumber;

  const FundiProfileScreen({
    super.key,
    required this.fundiId,
    required this.name,
    required this.available,
    required this.phoneNumber,
  });

  Future<void> _launchCall(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone app')),
      );
    }
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final Uri whatsappUri = Uri.parse("https://wa.me/$phoneNumber");
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Availability: ${available ? "Available" : "Busy"}'),
            Text('Phone: $phoneNumber'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.green),
                  onPressed: () => _launchCall(context),
                ),
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.green),
                  onPressed: () => _launchWhatsApp(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Ratings:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('fundis')
                    .doc(fundiId)
                    .collection('ratings')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  final reviews = snapshot.data?.docs ?? [];
                  if (reviews.isEmpty) {
                    return const Text('No reviews yet.');
                  }
                  return ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final data = reviews[index].data() as Map<String, dynamic>;
                      final user = data['user'] ?? 'Anonymous';
                      final rating = data['rating'] ?? 0;
                      final comment = data['comment'] ?? '';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text('⭐ $rating - $user'),
                          subtitle: Text(comment),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentScreen(
                  fundiName: name,
                  totalAmount: 1000, // You can later make this dynamic
                ),
              ),
            );
          },
          child: const Text('Pay via M-Pesa'),
        ),
      ),
    );
  }
}
