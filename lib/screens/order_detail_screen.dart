import 'package:flutter/material.dart';
import 'package:rositas_appk/models/order.dart';
import 'package:rositas_appk/services/supabase_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _order;
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _supabaseService.getUserOrders();
      final updatedOrder = orders.firstWhere(
        (o) => o.id == _order.id,
        orElse: () => _order,
      );
      setState(() => _order = updatedOrder);
    } catch (e) {
      debugPrint('Error loading order details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${_order.id.substring(0, 6)}'),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderStatus(),
                    const SizedBox(height: 24),
                    _buildOrderItems(),
                    const SizedBox(height: 24),
                    _buildOrderSummary(),
                    const SizedBox(height: 24),
                    _buildShippingInfo(),
                  ],
                ),
              ),
    );
  }

  Widget _buildOrderStatus() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado del pedido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _getProgressValue(_order.status),
              backgroundColor: Colors.grey[200],
              color: Colors.pink,
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusStep('Confirmado', _order.status != 'cancelled'),
                _buildStatusStep(
                  'Procesando',
                  _order.status == 'processing' ||
                      _order.status == 'shipped' ||
                      _order.status == 'completed',
                ),
                _buildStatusStep(
                  'Enviado',
                  _order.status == 'shipped' || _order.status == 'completed',
                ),
                _buildStatusStep('Completado', _order.status == 'completed'),
              ],
            ),
            if (_order.status == 'cancelled') ...[
              const SizedBox(height: 16),
              const Text(
                'Pedido cancelado',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep(String label, bool isActive) {
    return Column(
      children: [
        Icon(
          isActive ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isActive ? Colors.pink : Colors.grey,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: isActive ? Colors.pink : Colors.grey),
        ),
      ],
    );
  }

  double _getProgressValue(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return 0.33;
      case 'shipped':
        return 0.66;
      case 'completed':
        return 1.0;
      case 'cancelled':
        return 0.0;
      default:
        return 0.1;
    }
  }

  Widget _buildOrderItems() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Productos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._order.items.map((item) => _buildOrderItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.productImage ?? 'https://via.placeholder.com/80',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.shopping_bag, color: Colors.grey),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'Producto sin nombre',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Cantidad: ${item.quantity}'),
                Text('Precio unitario: S/${item.unitPrice.toStringAsFixed(2)}'),
              ],
            ),
          ),
          Text(
            'S/${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen del pedido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              'Subtotal',
              'S/${_order.totalAmount.toStringAsFixed(2)}',
            ),
            _buildSummaryRow('Envío', 'S/0.00'),
            if (_order.paymentMethod != null) ...[
              _buildSummaryRow(
                'Método de pago',
                _getPaymentMethodText(_order.paymentMethod),
              ),
            ],
            const Divider(),
            _buildSummaryRow(
              'Total',
              'S/${_order.totalAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de envío',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_order.deliveryAddress != null)
              Text('Dirección: ${_order.deliveryAddress}'),
            if (_order.contactPhone != null)
              Text('Teléfono: ${_order.contactPhone}'),
            if (_order.shippingType != null)
              Text(
                'Tipo de envío: ${_getShippingTypeText(_order.shippingType)}',
              ),
          ],
        ),
      ),
    );
  }

  String _getShippingTypeText(String? type) {
    switch (type?.toLowerCase()) {
      case 'delivery':
        return 'Delivery';
      case 'pickup':
        return 'Recojo en tienda';
      default:
        return type ?? 'No especificado';
    }
  }

  String _getPaymentMethodText(String? method) {
    switch (method?.toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      default:
        return method ?? 'No especificado';
    }
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.pink : null,
              fontSize: isTotal ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }
}
