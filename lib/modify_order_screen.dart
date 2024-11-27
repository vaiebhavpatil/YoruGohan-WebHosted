import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class ModifyOrderScreen extends StatelessWidget {
  final String userId;

  ModifyOrderScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modify Orders'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('user_id', isEqualTo: userId)
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
            return const Center(child: Text('No orders to modify.'));
          }

          final orders = snapshot.data!.docs;

          return ListView(
            children: orders.map((order) {
              String orderStatus =
                  order['status'] ?? 'pending'; // Default to 'pending'
              Timestamp timestamp = order['timestamp'];

              // Format the timestamp into a human-readable date and time format
              String formattedDate =
                  DateFormat('dd-MM-yyyy hh:mm a').format(timestamp.toDate());

              return ListTile(
                title: Text(order['order'] ?? 'No Order Name'),
                subtitle: Text(
                  'Quantity: ${order['quantity']}\nStatus: $orderStatus\nOrdered on: $formattedDate',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit quantity button - disabled if status is in progress or ready
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: orderStatus == 'pending'
                          ? () {
                              // Edit quantity functionality here
                              _editQuantity(
                                  context, order.id, order['quantity']);
                            }
                          : null, // Disable button if not pending
                    ),
                    // Delete button - only enabled if status is pending
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: orderStatus == 'pending'
                          ? () {
                              // Delete order functionality here
                              _deleteOrder(context, order.id);
                            }
                          : null, // Disable button if not pending
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // Function to edit quantity
  void _editQuantity(
      BuildContext context, String orderId, int currentQuantity) {
    TextEditingController controller =
        TextEditingController(text: currentQuantity.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Quantity'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Enter new quantity'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                int newQuantity = int.parse(controller.text);
                if (newQuantity > 0) {
                  FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .update({
                    'quantity': newQuantity,
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quantity updated')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Quantity must be greater than 0')),
                  );
                }
              },
              child: const Text('Update'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Function to delete order
  void _deleteOrder(BuildContext context, String orderId) {
    FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .delete()
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order deleted successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete order: $error')),
      );
    });
  }
}
