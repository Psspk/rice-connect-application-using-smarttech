import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart'; // Theme Provider for Dark Mode
import 'order_history_screen.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String address = "Not Provided";
  String displayName = "User Name";
  String email = "No Email";
  String photoUrl = "";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    if (user == null) return;

    setState(() {
      displayName = user!.displayName ?? "User Name";
      email = user!.email ?? "No Email";
      photoUrl = user!.photoURL ?? "";
    });

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null) {
        setState(() {
          address = userData['address'] ?? "Not Provided";
        });
      }
    } catch (e) {
      print("❌ Firestore Error: $e");
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }

  void _editField(BuildContext context, String field, String currentValue) async {
    TextEditingController controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $field"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: "Enter new $field",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String newValue = controller.text.trim();
              if (newValue.isNotEmpty && newValue != currentValue) {
                try {
                  await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                    field: newValue,
                  });
                  setState(() {
                    if (field == 'displayName') {
                      user?.updateDisplayName(newValue);
                      displayName = newValue;
                    }
                    if (field == 'address') address = newValue;
                  });
                } catch (e) {
                  print("❌ Firestore Update Error: $e");
                }
              }
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("My Account"), backgroundColor: Colors.green),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : AssetImage("assets/user_placeholder.png") as ImageProvider,
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _editField(context, 'displayName', displayName),
                    child: Column(
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text("✏️ Tap to edit", style: TextStyle(fontSize: 12, color: Colors.blue)),
                      ],
                    ),
                  ),
                  Text(email, style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),

            SizedBox(height: 20),

            _buildCard(
              icon: Icons.location_on,
              title: "Address",
              subtitle: address,
              iconColor: Colors.blue,
              onTap: () => _editField(context, 'address', address),
            ),

            _buildCard(
              icon: Icons.dark_mode,
              title: "Dark Mode",
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(),
              ),
            ),

            _buildCard(
              icon: Icons.history,
              title: "Order History",
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
                );
              },
            ),

            _buildCard(
              icon: Icons.logout,
              title: "Logout",
              iconColor: Colors.red,
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color iconColor = Colors.black,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 28),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing ?? (onTap != null ? Icon(Icons.edit, color: Colors.grey) : null),
        onTap: onTap,
      ),
    );
  }
}
