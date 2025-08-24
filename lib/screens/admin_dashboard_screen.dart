import 'package:flutter/material.dart';
import 'manage_inventory_screen.dart'; // ✅ Import Manage Inventory Screen
import 'manage_orders_screen.dart'; // ✅ Import Manage Orders Screen
import 'manage_users_screen.dart'; // ✅ Import Manage Users Screen

class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        backgroundColor: Colors.green,
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 80, color: Colors.green.shade800),
            SizedBox(height: 20),
            Text(
              "Welcome, Admin!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[900]),
            ),
            SizedBox(height: 30),
            _buildAdminButton(context, "Manage Inventory", Icons.store, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageInventoryScreen()),
              );
            }),
            SizedBox(height: 15),
            _buildAdminButton(context, "Manage Orders", Icons.shopping_cart, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageOrdersScreen()),
              );
            }),
            SizedBox(height: 15),
            _buildAdminButton(context, "Manage Users", Icons.people, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageUsersScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(title, style: TextStyle(fontSize: 18, color: Colors.white)),
      onPressed: onPressed,
    );
  }
}
