import 'package:flutter/material.dart';
import 'package:rositas_appk/data/user_data.dart';
import 'package:rositas_appk/models/product.dart';
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

  String _paymentMethod = 'credit_card';
  String _shippingType = 'home';
  bool _isLoading = false;
  bool _loadingUserData = true;
  List<CartItem> _cartItems = [];
  Map<String, dynamic>? _userProfile;

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
      // Obtener datos del usuario autenticado
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
          _userProfile = profileResponse;
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
            cartResponse
                .map(
                  (item) => CartItem(
                    product: Product(
                      id: item['products']['id'].toString(),
                      name: item['products']['name'],
                      price: (item['products']['price'] as num).toDouble(),
                      imageUrl: item['products']['image_url'],
                    ),
                    quantity: item['quantity'] as int,
                  ),
                )
                .toList();
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

      // Actualizar dirección del usuario si es diferente
      if (_userProfile?['address'] != _addressController.text ||
          _userProfile?['city'] != _cityController.text ||
          _userProfile?['postal_code'] != _zipController.text ||
          _userProfile?['phone'] != _phoneController.text) {
        await _supabase
            .from('profiles')
            .update({
              'address': _addressController.text,
              'city': _cityController.text,
              'postal_code': _zipController.text,
              'phone': _phoneController.text,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user', userId);
      }

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
      body: SingleChildScrollView(
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Dirección de envío
              _buildSectionTitle('Dirección de envío'),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Por favor ingresa tu dirección'
                            : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Por favor ingresa tu ciudad'
                                  : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _zipController,
                      decoration: const InputDecoration(
                        labelText: 'Código Postal',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.markunread_mailbox),
                      ),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Por favor ingresa tu código postal'
                                  : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono de contacto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator:
                    (value) =>
                        value?.isEmpty ?? true
                            ? 'Por favor ingresa tu teléfono'
                            : null,
              ),
              const SizedBox(height: 12),
              _buildSectionTitle('Tipo de envío'),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Casa'),
                      selected: _shippingType == 'home',
                      onSelected:
                          (selected) => setState(() => _shippingType = 'home'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Oficina'),
                      selected: _shippingType == 'office',
                      onSelected:
                          (selected) =>
                              setState(() => _shippingType = 'office'),
                    ),
                  ),
                ],
              ),

              // Método de pago
              _buildSectionTitle('Método de pago'),
              Column(
                children: [
                  RadioListTile(
                    title: const Text('Tarjeta de crédito/débito'),
                    value: 'credit_card',
                    groupValue: _paymentMethod,
                    onChanged:
                        (value) =>
                            setState(() => _paymentMethod = value.toString()),
                  ),
                  RadioListTile(
                    title: const Text('Transferencia bancaria'),
                    value: 'bank_transfer',
                    groupValue: _paymentMethod,
                    onChanged:
                        (value) =>
                            setState(() => _paymentMethod = value.toString()),
                  ),
                ],
              ),

              if (_paymentMethod == 'credit_card') ...[
                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Número de tarjeta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true)
                      return 'Ingresa el número de tarjeta';
                    if (value!.length < 16) return 'Debe tener 16 dígitos';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cardNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre en la tarjeta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator:
                      (value) =>
                          value?.isEmpty ?? true
                              ? 'Ingresa el nombre en la tarjeta'
                              : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryController,
                        decoration: const InputDecoration(
                          labelText: 'MM/AA',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Ingresa la fecha de expiración'
                                    : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Ingresa el CVV';
                          if (value!.length < 3) return 'Debe tener 3 dígitos';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _placeOrder,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Confirmar pedido',
                            style: TextStyle(fontSize: 18),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
