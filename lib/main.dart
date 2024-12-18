import 'package:flutter/material.dart';
import 'signup_screen.dart'; // Import your signup screen
import 'login_screen.dart'; // Import your login screen
import 'order_screen.dart'; // Import your order screen
import 'orders_list_screen.dart'; // Import OrdersListScreen
import 'kitchen_orders_screen.dart'; // Import your kitchen-specific orders screen
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Firebase options for web (replace with your own)
import 'firebase_options.dart'; // Ensure this file is generated by the Firebase CLI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the appropriate options for the current platform (e.g., web)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // This is crucial for web
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Global key for Navigator
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // Wait for the first frame to be drawn before navigating
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserRole();
    });
  }

  // Check the user's role on app startup
  Future<void> _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Get the user's role from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String role =
          userDoc['role'] ?? 'user'; // Default to 'user' if no role is found

      if (role == 'kitchen') {
        // Navigate to the kitchen screen if the user is a worker
        _navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (context) => KitchenOrdersScreen()),
        );
      } else {
        // Navigate to the user screen if the user is a regular customer
        _navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (context) => OrdersListScreen()),
        );
      }
    } else {
      // Navigate to login screen if no user is logged in
      _navigatorKey.currentState?.pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YoruGohan',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login', // Set initial route to login
      navigatorKey: _navigatorKey, // Use the global navigator key
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/order': (context) => OrderScreen(), // Define your order screen route
        '/orders': (context) =>
            OrdersListScreen(), // Add route for OrdersListScreen
        '/kitchen': (context) =>
            KitchenOrdersScreen(), // New route for KitchenOrdersScreen
      },
      home: Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(), // Show loading spinner while checking user role
        ),
      ),
    );
  }
}
