import 'package:rositas_appk/models/product.dart';

class UserData {
  static String name = '';
  static String email = '';
  static String password = '';
  static List<CartItem> cart = [];
  static List<Order> orders = [];
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

class Order {
  final String id;
  final DateTime date;
  final List<CartItem> items;
  final double total;
  final String status;

  Order({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    this.status = 'Procesando',
  });
}
