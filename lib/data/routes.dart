// lib/routes.dart
import 'package:flutter/material.dart';
import 'package:rositas_appk/screens/cart_screen.dart';
import 'package:rositas_appk/screens/favorites_screen.dart';
import 'package:rositas_appk/screens/login_screen.dart';
import 'package:rositas_appk/screens/products_screen.dart';
import 'package:rositas_appk/screens/profile_screen.dart';
import 'package:rositas_appk/screens/welcome_screen.dart';
import 'package:rositas_appk/screens/home_screen.dart';
import 'package:rositas_appk/screens/orders_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String welcome = '/';
  static const String products = '/products';
  static const String profile = '/profile';
  static const String orders = '/orders';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
  static const String category = '/category';
  static const String cart = '/cart';
  static const String login = '/login';
  static const String productDetail = '/productDetail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case products:
        return MaterialPageRoute(builder: (_) => const ProductsScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
