import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FundiProfilePage extends StatelessWidget {
  final String name;
  final String distance;
  final bool available;
  final String phoneNumber;

  const FundiProfilePage({
    super.key,
    required this.name,
    required this.distance,
    required this.available,
    required this.phoneNumber,
  });

  void contactViaCall(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      print('Could not launch phone app');
    }
  }

  void contactViaWhatsApp(String phone) async {
    final Uri whatsappUri = Uri.parse("https://wa.me/[4m$phone[0m");
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$name\'s Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $name', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Distance: $distance'),
            const SizedBox(height: 10),
            Text('Status: ${available ? 'Available' : 'Busy'}',
                style: TextStyle(
                    color: available ? Colors.green : Colors.redAccent)),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  onPressed: () => contactViaCall(phoneNumber),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp),
                  label: const Text('WhatsApp'),
                  onPressed: () => contactViaWhatsApp(phoneNumber),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Ratings & Reviews:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text('⭐️⭐️⭐️⭐️☆ (4.0)'),
            const Text('"Very professional and fast service."'),
            const Text('"Came on time and did a great job."'),
            const SizedBox(height: 20),
            Text(
              'Leave a Review:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('fundis')
                  .doc(name)
                  .collection('ratings')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text('No reviews yet.');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final rating = data['rating'] ?? 0;
                    final review = data['review'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('${'⭐' * rating} - $review'),
                    );
                  }).toList(),
                );
              },
            ),
            RatingForm(fundiName: name),
          ],
        ),
      ),
    );
  }
}

class RatingForm extends StatefulWidget {
  final String fundiName;

  const RatingForm({super.key, required this.fundiName});

  @override
  State<RatingForm> createState() => _RatingFormState();
}

class _RatingFormState extends State<RatingForm> {
  final _formKey = GlobalKey<FormState>();
  int _rating = 5;
  String _review = '';

  Future<void> submitRating() async {
    await FirebaseFirestore.instance
        .collection('fundis')
        .doc(widget.fundiName)
        .collection('ratings')
        .add({
      'rating': _rating,
      'review': _review,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted')),
    );

    setState(() {
      _rating = 5;
      _review = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            value: _rating,
            decoration: const InputDecoration(labelText: 'Rating'),
            items: List.generate(
              5,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1} Star(s)'),
              ),
            ),
            onChanged: (value) {
              if (value != null) setState(() => _rating = value);
            },
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Review'),
            onChanged: (value) => _review = value,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: submitRating,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
