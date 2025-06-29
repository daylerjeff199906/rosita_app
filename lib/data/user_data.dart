import 'package:flutter/foundation.dart';
import 'package:rositas_appk/models/order.dart';
import 'package:rositas_appk/models/product.dart';
import 'package:rositas_appk/services/supabase_service.dart';

class UserData {
  static String id = '';
  static String name = '';
  static String email = '';
  static String password = '';
  static String? phone; // Nuevo campo para teléfono
  static String? address; // Nuevo campo para dirección
  static List<CartItem> cart = [];
  static List<Order> orders = [];

  // Métodos para el carrito
  static Future<void> loadCart(SupabaseService supabaseService) async {
    try {
      final userId = supabaseService.getCurrentUserId();
      if (userId == null) {
        cart = [];
        return;
      }

      final cartItems = await supabaseService.getUserCart();
      cart = cartItems;
    } catch (e) {
      debugPrint('Error loading cart: $e');
      cart = [];
    }
  }

  static Future<void> addToCart({
    required Product product,
    required int quantity,
    required SupabaseService supabaseService,
  }) async {
    try {
      // Verificar si el producto ya está en el carrito
      final existingIndex = cart.indexWhere(
        (item) => item.product.id == product.id,
      );

      if (existingIndex >= 0) {
        // Actualizar cantidad si ya existe
        await updateCartItem(
          productId: product.id,
          newQuantity: cart[existingIndex].quantity + quantity,
          supabaseService: supabaseService,
        );
      } else {
        // Agregar nuevo item
        await supabaseService.addToCart(product.id, quantity);
        cart.add(
          CartItem(
            product: product,
            id: '', // ID opcional, puede ser generado por Supabase
            quantity: quantity,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      throw Exception('No se pudo agregar al carrito');
    }
  }

  static Future<void> updateCartItem({
    required String productId,
    required int newQuantity,
    required SupabaseService supabaseService,
  }) async {
    try {
      await supabaseService.updateCartItem(productId, newQuantity);
      final index = cart.indexWhere((item) => item.product.id == productId);
      if (index != -1) {
        cart[index].quantity = newQuantity;
      }
    } catch (e) {
      debugPrint('Error updating cart item: $e');
      throw Exception('No se pudo actualizar el carrito');
    }
  }

  static Future<void> removeFromCart({
    required String productId,
    required SupabaseService supabaseService,
  }) async {
    try {
      await supabaseService.removeFromCart(productId);
      cart.removeWhere((item) => item.product.id == productId);
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      throw Exception('No se pudo eliminar del carrito');
    }
  }

  static Future<void> clearCart(SupabaseService supabaseService) async {
    try {
      await supabaseService.clearUserCart();
      cart.clear();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      throw Exception('No se pudo vaciar el carrito');
    }
  }

  // Métodos para órdenes
  static Future<void> loadOrders(SupabaseService supabaseService) async {
    try {
      orders = await supabaseService.getUserOrders();
    } catch (e) {
      debugPrint('Error loading orders: $e');
      orders = [];
    }
  }

  static Future<Order> createOrder({
    required SupabaseService supabaseService,
    required String userId,
    String? paymentMethod,
    String? shippingType,
    String? specialInstructions,
  }) async {
    try {
      if (cart.isEmpty) throw Exception('El carrito está vacío');
      if (address == null || address!.isEmpty) {
        throw Exception('Dirección requerida');
      }
      if (phone == null || phone!.isEmpty) {
        throw Exception('Teléfono de contacto requerido');
      }

      final cartTotal = cart.fold(
        0.0,
        (sum, item) => sum + (item.product.price * item.quantity),
      );

      final orderResponse =
          await supabaseService.createOrder(
                cartItems: cart.map((item) => item.toSupabase()).toList(),
                totalAmount: cartTotal,
                deliveryAddress: address!,
                contactPhone: phone!,
                paymentMethod: paymentMethod,
                shippingType: shippingType,
              )
              as Map<String, dynamic>?;

      // Add null check for orderResponse and its id
      if (orderResponse == null || orderResponse['id'] == null) {
        throw Exception(
          'La respuesta del servidor no contiene un ID de orden válido',
        );
      }

      await clearCart(supabaseService);

      final now = DateTime.now();
      final newOrder = Order(
        id: orderResponse['id'],
        userId: userId,
        totalAmount: cartTotal,
        status: 'pending',
        deliveryAddress: address!,
        contactPhone: phone!,
        paymentMethod: paymentMethod,
        shippingType: shippingType,
        createdAt: now,
        updatedAt: now,
        items:
            cart
                .map((item) => OrderItem.fromSupabase(item.toSupabase()))
                .toList(),
      );

      orders.add(newOrder);
      return newOrder;
    } catch (e) {
      debugPrint('Error creating order: $e');
      throw Exception('No se pudo crear la orden: ${e.toString()}');
    }
  }

  // Métodos de ayuda
  static int get cartItemCount =>
      cart.fold(0, (sum, item) => sum + item.quantity);

  static double get cartTotal =>
      cart.fold(0.0, (sum, item) => sum + item.total);
}
