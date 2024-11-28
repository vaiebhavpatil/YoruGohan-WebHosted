import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KitchenOrdersScreen extends StatefulWidget {
  const KitchenOrdersScreen({super.key});

  @override
  _KitchenOrdersScreenState createState() => _KitchenOrdersScreenState();
}

class _KitchenOrdersScreenState extends State<KitchenOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'pending') // Only show pending orders
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading orders: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders placed yet.'));
          }

          // Local filtering to exclude collected orders
          final orders = snapshot.data!.docs.where((doc) {
            String status = doc['status'] ?? 'pending';
            return status != 'collected'; // Exclude 'collected' orders
          }).toList();

          if (orders.isEmpty) {
            return const Center(child: Text('No active orders.'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var order = orders[index];
              var items = order['items'] as List<dynamic>;

              // Display each order
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Items:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // Display items and quantities
                      ...items.map((item) {
                        return Text(
                          '${item['item']} - Quantity: ${item['quantity']}',
                        );
                      }).toList(),
                      const SizedBox(height: 10),
                      // Display total price
                      Text(
                        'Total Price: ₹${order['totalPrice']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      // Buttons to update order status
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: () {
                          _updateOrderStatus(order.id, 'In Progress');
                        },
                        child: const Text('Mark as In Progress'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () {
                          _updateOrderStatus(order.id, 'Completed');
                        },
                        child: const Text('Mark as Completed'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          bool confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Collection'),
                              content: const Text(
                                  'Are you sure you want to mark this order as collected?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, true);
                                  },
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );

                          if (confirm) {
                            FirebaseFirestore.instance
                                .collection('orders')
                                .doc(order.id)
                                .update({'status': 'collected'});
                          }
                        },
                        child: const Text('Collected'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Function to update the order status
  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': status});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update order status')),
      );
    }
  }
}
