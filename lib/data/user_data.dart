class UserData {
  static String name = '';
  static String email = '';
  static String password = '';
  static List<CartItem> cart = [];
  static List<Order> orders = [];
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

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