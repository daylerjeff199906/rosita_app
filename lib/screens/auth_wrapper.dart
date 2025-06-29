import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rositas_appk/screens/login_screen.dart';
import 'package:rositas_appk/screens/home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _supabase = Supabase.instance.client;
  late StreamSubscription<AuthState>? _authSubscription;
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Verificar sesión existente inmediatamente
      final initialSession = _supabase.auth.currentSession;
      debugPrint(
        'Sesión inicial: ${initialSession?.user.email ?? "No autenticado"}',
      );

      // Configurar listener para cambios de autenticación
      _authSubscription = _supabase.auth.onAuthStateChange.listen((event) {
        debugPrint('Cambio en estado de autenticación: ${event.event}');
        if (mounted) {
          setState(() => _isInitializing = false);
        }
      });

      // Timeout para evitar pantalla de carga infinita
      await Future.delayed(const Duration(seconds: 3));
      if (mounted && _isInitializing) {
        setState(() => _isInitializing = false);
      }
    } catch (e, stackTrace) {
      debugPrint('Error en AuthWrapper: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
          _errorMessage = 'Error de conexión. Reintentar?';
        });
      }
    }
  }

  void _retryInitialization() {
    if (mounted) {
      setState(() {
        _isInitializing = true;
        _hasError = false;
      });
      _initializeAuth();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga
    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    // Pantalla de error
    if (_hasError) {
      return _buildErrorScreen();
    }

    // Redirigir según estado de autenticación
    print('Estado de autenticación: ${_supabase.auth.currentSession?.user.email ?? "No autenticado"}');
    debugPrint(
      'Redirigiendo a ${_supabase.auth.currentSession == null ? "LoginScreen" : "HomeScreen"}',
    );
    return _supabase.auth.currentSession == null
        ? const LoginScreen()
        : const HomeScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Cargando Rositas App...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'Error desconocido',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _retryInitialization,
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
