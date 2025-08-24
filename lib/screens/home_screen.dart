import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'inventory_screen.dart';
import 'order_history_screen.dart';
import 'admin_dashboard_screen.dart'; // ✅ Import Admin Dashboard

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAdmin = false; // ✅ Track if the user is an admin
  bool _loading = true; // ✅ Track loading state

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _isAdmin = doc.exists && doc.data()?['role'] == "admin";
        _loading = false; // ✅ Stop loading
      });
    } else {
      setState(() {
        _loading = false; // ✅ Stop loading if no user
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rice Connect"),
        backgroundColor: Colors.green,
        centerTitle: true,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.green.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rice_bowl, size: 80, color: Colors.green.shade800),
            SizedBox(height: 10),
            Text(
              "Welcome to Rice Connect!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[900]),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Easily manage your rice inventory and orders with just a tap.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.green[800]),
              ),
            ),
            SizedBox(height: 30),
            _buildNavigationButton(context, "View Inventory", Icons.store, InventoryScreen()),
            SizedBox(height: 15),
            _buildNavigationButton(context, "View Order History", Icons.history, OrderHistoryScreen()),

            if (_loading) // ✅ Show a loading indicator while checking admin status
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: CircularProgressIndicator(),
              )
            else if (_isAdmin) // ✅ Show Admin Dashboard button only for admins
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: _buildNavigationButton(context, "Go to Admin Dashboard", Icons.admin_panel_settings, AdminDashboardScreen()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(BuildContext context, String title, IconData icon, Widget destination) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(title, style: TextStyle(fontSize: 18, color: Colors.white)),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
      },
    );
  }
}
