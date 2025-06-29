import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rositas_appk/models/order.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();
  String? getCurrentUserId() => _supabase.auth.currentUser?.id;

  final _supabase = Supabase.instance.client;
  final _storage = Supabase.instance.client.storage;

  // Auth Methods
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name, 'email': email},
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Profile Methods
  Future<Map<String, dynamic>?> getUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response =
        await _supabase.from('profiles').select().eq('id', userId).single();

    return response;
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? address,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('profiles').upsert({
      'id': userId,
      'full_name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Avatar Methods
  Future<String?> uploadAvatar(XFile imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final fileExtension = imageFile.path.split('.').last;
    final fileName = 'avatar_$userId.$fileExtension';
    final fileBytes = await imageFile.readAsBytes();

    await _storage
        .from('avatars')
        .uploadBinary(
          fileName,
          fileBytes,
          fileOptions: FileOptions(
            contentType: 'image/$fileExtension',
            upsert: true,
          ),
        );

    return _storage.from('avatars').getPublicUrl(fileName);
  }

  // Productos
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, category:categories (id, name)')
          .eq('is_active', true);

      debugPrint('Response function: ${response.length} productos obtenidos');
      debugPrint(
        'Primer producto: ${response.isNotEmpty ? response[0] : 'vacío'}',
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error en getProducts: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProductDetails(String productId) async {
    final response =
        await _supabase
            .from('products')
            .select('*, category:categories (id, name)')
            .eq('id', productId)
            .single();

    return response;
  }

  // Carrito
  // Método para obtener un item del carrito por product_id
  Future<CartItem?> getCartItem(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response =
        await _supabase
            .from('cart_items')
            .select('*, products(*)')
            .eq('user_id', userId)
            .eq('product_id', productId)
            .maybeSingle();

    return response == null ? null : CartItem.fromMap(response);
  }

  // Método para actualizar la cantidad de un item del carrito
  Future<void> updateCartItemQuantity(
    String cartItemId,
    int newQuantity,
  ) async {
    await _supabase
        .from('cart_items')
        .update({'quantity': newQuantity})
        .eq('id', cartItemId);
  }

  // Método para obtener todos los items del carrito del usuario
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('cart_items')
        .select('''
          id, 
          quantity, 
          products (id, name, price, image_url)
        ''')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  // Método para agregar un nuevo item al carrito
  Future<void> addToCart(String productId, int quantity) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('cart_items').upsert({
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
    });
  }

  // Método para eliminar un item del carrito
  Future<void> removeFromCart(String cartItemId) async {
    await _supabase.from('cart_items').delete().eq('id', cartItemId);
  }

  // Órdenes
  Future<List<Order>> getUserOrders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('orders')
        .select('''
        *,
        order_items:order_items(
          *,
          product:products(*)
        )
      ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response
        .map<Order>(
          (orderData) => Order.fromSupabase(
            orderData,
            orderData['order_items'] as List<Map<String, dynamic>>,
          ),
        )
        .toList();
  }

  Future<void> createOrder({
    required List<Map<String, dynamic>> cartItems,
    required double totalAmount,
    required String deliveryAddress,
    required String contactPhone,
    String? paymentMethod,
    String? shippingType,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final total = cartItems.fold(0.0, (sum, item) {
      return sum + (item['products']['price'] * item['quantity']);
    });

    final orderResponse =
        await _supabase
            .from('orders')
            .insert({
              'user_id': userId,
              'total_amount': total,
              'delivery_address': deliveryAddress,
              'contact_phone': contactPhone,
              'payment_method': paymentMethod,
              'shipping_type': shippingType,
              'status': 'pending',
            })
            .select()
            .single();

    final orderId = orderResponse['id'];

    for (final item in cartItems) {
      await _supabase.from('order_items').insert({
        'order_id': orderId,
        'product_id': item['products']['id'],
        'quantity': item['quantity'],
        'unit_price': item['products']['price'],
      });
    }

    // Limpiar carrito
    await _supabase.from('cart_items').delete().eq('user_id', userId);
  }

  //News functions
  Future<List<CartItem>> getUserCart() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    final response = await _supabase
        .from('cart_items')
        .select('*, product:products(*)')
        .eq('user_id', userId);

    return response
        .map<CartItem>((item) => CartItem.fromSupabase(item))
        .toList();
  }

  Future<void> updateCartItem(String productId, int newQuantity) async {
    final userId = getCurrentUserId();
    if (userId == null) throw Exception('Usuario no autenticado');

    await _supabase
        .from('cart_items')
        .update({'quantity': newQuantity})
        .eq('product_id', productId)
        .eq('user_id', userId);
  }

  Future<void> clearUserCart() async {
    final userId = getCurrentUserId();
    if (userId == null) return;

    await _supabase.from('cart_items').delete().eq('user_id', userId);
  }
}
