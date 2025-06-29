// lib/config/config.dart
import 'package:flutter/foundation.dart';

class Config {
  // Para desarrollo local (usando .env en mobile/desktop)
  static const String _devSupabaseUrl = 'https://qhgmwpprshtymhnzdocu.supabase.co';
  static const String _devSupabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFoZ213cHByc2h0eW1obnpkb2N1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExNDI4MzgsImV4cCI6MjA2NjcxODgzOH0.W0Hvrce2rvtFAcmxNr9pUs6LSBT6zTvro1fv0FzO5sw';

  // Para producción web (usar --dart-define en compilación)
  static const String _prodSupabaseUrl = 'https://qhgmwpprshtymhnzdocu.supabase.co';
  static const String _prodSupabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFoZ213cHByc2h0eW1obnpkb2N1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExNDI4MzgsImV4cCI6MjA2NjcxODgzOH0.W0Hvrce2rvtFAcmxNr9pUs6LSBT6zTvro1fv0FzO5sw';

  // Métodos seguros para obtener las configuraciones
  static String get supabaseUrl {
    if (kIsWeb) {
      return const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: _prodSupabaseUrl,
      );
    }
    return _devSupabaseUrl; // En mobile/desktop usa .env preferiblemente
  }

  static String get supabaseKey {
    if (kIsWeb) {
      return const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: _prodSupabaseKey,
      );
    }
    return _devSupabaseKey;
  }
}
