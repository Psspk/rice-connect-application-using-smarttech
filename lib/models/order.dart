import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String userId;
  final double totalAmount;
  final DateTime timestamp; // ✅ Ensures DateTime format
  final List<OrderItem> items;
  final String status;

  Order({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.timestamp,
    required this.items,
    required this.status,
  });

  /// ✅ Converts Firestore document snapshot to Order object
  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {}; // ✅ Safely cast data
    return Order.fromMap(data, doc.id);
  }

  /// ✅ Converts Firestore data into an Order object
  factory Order.fromMap(Map<String, dynamic> data, String documentId) {
    return Order(
      id: documentId,
      userId: data['userId'] ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'Pending',
      items: (data['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  /// ✅ Converts Order object to Firestore format
  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "totalAmount": totalAmount,
      "timestamp": Timestamp.fromDate(timestamp), // ✅ Correct timestamp format
      "status": status,
      "items": items.map((item) => item.toMap()).toList(),
    };
  }
}

class OrderItem {
  final String itemId;
  final String riceName;
  final int quantity;
  final double price;

  OrderItem({
    required this.itemId,
    required this.riceName,
    required this.quantity,
    required this.price,
  });

  /// ✅ Calculates total price dynamically
  double get totalPrice => quantity * price;

  /// ✅ Converts Firestore data into OrderItem object
  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      itemId: data['itemId'] ?? '',
      riceName: data['riceName'] ?? 'Unknown',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// ✅ Converts OrderItem object to Firestore format
  Map<String, dynamic> toMap() {
    return {
      "itemId": itemId,
      "riceName": riceName,
      "quantity": quantity,
      "price": price,
    };
  }
}
