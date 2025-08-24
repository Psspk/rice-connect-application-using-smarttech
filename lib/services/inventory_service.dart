import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rice.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Fetch rice inventory
  Stream<List<Rice>> getRiceInventory() {
    return _firestore.collection('inventory').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          print("Fetched data: $data"); // Debugging print
          return Rice.fromMap(data);
        } catch (e) {
          print("Error parsing rice item: $e");
          return Rice(name: "Unknown", price: 0.0, stock: 0, imageUrl: "");
        }
      }).toList();
    });
  }
}
