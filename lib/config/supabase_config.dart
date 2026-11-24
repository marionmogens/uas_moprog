class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://emctxybmfufmqhrvfhjd.supabase.co';
  static const String publishableKey = 'sb_publishable_7NuLpuzM0jkSqfxq9CyfjA_gvssp5uy';

  static String get authUrl => '$url/auth/v1';
  static String get restUrl => '$url/rest/v1';
}