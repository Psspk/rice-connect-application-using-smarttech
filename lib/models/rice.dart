class Rice {
  final String name;
  final double price;
  final int stock;
  final String imageUrl;

  Rice({
    required this.name,
    required this.price,
    required this.stock,
    required this.imageUrl,
  });

  // ✅ Convert Firestore data to a Rice object
  factory Rice.fromMap(Map<String, dynamic> map) {
    return Rice(
      name: map['name'] ?? 'Unknown',
      price: (map['price'] ?? 0).toDouble(),
      stock: (map['stock'] ?? 0).toInt(),
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
