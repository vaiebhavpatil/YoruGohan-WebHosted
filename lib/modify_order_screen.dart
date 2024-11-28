import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class ModifyOrderScreen extends StatelessWidget {
  final String userId;
  final String orderId;

  // Constructor to accept both userId and orderId
  ModifyOrderScreen({required this.userId, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modify Orders'),
      ),
      body: StreamBuilder(
        // Fetch orders for the specific user and orderId
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('user_id', isEqualTo: userId)
            .where('orderId', isEqualTo: orderId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading order: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No order found.'));
          }

          final order =
              snapshot.data!.docs.first; // Only one order based on orderId

          String orderStatus =
              order['status'] ?? 'pending'; // Default to 'pending'
          Timestamp timestamp = order['timestamp'];
          List items = order['items'] ?? [];

          // Format the timestamp into a human-readable date and time format
          String formattedDate =
              DateFormat('dd-MM-yyyy hh:mm a').format(timestamp.toDate());

          return ListView(
            children: [
              ListTile(
                title: Text('Order ID: $orderId'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display items in the order
                    for (var item in items)
                      Text(
                        '${item['item']} - ${item['quantity']} x ${item['price']}',
                      ),
                    Text('Total Price: ${order['totalPrice']}'),
                    Text('Status: $orderStatus'),
                    Text('Ordered on: $formattedDate'),
                  ],
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
                              _editQuantity(context, order.id, items);
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
              ),
            ],
          );
        },
      ),
    );
  }

  // Function to edit quantity
  void _editQuantity(BuildContext context, String orderId, List items) {
    // Add logic to edit quantity for items
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Quantity'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Enter new quantity'),
            onChanged: (value) {
              // Update logic for quantity editing
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                // After editing, update the quantity in Firestore
                FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .update({
                  'items': items, // Update the items field with new quantities
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quantity updated')),
                );
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
