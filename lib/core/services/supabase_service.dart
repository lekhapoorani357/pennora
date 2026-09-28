import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';

/// Thin singleton wrapper around [Supabase].
///
/// Call [SupabaseService.instance.init] once during app startup (before
/// [runApp]) to initialise the Supabase connection. After that, use
/// [client] anywhere in the app to reach the Supabase project.
///
/// This service does NOT touch authentication, navigation, or any other
/// existing service - it only establishes the client connection.
class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;

  /// Initialises the Supabase Flutter SDK.
  ///
  /// Safe to call multiple times - subsequent calls are no-ops.
  Future<void> init() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: SupabaseConfig.projectUrl,
      publishableKey: SupabaseConfig.anonKey,
      debug: false,
    );

    _initialized = true;
  }

  /// Returns the active [SupabaseClient].
  ///
  /// Throws a [StateError] if [init] has not been called yet.
  SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'SupabaseService has not been initialised. '
        'Call SupabaseService.instance.init() in main() before using client.',
      );
    }
    return Supabase.instance.client;
  }

  /// True once [init] has completed successfully.
  bool get isInitialized => _initialized;
}