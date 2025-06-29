import 'package:flutter/material.dart';
import 'package:rositas_appk/models/order.dart';
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
  final _specialInstructionsController = TextEditingController();

  String _paymentMethod = 'credit_card';
  String _shippingType = 'home_delivery';
  bool _isLoading = false;
  bool _loadingUserData = true;
  List<CartItem> _cartItems = [];

  final _supabase = Supabase.instance.client;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'value': 'credit_card',
      'label': 'Tarjeta de Crédito',
      'icon': Icons.credit_card,
    },
    {
      'value': 'debit_card',
      'label': 'Tarjeta de Débito',
      'icon': Icons.credit_card,
    },
    {'value': 'cash', 'label': 'Efectivo al recibir', 'icon': Icons.money},
    {
      'value': 'bank_transfer',
      'label': 'Transferencia Bancaria',
      'icon': Icons.account_balance,
    },
  ];

  final List<Map<String, dynamic>> _shippingOptions = [
    {'value': 'home_delivery', 'label': 'Envío a domicilio'},
    {'value': 'pickup', 'label': 'Recojo en tienda'},
    {'value': 'express', 'label': 'Envío express (24h)'},
  ];

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
    _specialInstructionsController.dispose();
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
          .select('*, product:products(*, category:categories(*))')
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
            'special_instructions':
                _specialInstructionsController.text.isNotEmpty
                    ? _specialInstructionsController.text
                    : null,
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
          'product_name': item.product.name,
          'product_image': item.product.imageUrl,
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
        SnackBar(
          content: Text('Error al procesar el pedido: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
        backgroundColor: Colors.pink[800],
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
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumen del pedido',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._cartItems.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[200],
                                      child:
                                          item.product.imageUrl != null
                                              ? Image.network(
                                                item.product.imageUrl!,
                                                fit: BoxFit.cover,
                                              )
                                              : const Icon(Icons.image),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Cantidad: ${item.quantity}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'S/${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'S/${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
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

                  const SizedBox(height: 24),

                  // Información de envío
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información de envío',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildShippingTypeSelector(),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Dirección',
                              prefixIcon: Icon(Icons.home),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese su dirección';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Ciudad',
                                    prefixIcon: Icon(Icons.location_city),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese su ciudad';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _zipController,
                                  decoration: const InputDecoration(
                                    labelText: 'Código Postal',
                                    prefixIcon: Icon(Icons.markunread_mailbox),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese su código postal';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono de contacto',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese su teléfono';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _specialInstructionsController,
                            decoration: const InputDecoration(
                              labelText: 'Instrucciones especiales (opcional)',
                              prefixIcon: Icon(Icons.note),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Método de pago
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Método de pago',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildPaymentMethodSelector(),
                          const SizedBox(height: 16),
                          if (_paymentMethod == 'credit_card' ||
                              _paymentMethod == 'debit_card')
                            Column(
                              children: [
                                TextFormField(
                                  controller: _cardNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'Número de tarjeta',
                                    prefixIcon: Icon(Icons.credit_card),
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if ((_paymentMethod == 'credit_card' ||
                                            _paymentMethod == 'debit_card') &&
                                        (value == null || value.isEmpty)) {
                                      return 'Por favor ingrese el número de tarjeta';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _cardNameController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nombre en la tarjeta',
                                          prefixIcon: Icon(Icons.person),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if ((_paymentMethod ==
                                                      'credit_card' ||
                                                  _paymentMethod ==
                                                      'debit_card') &&
                                              (value == null ||
                                                  value.isEmpty)) {
                                            return 'Por favor ingrese el nombre';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _expiryController,
                                        decoration: const InputDecoration(
                                          labelText: 'MM/AA',
                                          prefixIcon: Icon(
                                            Icons.calendar_today,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if ((_paymentMethod ==
                                                      'credit_card' ||
                                                  _paymentMethod ==
                                                      'debit_card') &&
                                              (value == null ||
                                                  value.isEmpty)) {
                                            return 'Por favor ingrese la fecha';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _cvvController,
                                        decoration: const InputDecoration(
                                          labelText: 'CVV',
                                          prefixIcon: Icon(Icons.lock),
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        obscureText: true,
                                        validator: (value) {
                                          if ((_paymentMethod ==
                                                      'credit_card' ||
                                                  _paymentMethod ==
                                                      'debit_card') &&
                                              (value == null ||
                                                  value.isEmpty)) {
                                            return 'Por favor ingrese el CVV';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón de confirmación
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                              : const Text(
                                'CONFIRMAR COMPRA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      children:
          _paymentMethods.map((method) {
            return RadioListTile<String>(
              title: Row(
                children: [
                  Icon(method['icon'] as IconData, color: Colors.pink[800]),
                  const SizedBox(width: 8),
                  Text(method['label'] as String),
                ],
              ),
              value: method['value'] as String,
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
              activeColor: Colors.pink[800],
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
    );
  }

  Widget _buildShippingTypeSelector() {
    return Column(
      children:
          _shippingOptions.map((option) {
            return RadioListTile<String>(
              title: Text(option['label'] as String),
              value: option['value'] as String,
              groupValue: _shippingType,
              onChanged: (value) {
                setState(() {
                  _shippingType = value!;
                });
              },
              activeColor: Colors.pink[800],
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
    );
  }
}
