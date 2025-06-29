import 'package:flutter/material.dart';
import 'package:rositas_appk/data/user_data.dart';
import 'package:rositas_appk/models/product.dart';
import 'package:rositas_appk/screens/product_detail_screen.dart';
import 'package:rositas_appk/screens/welcome_screen.dart';
import 'package:rositas_appk/services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<Product>> _productsFuture;
  bool _isLoading = true;
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCartCount();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      _productsFuture = _supabaseService.getProducts().then(
        (list) => list.map((map) => Product.fromMap(map)).toList(),
      );
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCartCount() async {
    try {
      final count = await UserData.getCartItemCount(_supabaseService);
      setState(() => _cartItemCount = count);
    } catch (e) {
      debugPrint('Error loading cart count: $e');
    }
  }

  void _logout(BuildContext context) {
    _supabaseService.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rositas',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.pink[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_cartItemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _navigateTo(context, '/cart'),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildBody(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            text: 'Inicio',
            onTap: () => _navigateTo(context, '/home'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.category,
            text: 'Productos',
            onTap: () => _navigateTo(context, '/products'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.shopping_bag,
            text: 'Mis compras',
            onTap: () => _navigateTo(context, '/orders'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.shopping_cart,
            text: 'Mi carrito',
            badgeCount: _cartItemCount,
            onTap: () => _navigateTo(context, '/cart'),
          ),
          const Divider(thickness: 1),
          _buildDrawerItem(
            context,
            icon: Icons.person,
            text: 'Mi cuenta',
            onTap: () => _navigateTo(context, '/profile'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            text: 'Cerrar sesión',
            onTap: () => _logout(context),
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink[800]!, Colors.pink[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(Icons.chair, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          Text(
            'Rositas Fundas de Muebles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black.withValues(alpha: 0.8),
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Bienvenido/a ${UserData.name.isNotEmpty ? UserData.name.split(' ').first : ''}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isLogout = false,
    int badgeCount = 0,
  }) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.pink[800]),
      title: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: isLogout ? Colors.red : Colors.black,
              fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (badgeCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.pink[800],
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
      hoverColor: Colors.pink[50],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.pink[50]!, Colors.white],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          await _loadProducts();
          await _loadCartCount();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildMainBanner(context)),
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
            SliverToBoxAdapter(child: _buildCategoriesRow()),
            SliverToBoxAdapter(child: const SizedBox(height: 24)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _buildFeaturedProductsSection(),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildSecondaryBanner()),
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainBanner(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80',
          ),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nueva Colección 2023',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black.withValues(alpha: 0.8),
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hasta 30% de descuento en fundas seleccionadas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      blurRadius: 2,
                      color: Colors.black.withValues(alpha: 0.8),
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                ),
                onPressed: () => _navigateTo(context, '/products'),
                child: const Text(
                  'Ver ofertas',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesRow() {
    final categories = [
      {'icon': Icons.chair, 'name': 'Sofás'},
      {'icon': Icons.king_bed, 'name': 'Camas'},
      {'icon': Icons.chair_outlined, 'name': 'Sillas'},
      {'icon': Icons.table_restaurant, 'name': 'Mesas'},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 16 : 8,
              right: index == categories.length - 1 ? 16 : 8,
            ),
            child: InkWell(
              onTap: () => _navigateTo(context, '/products'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      categories[index]['icon'] as IconData,
                      color: Colors.pink[800],
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      categories[index]['name'] as String,
                      style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  SliverList _buildFeaturedProductsSection() {
    return SliverList(
      delegate: SliverChildListDelegate([
        const Text(
          'Productos Destacados',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Lo más popular entre nuestros clientes',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        _buildFeaturedProducts(),
      ]),
    );
  }

  Widget _buildFeaturedProducts() {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Error al cargar productos'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadProducts,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay productos disponibles'));
        }

        final featuredProducts = snapshot.data!.take(4).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: featuredProducts.length,
          itemBuilder: (context, index) {
            return _buildProductItem(featuredProducts[index]);
          },
        );
      },
    );
  }

  Widget _buildProductItem(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(productId: product.id),
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      color: Colors.pink[100],
                      image:
                          product.imageUrl != null
                              ? DecorationImage(
                                image: NetworkImage(product.imageUrl!),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        product.imageUrl == null
                            ? const Center(
                              child: Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            )
                            : null,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.pink,
                          size: 20,
                        ),
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/ ${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _addToCart(product),
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text(
                        'Agregar',
                        style: TextStyle(fontSize: 12),
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

  Widget _buildSecondaryBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.pink[800]!, Colors.pink[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Envío Gratis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'En compras mayores a S/100',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrega en 24-48 horas',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    try {
      await UserData.addToCart(
        product: product,
        quantity: 1,
        supabaseService: _supabaseService,
      );
      await _loadCartCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} agregado al carrito'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al agregar al carrito'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pop(context); // Cierra el drawer primero
    Navigator.pushNamed(context, routeName);
  }
}
