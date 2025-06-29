import 'package:flutter/material.dart';
import 'package:rositas_appk/data/user_data.dart';
import 'package:rositas_appk/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double get _totalPrice {
    return UserData.cart.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  double get _discount => 0; // Cambiado a 0 como solicitaste
  double get _deliveryFee => 0;

  double get _subTotal => _totalPrice - _discount + _deliveryFee;

  void _removeItem(int index) {
    setState(() {
      UserData.cart.removeAt(index);
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        UserData.cart[index].quantity = newQuantity;
      });
    } else {
      _removeItem(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Carrito de compras',
          style: TextStyle(color: Colors.white), // Texto blanco
        ),
        backgroundColor: Colors.pink,
        iconTheme: const IconThemeData(color: Colors.white), // Iconos blancos
      ),
      body:
          UserData.cart.isEmpty
              ? const Center(child: Text('Tu carrito está vacío'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: UserData.cart.length,
                      itemBuilder: (context, index) {
                        final item = UserData.cart[index];
                        return _buildCartItem(item, index);
                      },
                    ),
                  ),
                  _buildTotalSection(),
                ],
              ),
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.product.imageUrl ??
                    'https://via.placeholder.com/80x80.png?text=Sin+Imagen',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría (nuevo)
                  if (item.product.category != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.product.category!.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/ ${item.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.pink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: S/ ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed:
                          () => _updateQuantity(index, item.quantity - 1),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed:
                          () => _updateQuantity(index, item.quantity + 1),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildTotalRow('Total', _totalPrice),
          const SizedBox(height: 4),
          // Solo mostramos descuento si es mayor a 0
          if (_discount > 0) ...[
            _buildTotalRow('Descuento', -_discount),
            const SizedBox(height: 4),
          ],
          _buildTotalRow('Delivery', _deliveryFee),
          const Divider(height: 20, thickness: 1),
          _buildTotalRow(
            'Sub Total',
            _subTotal,
            bold: true,
            color: Colors.pink,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Cambiado a negro
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_checkout, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Continuar (S/ ${_subTotal.toStringAsFixed(2)})',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool bold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${amount < 0 ? '-' : ''}S/ ${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
