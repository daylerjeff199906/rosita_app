class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String? productImage;
  final double unitPrice;
  final int quantity;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.unitPrice,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'].toString(),
      productId: map['product_id'].toString(),
      productName:
          map['product_name'] ??
          map['products']['name'] ??
          'Producto desconocido',
      productImage: map['product_image'] ?? map['products']['image_url'],
      unitPrice: (map['unit_price'] as num).toDouble(),
      quantity: map['quantity'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      if (productImage != null) 'product_image': productImage,
    };
  }
}

class Order {
  final String id;
  final String userId;
  final double totalAmount;
  final String status;
  final String deliveryAddress;
  final String? contactPhone;
  final String? paymentMethod;
  final String? shippingType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    this.contactPhone,
    this.paymentMethod,
    this.shippingType,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  String get formattedDate =>
      '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  String get formattedTime =>
      '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      status: map['status'] ?? 'pending',
      deliveryAddress: map['delivery_address'] ?? '',
      contactPhone: map['contact_phone'],
      paymentMethod: map['payment_method'],
      shippingType: map['shipping_type'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      items:
          map['order_items'] != null
              ? List<Map<String, dynamic>>.from(
                map['order_items'],
              ).map((item) => OrderItem.fromMap(item)).toList()
              : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'total_amount': totalAmount,
      'status': status,
      'delivery_address': deliveryAddress,
      'contact_phone': contactPhone,
      'payment_method': paymentMethod,
      'shipping_type': shippingType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'order_items': items.map((item) => item.toMap()).toList(),
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    double? totalAmount,
    String? status,
    String? deliveryAddress,
    String? contactPhone,
    String? paymentMethod,
    String? shippingType,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      contactPhone: contactPhone ?? this.contactPhone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shippingType: shippingType ?? this.shippingType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}
