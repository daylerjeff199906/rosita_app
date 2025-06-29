import 'package:flutter/material.dart';
import 'package:rositas_appk/data/user_data.dart';
import 'package:rositas_appk/models/product.dart';
import 'package:rositas_appk/screens/cart_screen.dart';
import 'package:rositas_appk/services/supabase_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  Product? _product;
  int _quantity = 1;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    try {
      final data = await _supabaseService.getProductDetails(widget.productId);
      setState(() {
        _product = Product.fromMap(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el producto: $e';
        _isLoading = false;
      });
    }
  }

  void _addToCart() {
    if (_product == null) return;

    // Verificar si la cantidad excede el stock disponible
    if (_quantity > _product!.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No hay suficiente stock disponible (${_product!.stockQuantity} unidades)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final existingItemIndex = UserData.cart.indexWhere(
      (item) => item.product.id == _product!.id,
    );

    if (existingItemIndex >= 0) {
      UserData.cart[existingItemIndex].quantity += _quantity;
    } else {
      UserData.cart.add(CartItem(product: _product!, quantity: _quantity));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_product!.name} agregado al carrito'),
        action: SnackBarAction(
          label: 'Ver carrito',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_product?.name ?? 'Cargando...'),
        backgroundColor: Colors.pink,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(
                        _product!.imageUrl ??
                            'https://via.placeholder.com/300.png?text=Sin+Imagen',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _product!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'S/ ${_product!.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.pink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _product!.description ??
                                'No hay descripción disponible',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Text(
                                'Cantidad:',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (_quantity > 1) {
                                    setState(() => _quantity--);
                                  }
                                },
                              ),
                              Text(
                                '$_quantity',
                                style: const TextStyle(fontSize: 18),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() => _quantity++);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _product!.stockQuantity > 0
                                        ? Colors.pink
                                        : Colors.grey,
                                foregroundColor:
                                    _product!.stockQuantity > 0
                                        ? Colors.white
                                        : Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed:
                                  _product!.stockQuantity > 0
                                      ? _addToCart
                                      : null,
                              child: Text(
                                _product!.stockQuantity > 0
                                    ? 'Agregar al carrito'
                                    : 'Sin stock',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
