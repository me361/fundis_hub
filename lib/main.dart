import 'package:flutter/foundation.dart'; // required for kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_screen.dart';
import 'fundi_dashboard.dart';


const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyCTPMaf1vi11KpTqaGBdkNPa4gEufljTb4",
  authDomain: "fundishub.firebaseapp.com",
  projectId: "fundishub",
  storageBucket: "fundishub.firebasestorage.app",
  messagingSenderId: "360697935667",
  appId: "1:360697935667:web:0e9933e7e2286e4ad3f046"
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(options: firebaseConfig); // ← for Chrome
  } else {
    await Firebase.initializeApp(); // ← for Android later
  }

  runApp(MyApp());
}

// Main app widget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fundis Hub',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: AuthScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/fundi': (context) => const FundiDashboard(),
      },
    );
  }
}

// First screen user sees
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fundis Hub'),
      ),
      body: Center(
        child: Text(
          'Welcome to Fundis Hub!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
