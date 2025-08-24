import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' as CustomOrder;

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Places an order for the current user
  Future<void> placeOrder(List<CustomOrder.OrderItem> cartItems) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        print("❌ Error: User not authenticated. Order not placed.");
        return;
      }

      // Generate a unique order ID
      String orderId = _firestore.collection('users').doc(userId).collection('orders').doc().id;
      double totalAmount = cartItems.fold(0, (sum, item) => sum + item.totalPrice);
      List<Map<String, dynamic>> itemsList = cartItems.map((item) => item.toMap()).toList();

      Map<String, dynamic> orderData = {
        "id": orderId,
        "userId": userId,
        "totalAmount": totalAmount,
        "timestamp": FieldValue.serverTimestamp(), // ✅ Consistent timestamp naming
        "items": itemsList,
        "status": "Pending", // ✅ Default status
      };

      print("📦 Attempting to save order for user $userId...");
      print("📋 Order Data: $orderData");

      await _firestore.collection('users').doc(userId).collection('orders').doc(orderId).set(orderData);

      print("✅ Order successfully stored in Firestore!");

    } catch (e) {
      print("❌ Error placing order: $e");
    }
  }

  /// ✅ Retrieves orders for the currently logged-in user in real-time.
  Stream<List<CustomOrder.Order>> getOrdersForUser() {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      print("❌ Error: User is not logged in.");
      return Stream.value([]);
    }

    print("📡 Fetching orders for user: $userId...");

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('timestamp', descending: true) // ✅ Consistent field name
        .snapshots()
        .map((snapshot) {
      print("📡 Firestore Orders Retrieved: ${snapshot.docs.length} orders found.");

      return snapshot.docs.map((doc) {
        try {
          return CustomOrder.Order.fromFirestore(doc);
        } catch (e) {
          print("❌ Error parsing order document ${doc.id}: $e");
          return null;
        }
      }).whereType<CustomOrder.Order>().toList();
    });
  }

  /// ✅ Fetch all orders (For Admin)
  Stream<List<CustomOrder.Order>> getAllOrders() {
    print("📡 Fetching all orders for admin...");

    return _firestore
        .collectionGroup('orders')
        .orderBy('timestamp', descending: true) // ✅ Ensure timestamp ordering
        .snapshots()
        .map((snapshot) {
      print("📡 Admin Orders Retrieved: ${snapshot.docs.length} orders found.");

      return snapshot.docs.map((doc) {
        try {
          return CustomOrder.Order.fromFirestore(doc);
        } catch (e) {
          print("❌ Error parsing admin order document ${doc.id}: $e");
          return null;
        }
      }).whereType<CustomOrder.Order>().toList();
    });
  }

  /// ✅ Update order status (For Admin)
  Future<void> updateOrderStatus(String orderId, String userId, String status) async {
    try {
      // Check if the admin is updating the order
      String? adminId = _auth.currentUser?.uid;
      if (adminId == null) {
        print("❌ Error: Admin not authenticated.");
        return;
      }

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(adminId).get();
      if (!userDoc.exists || userDoc['role'] != 'admin') {
        print("❌ Error: Access denied. Only admins can update orders.");
        return;
      }

      await _firestore.collection('users').doc(userId).collection('orders').doc(orderId).update({
        'status': status,
      });
      print("✅ Order $orderId status updated to $status.");
    } catch (e) {
      print("❌ Error updating order status: $e");
    }
  }

  /// ✅ Delete an order (For Admin)
  Future<void> deleteOrder(String orderId, String userId) async {
    try {
      // Check if the admin is deleting the order
      String? adminId = _auth.currentUser?.uid;
      if (adminId == null) {
        print("❌ Error: Admin not authenticated.");
        return;
      }

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(adminId).get();
      if (!userDoc.exists || userDoc['role'] != 'admin') {
        print("❌ Error: Access denied. Only admins can delete orders.");
        return;
      }

      await _firestore.collection('users').doc(userId).collection('orders').doc(orderId).delete();
      print("✅ Order $orderId deleted successfully.");
    } catch (e) {
      print("❌ Error deleting order: $e");
    }
  }
}
