import 'package:rositas_appk/models/product.dart';

class CartItem {
  final int id;
  final Product product;
  final int quantity;

  CartItem({required this.id, required this.product, required this.quantity});

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      product: Product.fromMap(map['products']),
      quantity: map['quantity'],
    );
  }
}
