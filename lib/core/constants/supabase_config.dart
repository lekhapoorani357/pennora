/// Supabase project credentials.
///
/// Keep this file out of public version control.
/// In production, load these from environment variables or a secrets manager.
class SupabaseConfig {
  SupabaseConfig._();

  static const String projectUrl = 'https://jwbunowmydtxhkgbcvdb.supabase.co';

  /// Publishable (anon) key — safe to ship in client code.
  static const String anonKey =
      'sb_publishable_ZB9TGgqqmk8dwMW0beBg4Q_Tv4b2VMi';
}