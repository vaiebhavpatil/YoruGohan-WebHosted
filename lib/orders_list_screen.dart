import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // Get the current user

    if (user == null) {
      return const Center(child: Text('No user logged in.'));
    }

    print("Current user ID: ${user.uid}"); // Debug: Log the user ID

    return Scaffold(
      appBar: AppBar(
        title: const Text('Placed Orders'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('user_id',
                isEqualTo: user.uid) // Use 'user_id' to match Firestore
            .orderBy('timestamp', descending: true) // Sort by timestamp
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Error loading orders: ${snapshot.error}"); // Debug error
            return Center(
                child: Text('Error loading orders: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print(
                "No orders found for user ID: ${user.uid}"); // Debug no orders
            return const Center(child: Text('No orders placed yet.'));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var order = orders[index];
              print("Order found: ${order['order']}"); // Debug order details
              return ListTile(
                title: Text(order['order'] ?? 'No Order Name'),
                subtitle: Text('Status: ${order['status']}'),
                trailing: Text(
                  order['timestamp']?.toDate()?.toString() ?? 'No Date',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
