import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; // required for kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_screen.dart';
import 'fundi_dashboard.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['API_KEY']!,
        appId: dotenv.env['APP_ID']!,
        projectId: dotenv.env['PROJECT_ID']!,
        messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!, 
      ), 
  );
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
