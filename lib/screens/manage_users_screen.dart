import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersScreen extends StatefulWidget {
  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('users');

  String searchQuery = ""; // ✅ Stores the search query

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Users"),
        backgroundColor: Colors.green,
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by shop name or email...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query.toLowerCase(); // ✅ Update search query
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: usersCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No users available."));
                }

                // ✅ Filter users based on the search query
                var filteredUsers = snapshot.data!.docs.where((doc) {
                  var userData = doc.data() as Map<String, dynamic>;
                  String shopName = (userData['shopName'] ?? "").toLowerCase();
                  String email = (userData['email'] ?? "").toLowerCase();

                  return shopName.contains(searchQuery) || email.contains(searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(child: Text("No users match your search."));
                }

                return ListView(
                  padding: EdgeInsets.all(16),
                  children: filteredUsers.map((doc) {
                    var userData = doc.data() as Map<String, dynamic>;
                    String userId = doc.id;
                    String shopName = userData['shopName'] ?? "Unknown Shop"; // ✅ Fetch shop name
                    String email = userData['email'] ?? "No email";
                    String role = userData['role'] ?? "user"; // Default to "user"

                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade700,
                          child: Icon(Icons.store, color: Colors.white), // ✅ Store Icon
                        ),
                        title: Text(
                          shopName, // ✅ Display Shop Name
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(email, style: TextStyle(fontSize: 14)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Role Toggle Button
                            IconButton(
                              icon: Icon(
                                role == "admin" ? Icons.admin_panel_settings : Icons.person,
                                color: role == "admin" ? Colors.orange : Colors.grey,
                              ),
                              onPressed: () {
                                _toggleUserRole(userId, role);
                              },
                            ),

                            // Delete User Button
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _confirmDelete(userId);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Function to Promote/Demote a User Role
  Future<void> _toggleUserRole(String userId, String currentRole) async {
    String newRole = currentRole == "admin" ? "user" : "admin";

    try {
      await usersCollection.doc(userId).update({'role': newRole});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ User role updated to $newRole"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to update role: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Function to Show Confirmation Dialog Before Deleting a User
  void _confirmDelete(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete User?"),
        content: Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _deleteUser(userId);
              Navigator.pop(context);
            },
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  /// Function to Delete a User
  Future<void> _deleteUser(String userId) async {
    try {
      await usersCollection.doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ User deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to delete user: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
