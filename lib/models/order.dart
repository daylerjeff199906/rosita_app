import 'package:rositas_appk/models/product.dart';

class Order {
  final String id;
  final String userId;
  final double totalAmount;
  final String status;
  final String? deliveryAddress;
  final String? contactPhone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? paymentMethod;
  final String? shippingType;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.totalAmount,
    this.status = 'pending',
    this.deliveryAddress,
    this.contactPhone,
    required this.createdAt,
    required this.updatedAt,
    this.paymentMethod,
    this.shippingType,
    required this.items,
  });

  factory Order.fromSupabase(
    Map<String, dynamic> data,
    List<Map<String, dynamic>> itemsData,
  ) {
    return Order(
      id: data['id'] ?? '',
      userId: data['user_id'] ?? '',
      totalAmount: (data['total_amount'] as num).toDouble(),
      status: data['status'] ?? 'pending',
      deliveryAddress: data['delivery_address'],
      contactPhone: data['contact_phone'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      paymentMethod: data['payment_method'],
      shippingType: data['shipping_type'],
      items: itemsData.map((item) => OrderItem.fromSupabase(item)).toList(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'total_amount': totalAmount,
      'status': status,
      'delivery_address': deliveryAddress,
      'contact_phone': contactPhone,
      'payment_method': paymentMethod,
      'shipping_type': shippingType,
    };
  }
}

class OrderItem {
  final int? id;
  final String orderId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final DateTime createdAt;
  final String? productName;
  final String? productImage;

  OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.createdAt,
    this.productName,
    this.productImage,
  });

  factory OrderItem.fromSupabase(Map<String, dynamic> data) {
    return OrderItem(
      id: data['id'],
      orderId: data['order_id'] ?? '',
      productId: data['product_id'] ?? '',
      quantity: data['quantity'] ?? 1,
      unitPrice: (data['unit_price'] as num).toDouble(),
      createdAt: DateTime.parse(data['created_at']),
      productName: data['product_name'],
      productImage: data['product_image'],
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'product_name': productName,
      'product_image': productImage,
    };
  }
}

class CartItem {
  final Product product;
  final String id; // Optional ID for the cart item
  int quantity;

  CartItem({required this.product, required this.id, this.quantity = 1});

  double get total => product.price * quantity;

  OrderItem toOrderItem(String orderId) {
    return OrderItem(
      orderId: orderId,
      productId: product.id,
      quantity: quantity,
      unitPrice: product.price,
      createdAt: DateTime.now(),
      productName: product.name,
      productImage: product.imageUrl,
    );
  }

  factory CartItem.fromSupabase(Map<String, dynamic> data) {
    return CartItem(
      id: data['id'] ?? '',
      product: Product.fromMap(data['product']),
      quantity: data['quantity'] ?? 1,
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      product: Product.fromMap(map['product']),
      quantity: map['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {'product_id': product.id, 'quantity': quantity};
  }
}
