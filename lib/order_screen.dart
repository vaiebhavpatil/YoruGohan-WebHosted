import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'orders_list_screen.dart'; // Import the OrdersListScreen
import 'package:firebase_auth/firebase_auth.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  // Function to place order
  // _placeOrder method in OrderScreen
  void _placeOrder(String order) async {
    try {
      var userId =
          'current-logged-in-user-id'; // Get the logged-in user ID, e.g., from FirebaseAuth

      await FirebaseFirestore.instance.collection('orders').add({
        'order': order,
        'status': 'pending', // Default status when order is created
        'timestamp': FieldValue.serverTimestamp(),
        'user_id':
            FirebaseAuth.instance.currentUser?.uid, // Store the user's UID
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order for $order placed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order. Please try again!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Food'),
      ),
      body: Column(
        children: [
          // Pizza ListTile
          ListTile(
            title: const Text('Pizza'),
            subtitle: const Text('₹200'),
            trailing: ElevatedButton(
              onPressed: () {
                _placeOrder('Pizza'); // Trigger order placement for Pizza
              },
              child: const Text('Order'),
            ),
          ),
          // Burger ListTile
          ListTile(
            title: const Text('Burger'),
            subtitle: const Text('₹100'),
            trailing: ElevatedButton(
              onPressed: () {
                _placeOrder('Burger'); // Trigger order placement for Burger
              },
              child: const Text('Order'),
            ),
          ),
          // Button to navigate to Orders List
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const OrdersListScreen()),
                );
              },
              child: const Text('View My Orders'),
            ),
          ),
        ],
      ),
    );
  }
}
