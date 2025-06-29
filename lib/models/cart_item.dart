import 'package:rositas_appk/models/product.dart';

// cart_item_model.dart
class CartItem {
  final String id;
  final Product product;
  final int quantity;

  CartItem({required this.id, required this.product, required this.quantity});

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'].toString(),
      product: Product(
        id: map['product_id'].toString(),
        name: map['products']['name'],
        price: (map['products']['price'] as num).toDouble(),
        imageUrl: map['products']['image_url'],
        category:
            map['products']['category'] != null
                ? Category.fromMap(map['products']['category'])
                : null,
      ),
      quantity: map['quantity'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {'product_id': product.id, 'quantity': quantity};
  }
}
