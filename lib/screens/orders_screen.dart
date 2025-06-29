import 'package:flutter/material.dart';
import 'package:rositas_appk/data/user_data.dart';
import 'package:rositas_appk/models/order.dart';
import 'package:rositas_appk/screens/order_detail_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        backgroundColor: Colors.pink,
      ),
      body:
          UserData.orders.isEmpty
              ? const Center(child: Text('No tienes pedidos realizados'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: UserData.orders.length,
                itemBuilder: (context, index) {
                  final order = UserData.orders[index];
                  return _buildOrderCard(context, order);
                },
              ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                      order.status,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                // Cambia 'order.date' por el nombre correcto de la propiedad de fecha en tu modelo Order
                'Fecha: ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
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
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'procesando':
        return Colors.orange;
      case 'enviado':
        return Colors.blue;
      case 'completado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
