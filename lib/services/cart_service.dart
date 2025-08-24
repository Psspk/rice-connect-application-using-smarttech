import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Get the current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// ✅ Add item to cart (updates quantity if already exists)
  Future<void> addToCart(String riceName, int quantity, double price) async {
    if (_userId == null) {
      print("❌ Error: User not authenticated.");
      return;
    }

    try {
      // Reference to the user's cart collection
      CollectionReference cartRef = _firestore.collection('users').doc(_userId).collection('cartItems');

      // Check if the item already exists in the cart
      QuerySnapshot existingItems = await cartRef.where('riceName', isEqualTo: riceName).get();

      if (existingItems.docs.isNotEmpty) {
        // If item exists, update the quantity & total price
        DocumentSnapshot itemDoc = existingItems.docs.first;
        int newQuantity = itemDoc['quantity'] + quantity;
        double newTotalPrice = newQuantity * price;

        await cartRef.doc(itemDoc.id).update({
          'quantity': newQuantity,
          'totalPrice': newTotalPrice,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // If item does not exist, create a new entry
        String itemId = cartRef.doc().id;
        double totalPrice = quantity * price;

        await cartRef.doc(itemId).set({
          'riceName': riceName,
          'quantity': quantity,
          'price': price,
          'totalPrice': totalPrice,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      print("✅ Item added to cart successfully!");
    } catch (e) {
      print("❌ Error adding item to cart: $e");
    }
  }

  /// ✅ Get cart items in real-time (StreamBuilder can use this)
  Stream<List<Map<String, dynamic>>> getCartItems() {
    if (_userId == null) {
      print("❌ Error: User not authenticated.");
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('cartItems')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  /// ✅ Remove a single item from cart
  Future<void> removeFromCart(String itemId) async {
    if (_userId == null) {
      print("❌ Error: User not authenticated.");
      return;
    }

    try {
      await _firestore.collection('users').doc(_userId).collection('cartItems').doc(itemId).delete();
      print("✅ Item removed from cart.");
    } catch (e) {
      print("❌ Error removing item from cart: $e");
    }
  }

  /// ✅ Clear entire cart after placing an order
  Future<void> clearCart() async {
    if (_userId == null) {
      print("❌ Error: User not authenticated.");
      return;
    }

    try {
      var cartItems = await _firestore.collection('users').doc(_userId).collection('cartItems').get();
      for (var doc in cartItems.docs) {
        await doc.reference.delete();
      }
      print("✅ Cart cleared successfully!");
    } catch (e) {
      print("❌ Error clearing cart: $e");
    }
  }
}
