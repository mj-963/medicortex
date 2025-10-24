import 'dart:io' show Platform;

/// Platform-specific environment access for native platforms (IO)
class PlatformEnv {
  static String? getEnv(String key) {
    return Platform.environment[key];
  }
}
