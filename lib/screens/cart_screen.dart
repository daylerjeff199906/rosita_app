// cart_screen.dart
import 'package:flutter/material.dart';
import 'package:rositas_appk/models/cart_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rositas_appk/screens/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _supabase = Supabase.instance.client;
  List<CartItem> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('cart_items')
          .select('*, products(*, category:categories(*))')
          .eq('user_id', userId);

      setState(() {
        _cartItems = response.map((item) => CartItem.fromMap(item)).toList();
      });
    } catch (e) {
      debugPrint('Error loading cart: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCartItemQuantity(
    String cartItemId,
    int newQuantity,
  ) async {
    if (newQuantity <= 0) {
      await _removeCartItem(cartItemId);
      return;
    }

    try {
      await _supabase
          .from('cart_items')
          .update({'quantity': newQuantity})
          .eq('id', cartItemId);

      await _loadCartItems();
    } catch (e) {
      debugPrint('Error updating cart item: $e');
    }
  }

  Future<void> _removeCartItem(String cartItemId) async {
    try {
      await _supabase.from('cart_items').delete().eq('id', cartItemId);

      await _loadCartItems();
    } catch (e) {
      debugPrint('Error removing cart item: $e');
    }
  }

  double get _totalPrice {
    return _cartItems.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  double get _discount => 0;
  double get _deliveryFee => 0;
  double get _subTotal => _totalPrice - _discount + _deliveryFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Carrito de compras',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.pink,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _cartItems.isEmpty
              ? const Center(child: Text('Tu carrito está vacío'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
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
                          () => _updateCartItemQuantity(
                            item.id,
                            item.quantity - 1,
                          ),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed:
                          () => _updateCartItemQuantity(
                            item.id,
                            item.quantity + 1,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeCartItem(item.id),
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
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed:
                  _cartItems.isEmpty
                      ? null
                      : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckoutScreen(),
                          ),
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
