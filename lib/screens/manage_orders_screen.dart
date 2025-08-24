import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageOrdersScreen extends StatefulWidget {
  @override
  _ManageOrdersScreenState createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  Future<List<QueryDocumentSnapshot>> fetchAllOrders() async {
    List<QueryDocumentSnapshot> allOrders = [];

    QuerySnapshot usersSnapshot =
    await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in usersSnapshot.docs) {
      String userId = userDoc.id;

      QuerySnapshot orderSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .orderBy('timestamp', descending: true)
          .get();

      allOrders.addAll(orderSnapshot.docs);
    }

    return allOrders;
  }

  Future<void> updateOrderStatus(String userId, String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .update({'status': 'Completed'});

      setState(() {}); // Refresh UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Order marked as Completed"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to update order: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Orders")),
      body: FutureBuilder(
        future: fetchAllOrders(),
        builder: (context, AsyncSnapshot<List<QueryDocumentSnapshot>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("❌ Error fetching orders: ${snapshot.error}");
            return Center(
                child: Text("❌ Error loading orders. Please try again."));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("📭 No orders available."));
          }

          var orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var orderData = orders[index].data() as Map<String, dynamic>;

              String orderId = orders[index].id;
              String userId = orderData['userId']?.toString() ?? "Unknown User";
              double totalAmount =
                  (orderData['totalAmount'] as num?)?.toDouble() ?? 0.0;
              String status = orderData['status']?.toString() ?? "Pending";
              Timestamp? timestamp = orderData['timestamp'] as Timestamp?;
              List<dynamic> items = orderData['items'] ?? [];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Order Header (Prevents Overflow)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Order ID: $orderId",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis, // Prevents overflow
                            ),
                          ),
                          Chip(
                            label: Text(
                              status,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: status == "Completed"
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Divider(),

                      // 🔹 User ID & Total Price
                      Text(
                        "👤 User ID: $userId",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "💰 Total: ₹${totalAmount.toStringAsFixed(2)}",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                      SizedBox(height: 8),

                      // 🔹 Order Items List
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items.map((item) {
                          String riceName =
                              item['riceName']?.toString() ?? "Unknown Rice";
                          int quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Icon(Icons.shopping_bag,
                                    size: 18, color: Colors.brown),
                                SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    "$riceName - $quantity Quintals",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[800]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 8),

                      // 🔹 Date & Mark as Completed Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16, color: Colors.grey),
                              SizedBox(width: 5),
                              Text(
                                timestamp != null
                                    ? DateFormat('yyyy-MM-dd HH:mm')
                                    .format(timestamp.toDate())
                                    : "Unknown Date",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          if (status != "Completed") // Show button only if status is Pending
                            ElevatedButton.icon(
                              onPressed: () => updateOrderStatus(userId, orderId),
                              icon: Icon(Icons.check_circle, size: 18),
                              label: Text("Mark as Completed"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding:
                                EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                        ],
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
}
