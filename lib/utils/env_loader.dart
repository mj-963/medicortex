import 'dart:convert';

// Conditional import: uses env_loader_io.dart on native platforms, env_loader_web.dart on web
import 'env_loader_io.dart' if (dart.library.html) 'env_loader_web.dart';

/// Environment configuration loader
///
/// Supports two modes:
/// 1. Runtime environment variables (Appwrite, native apps): Uses Platform.environment
/// 2. Compile-time defines (local dev, web): Uses --dart-define-from-file
///
/// Usage for local development:
/// ```bash
/// flutter run --dart-define-from-file=env.json
/// ```
///
/// Usage for Appwrite deployment:
/// Set environment variables in Appwrite dashboard
///
/// Note: JSON objects in env.json should be encoded as strings:
/// ```json
/// {
///   "elasticsearch": "{\"endpoint\":\"https://...\",\"apiKey\":\"...\"}",
///   "gemini_api_key": "your_api_key"
/// }
/// ```
class EnvLoader {
  // Cache for parsed JSON values
  static final Map<String, dynamic> _cache = {};

  /// Get a simple string value
  /// First tries Platform.environment (runtime), then falls back to String.fromEnvironment (compile-time)
  static String getString(String key, {String defaultValue = ''}) {
    // Try runtime environment first (for Appwrite and server environments)
    final runtimeValue = PlatformEnv.getEnv(key);
    if (runtimeValue != null && runtimeValue.isNotEmpty) {
      return runtimeValue;
    }

    // Fall back to compile-time environment (for local development)
    switch (key) {
      case 'gemini_api_key':
        return const String.fromEnvironment('gemini_api_key', defaultValue: '');
      default:
        return defaultValue;
    }
  }

  /// Get and parse a JSON object/map from a JSON-encoded string
  /// First tries Platform.environment (runtime), then falls back to String.fromEnvironment (compile-time)
  static Map<String, dynamic> getJson(String key, {Map<String, dynamic>? defaultValue}) {
    // Check cache first
    if (_cache.containsKey(key)) {
      return _cache[key] as Map<String, dynamic>;
    }

    String jsonString = '';

    // Try runtime environment first (for Appwrite and server environments)
    final runtimeValue = PlatformEnv.getEnv(key);
    if (runtimeValue != null && runtimeValue.isNotEmpty) {
      jsonString = runtimeValue;
    } else {
      // Fall back to compile-time environment (for local development)
      switch (key) {
        case 'elasticsearch':
          jsonString = const String.fromEnvironment('elasticsearch', defaultValue: '');
          break;
        case 'vertex_ai':
          jsonString = const String.fromEnvironment('vertex_ai', defaultValue: '');
          break;
        case 'service_account':
          jsonString = const String.fromEnvironment('service_account', defaultValue: '');
          break;
        case 'pubmed':
          jsonString = const String.fromEnvironment('pubmed', defaultValue: '');
          break;
        default:
          return defaultValue ?? {};
      }
    }

    if (jsonString.isEmpty) {
      return defaultValue ?? {};
    }

    try {
      // Decode the JSON string to get the actual object
      final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
      _cache[key] = parsed;
      return parsed;
    } catch (e) {
      // Silent fail on parse error, return default
      return defaultValue ?? {};
    }
  }

  /// Get a nested value from a JSON object
  /// Example: getNestedString('elasticsearch', 'endpoint')
  static String getNestedString(String parentKey, String childKey, {String defaultValue = ''}) {
    final parent = getJson(parentKey);
    return parent[childKey]?.toString() ?? defaultValue;
  }

  /// Get nested integer
  static int getNestedInt(String parentKey, String childKey, {int defaultValue = 0}) {
    final parent = getJson(parentKey);
    final value = parent[childKey];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Get nested boolean
  static bool getNestedBool(String parentKey, String childKey, {bool defaultValue = false}) {
    final parent = getJson(parentKey);
    final value = parent[childKey];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return defaultValue;
  }

  /// Clear the cache (useful for testing)
  static void clearCache() {
    _cache.clear();
  }

  // Convenience getters for your app's specific config

  /// Elasticsearch configuration
  static Map<String, dynamic> get elasticsearch => getJson('elasticsearch');

  /// Vertex AI configuration
  static Map<String, dynamic> get vertexAi => getJson('vertex_ai');

  /// Service account configuration
  static Map<String, dynamic> get serviceAccount => getJson('service_account');

  /// PubMed configuration
  static Map<String, dynamic> get pubmed => getJson('pubmed');

  /// Gemini API key
  static String get geminiApiKey => getString('gemini_api_key');
}
