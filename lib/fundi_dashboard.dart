import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FundiDashboard extends StatefulWidget {
  const FundiDashboard({super.key});

  @override
  State<FundiDashboard> createState() => _FundiDashboardState();
}

class _FundiDashboardState extends State<FundiDashboard> {
  bool isAvailable = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    getAvailabilityStatus();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Fundi Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Availability Status',
              style: TextStyle(fontSize: 18),
            ),
            Switch(
              value: isAvailable,
              onChanged: toggleAvailability,
            ),
            Text(
              isAvailable ? 'You are Available' : 'You are Busy',
              style: TextStyle(fontSize: 16, color: isAvailable ? Colors.green : Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
