import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'orders_list_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final Map<String, int> _itemQuantities = {
    'Paneer Masala Dosa': 1,
    'Tea': 1,
    'Omlette': 1,
    'Burger': 1,
  };

  // Function to place an order for a specific item
  void _placeOrder(String itemName) async {
    try {
      int quantity = _itemQuantities[itemName] ?? 1;
      // Ensure quantity is at least 1 and not empty
      if (quantity > 0) {
        await FirebaseFirestore.instance.collection('orders').add({
          'order': itemName,
          'quantity': quantity, // Add quantity to the order
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
          'user_id': FirebaseAuth.instance.currentUser?.uid,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Order for $quantity $itemName(s) placed successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid quantity.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order. Please try again!')),
      );
    }
  }

  // Helper function to get price for each item
  int _getPrice(String itemName) {
    switch (itemName) {
      case 'Paneer Masala Dosa':
        return 65;
      case 'Tea':
        return 15;
      case 'Omlette':
        return 25;
      case 'Burger':
        return 100;
      default:
        return 0;
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
          // Dynamically create ListTile for each menu item
          ..._itemQuantities.keys.map((itemName) {
            return ListTile(
              title: Text(itemName),
              subtitle: Row(
                children: [
                  Text('₹${_getPrice(itemName)}'),
                  const SizedBox(width: 10),
                  Text('Qty: ${_itemQuantities[itemName]}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decrease Quantity Button
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        // Decrement quantity with a minimum limit of 1
                        if (_itemQuantities[itemName]! > 1) {
                          _itemQuantities[itemName] =
                              (_itemQuantities[itemName]! - 1).clamp(1, 99);
                        }
                      });
                    },
                  ),
                  // Order Button
                  ElevatedButton(
                    onPressed: () => _placeOrder(itemName),
                    child: const Text('Order'),
                  ),
                  // Increase Quantity Button
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        // Increment quantity with a maximum limit of 99
                        _itemQuantities[itemName] =
                            (_itemQuantities[itemName]! + 1).clamp(1, 99);
                      });
                    },
                  ),
                ],
              ),
            );
          }).toList(),
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
