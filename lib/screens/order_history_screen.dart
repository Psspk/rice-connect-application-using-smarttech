import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Order History")),
      body: user == null
          ? Center(child: Text("Please log in to view order history."))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Firestore Error: ${snapshot.error}"); // ✅ Log actual error
            return Center(child: Text("❌ Error loading orders. Please try again."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("📭 No past orders found."));
          }

          var orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var orderData = orders[index].data() as Map<String, dynamic>?;

              if (orderData == null) return SizedBox.shrink(); // ✅ Handle null gracefully

              String orderId = orders[index].id;
              double totalAmount = (orderData['totalAmount'] as num?)?.toDouble() ?? 0.0;
              String status = orderData['status']?.toString() ?? "Unknown";
              Timestamp? timestamp = orderData['timestamp'] as Timestamp?;
              List<dynamic> items = (orderData['items'] as List<dynamic>?) ?? [];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          "Order ID: $orderId",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          "Total: ₹${totalAmount.toStringAsFixed(2)}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                        ),
                        trailing: Chip(
                          label: Text(
                            status,
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: status == "Completed" ? Colors.green : Colors.orange,
                        ),
                      ),
                      Divider(),
                      ...items.map((item) {
                        String riceName = item['riceName']?.toString() ?? "Unknown Rice";
                        int quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                          child: Text(
                            "🍚 $riceName - $quantity Quintals",
                            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                          ),
                        );
                      }).toList(),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              SizedBox(width: 5),
                              Text(
                                timestamp != null
                                    ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
                                    : "Unknown Date",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          Icon(Icons.shopping_bag, color: Colors.blueGrey),
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
