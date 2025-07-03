import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FundiProfileScreen extends StatelessWidget {
  final String fundiId;
  final String name;
  final bool available;
  final String phoneNumber;
  final String? specialization;

  const FundiProfileScreen({
    super.key,
    required this.fundiId,
    required this.name,
    required this.available,
    required this.phoneNumber,
    this.specialization,
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
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.teal[100],
                        child: Icon(Icons.account_circle, color: Colors.teal[700], size: 60),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      if (specialization != null && specialization!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            specialization!,
                            style: const TextStyle(fontSize: 16, color: Colors.teal),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            available ? Icons.check_circle : Icons.cancel,
                            color: available ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            available ? 'Available' : 'Busy',
                            style: TextStyle(
                              color: available ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Phone: $phoneNumber', style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            icon: const Icon(Icons.call, color: Colors.white, size: 20),
                            label: const Text('Call'),
                            onPressed: () => _launchCall(context),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 20),
                            label: const Text('WhatsApp'),
                            onPressed: () => _launchWhatsApp(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Ratings & Reviews:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('fundis')
                    .doc(fundiId)
                    .collection('ratings')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: [31m${snapshot.error}[0m');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
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
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal[50],
                            child: Text('⭐ $rating', style: const TextStyle(fontSize: 16)),
                          ),
                          title: Text(user, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
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
