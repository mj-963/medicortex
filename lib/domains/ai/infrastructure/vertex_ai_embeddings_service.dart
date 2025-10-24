import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

/// Service for generating text embeddings using Google Cloud Vertex AI
/// This enables semantic search and hybrid search capabilities
class VertexAiEmbeddingsService {
  final String projectId;
  final String location;
  final Map<String, dynamic>? serviceAccount;
  final http.Client _client;
  auth.AccessToken? _accessToken;
  DateTime? _tokenExpiry;

  // Using text-embedding-004 model for high-quality embeddings
  static const String _model = 'text-embedding-004';
  static const int _embeddingDimension = 768;

  VertexAiEmbeddingsService({
    required this.projectId,
    required this.location,
    this.serviceAccount,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Get or refresh OAuth 2.0 access token
  Future<String> _getAccessToken() async {
    // Check if token is still valid
    if (_accessToken != null && _tokenExpiry != null) {
      if (DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
        return _accessToken!.data;
      }
    }

    // Generate new token from service account
    if (serviceAccount == null) {
      throw Exception('Service account credentials required for Vertex AI');
    }

    try {
      final accountCredentials = auth.ServiceAccountCredentials.fromJson(serviceAccount!);
      final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
      
      final authClient = await auth.clientViaServiceAccount(accountCredentials, scopes);
      final credentials = authClient.credentials;
      
      _accessToken = credentials.accessToken;
      _tokenExpiry = credentials.accessToken.expiry;
      
      authClient.close();
      
      return _accessToken!.data;
    } catch (e) {
      throw Exception('Failed to get access token: $e');
    }
  }

  /// Generate embedding vector for a single text
  Future<List<double>> generateEmbedding(String text) async {
    final embeddings = await generateEmbeddings([text]);
    return embeddings.first;
  }

  /// Generate embedding vectors for multiple texts (batch processing)
  Future<List<List<double>>> generateEmbeddings(List<String> texts) async {
    if (texts.isEmpty) return [];

    final url = Uri.parse(
      'https://$location-aiplatform.googleapis.com/v1/projects/$projectId/locations/$location/publishers/google/models/$_model:predict',
    );

    try {
      final accessToken = await _getAccessToken();
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'instances': texts.map((text) => {
            'content': text,
            'task_type': 'RETRIEVAL_DOCUMENT', // Optimized for search
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictions = data['predictions'] as List;
        
        return predictions.map((prediction) {
          final embeddings = prediction['embeddings'];
          final values = embeddings['values'] as List;
          return values.map((v) => (v as num).toDouble()).toList();
        }).toList();
      } else {
        throw Exception(
          'Failed to generate embeddings: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error generating embeddings: $e');
    }
  }

  /// Generate query embedding (optimized for search queries)
  Future<List<double>> generateQueryEmbedding(String query) async {
    final url = Uri.parse(
      'https://$location-aiplatform.googleapis.com/v1/projects/$projectId/locations/$location/publishers/google/models/$_model:predict',
    );

    try {
      final accessToken = await _getAccessToken();
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'instances': [
            {
              'content': query,
              'task_type': 'RETRIEVAL_QUERY', // Optimized for queries
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prediction = data['predictions'][0];
        final embeddings = prediction['embeddings'];
        final values = embeddings['values'] as List;
        return values.map((v) => (v as num).toDouble()).toList();
      } else {
        throw Exception(
          'Failed to generate query embedding: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error generating query embedding: $e');
    }
  }

  /// Calculate cosine similarity between two embedding vectors
  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  void dispose() {
    _client.close();
  }

  static int get embeddingDimension => _embeddingDimension;
}
