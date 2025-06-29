import 'package:flutter/material.dart';
import 'package:rositas_appk/models/order.dart';
import 'package:rositas_appk/screens/order_detail_screen.dart';
import 'package:rositas_appk/services/supabase_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Order>> _ordersFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<Order>> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      return await _supabaseService.getUserOrders();
    } catch (e) {
      debugPrint('Error loading orders: $e');
      return [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes pedidos realizados'));
          }

          final orders = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshOrders,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCard(context, order);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${order.id.substring(0, 6)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Chip(
                    backgroundColor: _getStatusColor(order.status),
                    label: Text(
                      _getStatusText(order.status),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Fecha: ${_formatDate(order.createdAt)}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                '${order.items.length} ${order.items.length == 1 ? 'producto' : 'productos'}',
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'S/${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (order.paymentMethod != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Método de pago: ${_getPaymentMethodText(order.paymentMethod)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendiente';
      case 'processing':
        return 'Procesando';
      case 'shipped':
        return 'Enviado';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
