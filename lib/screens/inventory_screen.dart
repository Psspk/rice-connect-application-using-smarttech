import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../models/rice.dart';
import 'order_screen.dart';

class InventoryScreen extends StatelessWidget {
  final InventoryService _inventoryService = InventoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rice Inventory"),
        backgroundColor: Colors.green,
        centerTitle: true,
        elevation: 2,
      ),
      body: StreamBuilder<List<Rice>>(
        stream: _inventoryService.getRiceInventory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No rice available"));
          }

          List<Rice> riceList = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            itemCount: riceList.length,
            itemBuilder: (context, index) {
              Rice rice = riceList[index];

              return Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (rice.price > 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderScreen(
                            riceName: rice.name,
                            pricePerQuintal: rice.price * 100,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Price not available for this item")),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: (rice.imageUrl.isNotEmpty &&
                              Uri.tryParse(rice.imageUrl)?.hasAbsolutePath == true)
                              ? Image.network(
                            rice.imageUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey[300],
                                child: Icon(Icons.broken_image, color: Colors.red, size: 40),
                              );
                            },
                          )
                              : Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rice.name,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                "₹${rice.price > 0 ? rice.price * 100 : 'N/A'} per quintal",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: rice.price > 0 ? Colors.green[700] : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "Stock: ${rice.stock} quintals",
                                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.green, size: 20),
                      ],
                    ),
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
