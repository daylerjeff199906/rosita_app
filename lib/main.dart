import 'package:flutter/material.dart';
import 'package:rositas_appk/config.dart';
import 'package:rositas_appk/screens/auth_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: Config.supabaseUrl,
      anonKey: Config.supabaseKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    runApp(const MyApp()); // Ahora MyApp está definido
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error inicializando Supabase: $e')),
        ),
      ),
    );
  }
}

// Definición de la clase MyApp que faltaba
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rositas App',
      theme: ThemeData(primarySwatch: Colors.pink),
      home: const AuthWrapper(), // Asegúrate de tener esta pantalla definida
    );
  }
}
