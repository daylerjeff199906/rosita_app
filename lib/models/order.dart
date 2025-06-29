class OrderItem {
  final String productName;
  final double unitPrice;
  final int quantity;

  OrderItem({
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });
}

class Order {
  final String id;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      totalAmount: (map['total_amount'] as num).toDouble(),
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
      items:
          List<Map<String, dynamic>>.from(map['order_items'])
              .map(
                (item) => OrderItem(
                  productName: item['products']['name'],
                  unitPrice: (item['products']['price'] as num).toDouble(),
                  quantity: item['quantity'],
                ),
              )
              .toList(),
    );
  }
}
