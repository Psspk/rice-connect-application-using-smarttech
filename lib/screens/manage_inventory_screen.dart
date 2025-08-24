import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageInventoryScreen extends StatefulWidget {
  @override
  _ManageInventoryScreenState createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen> {
  final CollectionReference riceCollection =
  FirebaseFirestore.instance.collection('inventory');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Inventory"),
        backgroundColor: Colors.green,
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text("Add New Rice Item"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                _showRiceDialog(context);
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: riceCollection.orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No rice items available."));
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: (data['imageUrl'] != null &&
                                Uri.tryParse(data['imageUrl'])
                                    ?.hasAbsolutePath ==
                                    true)
                                ? Image.network(
                              data['imageUrl'],
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) {
                                return _placeholderImage();
                              },
                            )
                                : _placeholderImage(),
                          ),
                          title: Text(
                            data['name'] ?? "Unknown",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "₹${data['price'] ?? 0} per quintal",
                                style: TextStyle(
                                    fontSize: 15, color: Colors.green[700]),
                              ),
                              Text(
                                "Stock: ${data['stock'] ?? 0} quintals",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _showRiceDialog(context, doc.id, data);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _confirmDelete(doc.id);
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
      ),
    );
  }

  /// Function to Show Add/Edit Rice Item Dialog
  void _showRiceDialog(BuildContext context,
      [String? docId, Map<String, dynamic>? data]) {
    TextEditingController nameController =
    TextEditingController(text: data?['name'] ?? "");
    TextEditingController priceController =
    TextEditingController(text: data?['price']?.toString() ?? "");
    TextEditingController stockController =
    TextEditingController(text: data?['stock']?.toString() ?? "");
    TextEditingController imageUrlController =
    TextEditingController(text: data?['imageUrl'] ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docId == null ? "Add Rice Item" : "Edit Rice Item"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, "Rice Name"),
              _buildTextField(priceController, "Price per Quintal",
                  keyboardType: TextInputType.number),
              _buildTextField(stockController, "Stock (quintals)",
                  keyboardType: TextInputType.number),
              _buildTextField(imageUrlController, "Image URL (optional)"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              String name = nameController.text.trim();
              double? price = double.tryParse(priceController.text.trim());
              int? stock = int.tryParse(stockController.text.trim());
              String imageUrl = imageUrlController.text.trim();

              if (name.isNotEmpty && price != null && stock != null) {
                if (docId == null) {
                  await _addRiceItem(name, price, stock, imageUrl);
                } else {
                  await _updateRiceItem(docId, name, price, stock, imageUrl);
                }
                Navigator.pop(context);
              }
            },
            child: Text(docId == null ? "Add" : "Update"),
          ),
        ],
      ),
    );
  }

  /// Function to Add a New Rice Item
  Future<void> _addRiceItem(
      String name, double price, int stock, String imageUrl) async {
    await riceCollection.add({
      'name': name,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,  // ✅ Handle optional image URL
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Function to Update an Existing Rice Item
  Future<void> _updateRiceItem(
      String docId, String name, double price, int stock, String imageUrl) async {
    try {
      await riceCollection.doc(docId).update({
        'name': name,
        'price': price,
        'stock': stock,
        'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,  // ✅ Handle optional image URL
        'updatedAt': FieldValue.serverTimestamp(), // ✅ Ensures timestamp updates
      });
      print("Item updated successfully");
    } catch (e) {
      print("Error updating item: $e");
    }
  }

  /// Function to Show a Confirmation Dialog Before Deleting
  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Item?"),
        content: Text("Are you sure you want to delete this rice item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _deleteRiceItem(docId);
              Navigator.pop(context);
            },
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  /// Function to Delete a Rice Item
  Future<void> _deleteRiceItem(String docId) async {
    await riceCollection.doc(docId).delete();
  }

  /// Helper Function to Build Text Fields
  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        keyboardType: keyboardType,
      ),
    );
  }

  /// Placeholder for Missing Images
  Widget _placeholderImage() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey[300],
      child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
    );
  }
}
