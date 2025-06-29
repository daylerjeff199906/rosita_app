import 'dart:async'; // Añade esta importación
import 'package:flutter/material.dart';
import 'package:rositas_appk/screens/home_screen.dart';
import 'package:rositas_appk/screens/login_screen.dart';
import 'package:rositas_appk/screens/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _supabase = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSubscription; // Ahora StreamSubscription será reconocido
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authSubscription = _supabase.auth.onAuthStateChange.listen((event) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    // Verificar sesión existente después de un breve retraso
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _supabase.auth.currentSession == null
        ? const LoginScreen()
        : const HomeScreen();
  }
}