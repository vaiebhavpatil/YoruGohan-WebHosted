import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting
import 'modify_order_screen.dart'; // Correct import

class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('No user logged in.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Placed Orders'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('user_id', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading orders: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders placed yet.'));
          }

          final orders = snapshot.data!.docs;

          return ListView(
            children: orders.map((order) {
              String status = order['status'] ??
                  'pending'; // Default to 'pending' if status doesn't exist
              Timestamp timestamp = order['timestamp']; // Get the timestamp
              String formattedDate =
                  DateFormat('dd-MM-yyyy hh:mm a').format(timestamp.toDate());

              return ListTile(
                title: Text(order['order'] ?? 'No Order Name'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quantity: ${order['quantity']}'),
                    Text('Status: $status'),
                    Text('Ordered on: $formattedDate'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    // If the order is in progress or ready, show a dialog
                    if (status == 'in_progress') {
                      // Show a dialog for in-progress orders
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Order In Progress'),
                            content: const Text(
                                'This order is currently being processed and cannot be modified at this time.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    } else if (status == 'ready') {
                      // Show a dialog for ready orders
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Order Ready'),
                            content: const Text(
                                'This order is ready for delivery and cannot be modified at this time.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      // If the order is not in progress or ready, allow modification
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ModifyOrderScreen(
                            userId: user.uid,
                          ), // Pass the order object
                        ),
                      );
                    }
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
