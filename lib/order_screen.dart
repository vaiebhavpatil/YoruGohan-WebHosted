import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'modify_order_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final Map<String, int> _cart =
      {}; // Cart to store selected items and quantities
  final Map<String, int> _itemQuantities = {
    'Paneer Masala Dosa': 1,
    'Tea': 1,
    'Omlette': 1,
    'Burger': 1,
  };

  // Function to get the price of an item
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

  // Function to add item to the cart
  void _addToCart(String itemName, int quantity) {
    setState(() {
      if (quantity > 0) {
        _cart[itemName] = quantity;
      }
    });
  }

  // Function to remove item from the cart
  void _removeFromCart(String itemName) {
    setState(() {
      _cart.remove(itemName);
    });
  }

  // Function to place a single order for all items in the cart
  void _placeOrder() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty!')),
      );
      return;
    }

    try {
      List<Map<String, dynamic>> orderItems = _cart.entries.map((entry) {
        return {
          'item': entry.key,
          'quantity': entry.value,
          'price': _getPrice(entry.key) * entry.value,
        };
      }).toList();

      int totalPrice = _cart.entries
          .fold(0, (sum, entry) => sum + (_getPrice(entry.key) * entry.value));

      // Create a new order document in Firestore
      await FirebaseFirestore.instance.collection('orders').add({
        'items': orderItems,
        'totalPrice': totalPrice,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'user_id': FirebaseAuth.instance.currentUser?.uid,
        'role': 'user',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed successfully!')),
      );

      // Clear cart after placing the order
      setState(() {
        _cart.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order. Please try again!')),
      );
    }
  }

  // Function to display the cart
  void _viewCart() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int totalPrice = _cart.entries.fold(
            0, (sum, entry) => sum + (_getPrice(entry.key) * entry.value));

        return AlertDialog(
          title: const Text('Cart'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display cart items
              ..._cart.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  subtitle: Text('Quantity: ${entry.value}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Button to remove item from cart
                      IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () {
                          _removeFromCart(entry.key);
                        },
                      ),
                      Text('₹${_getPrice(entry.key) * entry.value}'),
                    ],
                  ),
                );
              }).toList(),
              const Divider(),
              Text(
                'Total: ₹$totalPrice',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _placeOrder();
                Navigator.of(context).pop();
              },
              child: const Text('Place Order'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Food'),
      ),
      body: Column(
        children: [
          // Dynamically generate ListTile for each menu item
          ..._itemQuantities.keys.map((itemName) {
            return ListTile(
              title: Text(itemName),
              subtitle: Row(
                children: [
                  Text('₹${_getPrice(itemName)}'),
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
                        // Decrease the quantity with a minimum of 1
                        if (_itemQuantities[itemName]! > 1) {
                          _itemQuantities[itemName] =
                              (_itemQuantities[itemName]! - 1);
                        }
                      });
                    },
                  ),
                  // Show the current quantity
                  Text('${_itemQuantities[itemName]}'),
                  // Increase Quantity Button
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        // Increase the quantity
                        _itemQuantities[itemName] =
                            (_itemQuantities[itemName]! + 1);
                      });
                    },
                  ),
                  // Add to Cart Button
                  IconButton(
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: () {
                      _addToCart(itemName, _itemQuantities[itemName]!);
                    },
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 20),
          // Button to view the cart
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _viewCart,
              child: Text('View Cart (${_cart.length} items)'),
            ),
          ),
        ],
      ),
    );
  }
}
