import 'package:flutter/material.dart';
import 'package:rositas_appk/data/user_data.dart';
import 'package:rositas_appk/screens/product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String category;
  
  const ProductsScreen({super.key, this.category = 'todos'});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final List<Product> _products = [
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
    Product(
      id: '3',
      name: 'Funda para Cama Matrimonial',
      description: 'Juego de fundas para cama matrimonial',
      price: 89.99,
      imageUrl: 'assets/products/cama1.jpg',
      category: 'camas',
    ),
    Product(
      id: '4',
      name: 'Funda para Sofá 2 plazas',
      description: 'Funda moderna para sofá de 2 plazas',
      price: 49.99,
      imageUrl: 'assets/products/sofa2.jpg',
      category: 'sofas',
    ),
  ];

  List<Product> get _filteredProducts {
    if (widget.category == 'todos') return _products;
    return _products.where((p) => p.category == widget.category).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryTitle()),
        backgroundColor: Colors.pink,
      ),
      body: _filteredProducts.isEmpty
          ? const Center(child: Text('No hay productos en esta categoría'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return _buildProductCard(context, product);
              },
            ),
    );
  }

  String _getCategoryTitle() {
    switch (widget.category) {
      case 'sofas': return 'Fundas para Sofás';
      case 'sillas': return 'Fundas para Sillas';
      case 'camas': return 'Fundas para Camas';
      default: return 'Todos los Productos';
    }
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
                child: Image.asset(
                  product.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
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
      ),
    );
  }
}