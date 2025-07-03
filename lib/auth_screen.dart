import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'client_home_screen.dart';
import 'fundi_dashboard.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLogin = true;
  String errorMessage = '';
  bool isLoading = false;
  String selectedRole = 'client';
  String selectedSpecialization = 'Plumber'; // default

  void toggleMode() {
    setState(() {
      isLogin = !isLogin;
      errorMessage = '';
    });
  }

  Future<void> handleAuth() async {
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // After login, check user role
        final uid = _auth.currentUser!.uid;
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (doc.exists && doc['role'] == 'fundi') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => FundiDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ClientHomeScreen()),
          );
        }
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Store user info in Firestore
        final role = selectedRole; // from the dropdown
        final specialization = selectedSpecialization;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .set({
          'email': emailController.text.trim(),
          'role': role,
          if (role == 'fundi') 'specialization': specialization,
        });

        // If registering as fundi, also add to 'fundis' collection
        if (role == 'fundi') {
          await FirebaseFirestore.instance
              .collection('fundis')
              .doc(_auth.currentUser!.uid)
              .set({
            'email': emailController.text.trim(),
            'specialization': specialization,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // After registration, check role and navigate
        if (role == 'fundi') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => FundiDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ClientHomeScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => errorMessage = e.message ?? 'Authentication error');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email Input
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),

            // Password Input
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // Role Dropdown (only show on Register)
            if (!isLogin)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Role:'),
                  DropdownButton<String>(
                    value: selectedRole,
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'client',
                        child: Text('Client'),
                      ),
                      DropdownMenuItem(
                        value: 'fundi',
                        child: Text('Fundi'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (selectedRole == 'fundi')
                    DropdownButtonFormField<String>(
                      value: selectedSpecialization,
                      decoration: const InputDecoration(labelText: 'Specialization'),
                      items: ['Plumber', 'Electrician', 'Carpenter', 'Painter', 'Technician']
                          .map((spec) => DropdownMenuItem(
                                value: spec,
                                child: Text(spec),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSpecialization = value!;
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                ],
              ),

            // Error message
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: isLoading ? null : handleAuth,
              child: Text(isLogin ? 'Login' : 'Register'),
            ),

            const SizedBox(height: 10),

            // Toggle between Login/Register
            TextButton(
              onPressed: toggleMode,
              child: Text(isLogin
                  ? "Don't have an account? Register"
                  : "Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
