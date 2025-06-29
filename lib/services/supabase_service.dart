import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

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

  Future<void> addToCart(int productId, int quantity) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('cart_items').upsert({
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
    });
  }

  Future<void> removeFromCart(int cartItemId) async {
    await _supabase.from('cart_items').delete().eq('id', cartItemId);
  }

  // Órdenes
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('orders')
        .select('''
          id,
          total_amount,
          status,
          created_at,
          order_items:order_items (quantity, products:products (name, price, image_url))
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createOrder(List<Map<String, dynamic>> cartItems) async {
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
}
