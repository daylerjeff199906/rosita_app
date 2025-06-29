// checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:rositas_appk/data/user_data.dart';
import 'package:rositas_appk/screens/order_confirmation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _phoneController = TextEditingController();

  final String _paymentMethod = 'credit_card';
  final String _shippingType = 'home';
  bool _isLoading = false;
  bool _loadingUserData = true;
  List<CartItem> _cartItems = [];

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndCart();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDataAndCart() async {
    setState(() => _loadingUserData = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Obtener perfil del usuario
      final profileResponse =
          await _supabase
              .from('profiles')
              .select()
              .eq('user', userId)
              .maybeSingle();

      if (profileResponse != null) {
        setState(() {
          _phoneController.text = profileResponse['phone'] ?? '';
          _addressController.text = profileResponse['address'] ?? '';
          _cityController.text = profileResponse['city'] ?? '';
          _zipController.text = profileResponse['postal_code'] ?? '';
        });
      }

      // Obtener carrito desde Supabase
      final cartResponse = await _supabase
          .from('cart_items')
          .select('*, products(*)')
          .eq('user_id', userId);

      setState(() {
        _cartItems =
            cartResponse.map((item) => CartItem.fromMap(item)).toList();
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() => _loadingUserData = false);
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final deliveryAddress =
          '${_addressController.text}, ${_cityController.text}, ${_zipController.text}';

      final totalAmount = _cartItems.fold(
        0.0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );

      // Crear la orden en Supabase
      final orderResponse =
          await _supabase.from('orders').insert({
            'user_id': userId,
            'total_amount': totalAmount,
            'delivery_address': deliveryAddress,
            'contact_phone': _phoneController.text,
            'payment_method': _paymentMethod,
            'shipping_type': _shippingType,
            'status': 'pending',
          }).select();

      if (orderResponse.isEmpty) throw Exception('Failed to create order');

      final orderId = orderResponse.first['id'] as String;

      // Crear los items de la orden
      for (final item in _cartItems) {
        await _supabase.from('order_items').insert({
          'order_id': orderId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.product.price,
        });
      }

      // Limpiar el carrito
      await _supabase.from('cart_items').delete().eq('user_id', userId);

      // Navegar a la pantalla de confirmación
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => OrderConfirmationScreen(
                orderId: orderId,
                total: totalAmount,
                deliveryAddress: deliveryAddress,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar el pedido: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _cartItems.fold(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );

    if (_loadingUserData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Finalizar compra',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.pink,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resumen de productos
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumen del pedido',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._cartItems.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.product.name} x${item.quantity}',
                                    ),
                                  ),
                                  Text(
                                    '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          Row(
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                '\$${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Resto del formulario de checkout...
                  // (Mantener el mismo código para los campos de dirección, pago, etc.)
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Realizar pedido'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
