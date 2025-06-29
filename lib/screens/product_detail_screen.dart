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
  bool _isAddingToCart = false;

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

  Future<void> _addToCart() async {
    if (_product == null) return;

    setState(() => _isAddingToCart = true);

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
      setState(() => _isAddingToCart = false);
      return;
    }

    try {
      // Verificar si el producto ya está en el carrito del usuario en Supabase
      final existingCartItem = await _supabaseService.getCartItem(_product!.id);

      if (existingCartItem != null) {
        // Actualizar cantidad si ya existe
        await _supabaseService.updateCartItemQuantity(
          existingCartItem.id,
          existingCartItem.quantity + _quantity,
        );
      } else {
        // Agregar nuevo item al carrito
        await _supabaseService.addToCart(_product!.id, _quantity);
      }

      // Actualizar el carrito en memoria
      await UserData.loadCart(_supabaseService);

      // Pequeña animación de éxito
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_product!.name} agregado al carrito'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Ver carrito',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar al carrito: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isAddingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _product?.name ?? 'Cargando...',
          style: const TextStyle(color: Colors.white), // Texto blanco
        ),
        backgroundColor: Colors.pink,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Iconos blancos
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchProduct,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección de imagen
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Image.network(
                            _product!.imageUrl ??
                                'https://via.placeholder.com/300.png?text=Sin+Imagen',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 100,
                                  ),
                                ),
                          ),
                        ),
                        if (_product!.stockQuantity <= 0)
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'AGOTADO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Sección de información
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Categoría
                          if (_product!.category != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.pink.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _product!.category!.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                          // Nombre y precio
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _product!.name,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                'S/ ${_product!.price.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.pink,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          // Stock disponible
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              _product!.stockQuantity > 0
                                  ? '${_product!.stockQuantity} unidades disponibles'
                                  : 'Producto agotado',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    _product!.stockQuantity > 0
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          ),

                          const Divider(height: 24),

                          // Descripción
                          Text(
                            'Descripción',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _product!.description ??
                                'No hay descripción disponible',
                            style: theme.textTheme.bodyMedium,
                          ),

                          const Divider(height: 32),

                          // Selector de cantidad
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cantidad:',
                                style: theme.textTheme.titleMedium,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        if (_quantity > 1) {
                                          setState(() => _quantity--);
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Center(
                                        child: Text(
                                          '$_quantity',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        setState(() => _quantity++);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Botón de agregar al carrito - VERSIÓN MEJORADA
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black, // Fondo negro
                                foregroundColor: Colors.white, // Texto blanco
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed:
                                  _product!.stockQuantity > 0 &&
                                          !_isAddingToCart
                                      ? _addToCart
                                      : null,
                              child:
                                  _isAddingToCart
                                      ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                      : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons
                                                .add_shopping_cart, // Icono de carrito
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _product!.stockQuantity > 0
                                                ? 'Añadir al carrito'
                                                : 'Sin stock',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(color: Colors.white),
                                          ),
                                        ],
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
