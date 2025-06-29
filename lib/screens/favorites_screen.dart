import 'package:flutter/material.dart';
import 'package:rositas_appk/models/product.dart';
import 'package:rositas_appk/screens/product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // Lista de productos favoritos (simulada)
  final List<Product> _favoriteProducts = [
    Product(
      id: '1',
      name: 'Funda para Sofá 3 plazas',
      description: 'Funda resistente y lavable para sofá de 3 plazas',
      price: 59.99,
      imageUrl: 'assets/products/sofa1.jpg',
      category: 'sofas',
    ),
    Product(
      id: '2',
      name: 'Funda para Silla de Comedor',
      description: 'Elegante funda para sillas de comedor',
      price: 19.99,
      imageUrl: 'assets/products/silla1.jpg',
      category: 'sillas',
    ),
  ];

  void _toggleFavorite(Product product) {
    setState(() {
      if (_favoriteProducts.any((p) => p.id == product.id)) {
        _favoriteProducts.removeWhere((p) => p.id == product.id);
      } else {
        _favoriteProducts.add(product);
      }
    });
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis favoritos'),
        backgroundColor: Colors.pink,
      ),
      body:
          _favoriteProducts.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No tienes productos favoritos',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        // Navegar a la pantalla de productos
                        Navigator.pop(context);
                      },
                      child: const Text('Explorar productos'),
                    ),
                  ],
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: _favoriteProducts.length,
                itemBuilder: (context, index) {
                  final product = _favoriteProducts[index];
                  return _buildFavoriteItem(product);
                },
              ),
    );
  }

  Widget _buildFavoriteItem(Product product) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  onTap: () => _navigateToProductDetail(product),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.asset(
                      product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              radius: 16,
              child: IconButton(
                icon: Icon(Icons.favorite, color: Colors.pink, size: 16),
                onPressed: () => _toggleFavorite(product),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
