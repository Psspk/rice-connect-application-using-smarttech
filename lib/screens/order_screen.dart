import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart'; // Import MainScreen to navigate properly

class OrderScreen extends StatefulWidget {
  final String riceName;
  final double pricePerQuintal;

  OrderScreen({required this.riceName, required this.pricePerQuintal});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final TextEditingController _quantityController = TextEditingController();

  Future<void> _addToCart() async {
    int quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid quantity")),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please log in first")),
        );
        return;
      }

      print("📌 Checking cart for existing item: ${widget.riceName}");

      // Get cart reference
      var cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');

      // Check if item already exists
      var existingItem = await cartRef
          .where("riceName", isEqualTo: widget.riceName)
          .limit(1)
          .get();

      if (existingItem.docs.isNotEmpty) {
        // Update existing item instead of adding a duplicate
        var docId = existingItem.docs.first.id;
        var currentQuantity = existingItem.docs.first['quantity'];
        var newQuantity = currentQuantity + quantity;
        double totalPrice = newQuantity * widget.pricePerQuintal;

        await cartRef.doc(docId).update({
          "quantity": newQuantity,
          "totalPrice": totalPrice,
        });

        print("✅ Updated existing cart item!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${widget.riceName} quantity updated in cart")),
        );
      } else {
        // Add new item if not found
        String cartItemId = cartRef.doc().id;
        double totalPrice = quantity * widget.pricePerQuintal;

        await cartRef.doc(cartItemId).set({
          "riceName": widget.riceName,
          "quantity": quantity,
          "pricePerQuintal": widget.pricePerQuintal,
          "totalPrice": totalPrice,
          "timestamp": FieldValue.serverTimestamp(),
        });

        print("✅ Item added to cart successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${widget.riceName} added to cart")),
        );
      }

      // ✅ Navigate to MainScreen and open the Cart tab
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(initialIndex: 2)),
      );
    } catch (e) {
      print("❌ Firestore Error: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add item: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order ${widget.riceName}"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${widget.riceName}",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Price: ₹${widget.pricePerQuintal} per quintal",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Enter Quantity (Quintals)"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addToCart,
              child: Text("Add to Cart"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
