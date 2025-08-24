import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final OrderService _orderService = OrderService();

  Future<void> placeOrder(BuildContext context) async {
    if (user == null || user!.uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to place an order')),
      );
      return;
    }

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart');

    try {
      QuerySnapshot cartSnapshot = await cartRef.get();
      if (cartSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your cart is empty')),
        );
        return;
      }

      List<OrderItem> cartItems = cartSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return OrderItem(
          itemId: data['itemId'] ?? '',
          riceName: data['riceName'] ?? 'Unknown',
          quantity: data['quantity'] ?? 1,
          price: (data['pricePerQuintal'] ?? 0).toDouble(),
        );
      }).toList();

      // ✅ Ensure valid stock update
      for (var item in cartItems) {
        if (item.itemId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('inventory')
              .doc(item.itemId)
              .update({
            'stock': FieldValue.increment(-item.quantity), // Reduce stock
          });
        }
      }

      await _orderService.placeOrder(cartItems);

      // ✅ Clear cart after order placement
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Shopping Cart")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: user != null
                  ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('cart')
                  .snapshots()
                  : null,
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("Your cart is empty"));
                }

                var cartItems = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    var item = cartItems[index];
                    var itemData = item.data() as Map<String, dynamic>;

                    String riceName = itemData['riceName'] ?? 'Unknown Item';
                    int quantity = itemData['quantity'] ?? 1;
                    double pricePerQuintal = (itemData['pricePerQuintal'] ?? 0).toDouble();
                    double totalPrice = quantity * pricePerQuintal;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 3,
                      child: ListTile(
                        leading: Icon(Icons.shopping_bag, color: Colors.green, size: 35),
                        title: Text(riceName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('Quantity: $quantity  |  Price: ₹${totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await item.reference.delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Item removed from cart')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Amount:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    StreamBuilder(
                      stream: user != null
                          ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(user!.uid)
                          .collection('cart')
                          .snapshots()
                          : null,
                      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Text("₹0",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green));
                        }

                        double totalAmount = snapshot.data!.docs.fold(0, (sum, item) {
                          var data = item.data() as Map<String, dynamic>;
                          double pricePerQuintal = (data['pricePerQuintal'] ?? 0).toDouble();
                          int quantity = data['quantity'] ?? 1;
                          return sum + (pricePerQuintal * quantity);
                        });

                        return Text(
                          "₹${totalAmount.toStringAsFixed(2)}",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => placeOrder(context),
                  child: Text("Proceed to Checkout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
