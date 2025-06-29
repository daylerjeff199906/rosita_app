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
      data: {
        'full_name': name,
        'email': email,
      },
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

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

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
        .uploadBinary(fileName, fileBytes, fileOptions: FileOptions(
          contentType: 'image/$fileExtension',
          upsert: true,
        ));

    return _storage.from('avatars').getPublicUrl(fileName);
  }
}