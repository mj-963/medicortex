/// Platform-specific environment access for web
/// Web doesn't support runtime environment variables
class PlatformEnv {
  static String? getEnv(String key) {
    // Web doesn't support Platform.environment
    // Return null to fall back to String.fromEnvironment
    return null;
  }
}
