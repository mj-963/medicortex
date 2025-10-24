import 'dart:convert';

/// Environment configuration loader using --dart-define-from-file
///
/// Usage:
/// ```bash
/// flutter run --dart-define-from-file=env.json
/// ```
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
  static String getString(String key, {String defaultValue = ''}) {
    switch (key) {
      case 'gemini_api_key':
        return const String.fromEnvironment('gemini_api_key', defaultValue: '');
      default:
        return defaultValue;
    }
  }

  /// Get and parse a JSON object/map from a JSON-encoded string
  /// The value in env.json should be a JSON-encoded string
  static Map<String, dynamic> getJson(String key,
      {Map<String, dynamic>? defaultValue}) {
    // Check cache first
    if (_cache.containsKey(key)) {
      return _cache[key] as Map<String, dynamic>;
    }

    String jsonString = '';

    // Get the JSON-encoded string from environment
    switch (key) {
      case 'elasticsearch':
        jsonString =
            const String.fromEnvironment('elasticsearch', defaultValue: '');
        break;
      case 'vertex_ai':
        jsonString =
            const String.fromEnvironment('vertex_ai', defaultValue: '');
        break;
      case 'service_account':
        jsonString =
            const String.fromEnvironment('service_account', defaultValue: '');
        break;
      case 'pubmed':
        jsonString = const String.fromEnvironment('pubmed', defaultValue: '');
        break;
      default:
        return defaultValue ?? {};
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
  static String getNestedString(String parentKey, String childKey,
      {String defaultValue = ''}) {
    final parent = getJson(parentKey);
    return parent[childKey]?.toString() ?? defaultValue;
  }

  /// Get nested integer
  static int getNestedInt(String parentKey, String childKey,
      {int defaultValue = 0}) {
    final parent = getJson(parentKey);
    final value = parent[childKey];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Get nested boolean
  static bool getNestedBool(String parentKey, String childKey,
      {bool defaultValue = false}) {
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
