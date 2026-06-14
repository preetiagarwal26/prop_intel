class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.authRedirectUrl,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String authRedirectUrl;

  static AppConfig fromEnv(Map<String, String> env) {
    final url = env['SUPABASE_URL'];
    final anonKey = env['SUPABASE_ANON_KEY'];
    final redirectUrl = env['AUTH_REDIRECT_URL'];

    if (url == null || url.isEmpty) {
      throw StateError('SUPABASE_URL is not set in .env');
    }
    if (anonKey == null || anonKey.isEmpty) {
      throw StateError('SUPABASE_ANON_KEY is not set in .env');
    }
    if (redirectUrl == null || redirectUrl.isEmpty) {
      throw StateError('AUTH_REDIRECT_URL is not set in .env');
    }

    return AppConfig(
      supabaseUrl: url,
      supabaseAnonKey: anonKey,
      authRedirectUrl: redirectUrl,
    );
  }
}
