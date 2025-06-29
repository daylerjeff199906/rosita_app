class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(id: map['id'].toString(), name: map['name']);
  }
}

class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final Category? category; // Cambiado de String? a Category?
  final String? imageUrl;
  final int stockQuantity;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.imageUrl,
    this.stockQuantity = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'].toString(),
      name: map['name'],
      description: map['description'],
      price: (map['price'] as num).toDouble(),
      category:
          map['category'] != null
              ? (map['category'] is Map
                  ? Category.fromMap(map['category'])
                  : Category(id: map['category'].toString(), name: ''))
              : null,
      imageUrl: map['image_url'],
      stockQuantity: map['stock_quantity'] ?? 0,
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
