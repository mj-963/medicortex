import '../repository/ai_repository.dart';
import '../entity/ai_entities.dart';
import '../../search/data/client/qdrant_client.dart';
import '../../search/domain/entities/search_result.dart';
import '../infrastructure/vertex_ai_embeddings_service.dart';

/// RAG (Retrieval-Augmented Generation) Service
/// Combines Qdrant vector search with Gemini AI for grounded responses
class RagService {
  final AiRepository aiRepository;
  final QdrantClient qdrantClient;
  final VertexAiEmbeddingsService embeddingsService;

  RagService({
    required this.aiRepository,
    required this.qdrantClient,
    required this.embeddingsService,
  });

  /// Answer a question using RAG pipeline
  /// 1. Generate query embedding
  /// 2. Hybrid search in Elastic (vector + keyword)
  /// 3. Retrieve relevant papers
  /// 4. Build context from papers
  /// 5. Ask Gemini with grounded context
  Future<RagResponse> answerWithContext({
    required String question,
    int maxResults = 5,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // Step 1: Generate query embedding
      final queryEmbedding = await embeddingsService.generateQueryEmbedding(
        question,
      );

      // Step 2: Hybrid search (vector + keyword)
      final searchResults = await qdrantClient.hybridSearch(
        query: question,
        queryEmbedding: queryEmbedding,
        size: maxResults,
        filters: filters,
      );

      if (searchResults.results.isEmpty) {
        return RagResponse(
          answer:
              "I couldn't find any relevant medical literature for your question. Try rephrasing or broadening your search.",
          sources: [],
          confidence: 0.0,
        );
      }

      // Step 3: Build context from retrieved papers
      final context = _buildContext(searchResults.results);

      // Step 4: Create grounded prompt
      final prompt = _buildGroundedPrompt(
        question,
        context,
        searchResults.results,
      );

      // Step 5: Get AI response
      final aiResponse = await _generateAiResponse(prompt);

      return RagResponse(
        answer: aiResponse,
        sources: searchResults.results,
        confidence: _calculateConfidence(searchResults.results),
        searchTime: searchResults.searchTime,
      );
    } catch (e) {
      throw Exception('RAG pipeline failed: $e');
    }
  }

  /// Synthesize findings from multiple papers
  Future<String> synthesizePapers({
    required List<SearchResult> papers,
    required String topic,
  }) async {
    if (papers.isEmpty) {
      return "No papers provided for synthesis.";
    }

    final context = _buildContext(papers);

    final prompt = '''
You are a medical research expert. Synthesize the following research papers on "$topic".

$context

Provide a comprehensive synthesis that:
1. Identifies common findings and consensus
2. Highlights contradictions or debates
3. Notes the strength of evidence
4. Suggests areas needing more research

Format your response in clear sections with citations [PMID: xxx], [PMID: yyy], etc.
''';

    return await _generateAiResponse(prompt);
  }

  /// Suggest follow-up research questions
  Future<List<String>> suggestFollowUpQuestions({
    required String originalQuery,
    required List<SearchResult> papers,
  }) async {
    final context = _buildContext(papers.take(3).toList());

    final prompt = '''
Based on this medical research query: "$originalQuery"

And these relevant papers:
$context

Suggest 5 specific follow-up research questions that would:
1. Deepen understanding of the topic
2. Explore related areas
3. Address gaps in current research
4. Consider practical applications

Return ONLY the questions, one per line, numbered 1-5.
''';

    final response = await _generateAiResponse(prompt);

    // Parse numbered questions
    return response
        .split('\n')
        .where(
          (line) =>
              line.trim().isNotEmpty && RegExp(r'^\d+\.').hasMatch(line.trim()),
        )
        .map((line) => line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim())
        .toList();
  }

  /// Compare multiple studies
  Future<String> compareStudies({
    required List<SearchResult> papers,
    required String comparisonAspect,
  }) async {
    if (papers.length < 2) {
      return "Need at least 2 papers to compare.";
    }

    final context = _buildContext(papers);

    final prompt = '''
Compare these medical studies focusing on: $comparisonAspect

$context

Provide a detailed comparison table or analysis covering:
1. Methodology differences
2. Sample sizes and populations
3. Key findings
4. Conclusions and recommendations
5. Limitations of each study

Use citations [PMID: xxx], [PMID: yyy], etc.
''';

    return await _generateAiResponse(prompt);
  }

  /// Extract key insights from papers
  Future<List<String>> extractKeyInsights(List<SearchResult> papers) async {
    if (papers.isEmpty) return [];

    final context = _buildContext(papers.take(5).toList());

    final prompt = '''
Extract the top 10 key insights from these medical research papers:

$context

Return ONLY the insights, one per line, as bullet points.
Focus on actionable findings, novel discoveries, and clinical implications.
''';

    final response = await _generateAiResponse(prompt);

    return response
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  // ========== Private Helper Methods ==========

  /// Helper method to generate AI response from prompt
  Future<String> _generateAiResponse(String prompt) async {
    final content = AiContent(role: 'user', parts: [AiTextPart(prompt)]);

    final response = await aiRepository.generateContent([content]);
    return response.text ?? 'No response generated';
  }

  /// Build context string from search results
  String _buildContext(List<SearchResult> results) {
    final buffer = StringBuffer();

    for (int i = 0; i < results.length; i++) {
      final paper = results[i];
      final paperNum = i + 1;

      buffer.writeln('[Paper $paperNum]');
      buffer.writeln('Title: ${paper.title}');
      buffer.writeln('PMID: ${paper.id}');
      if (paper.publicationDate != null) {
        buffer.writeln('Year: ${paper.publicationDate!.year}');
      }
      if (paper.authors.isNotEmpty) {
        buffer.writeln(
          'Authors: ${paper.authors.take(3).join(", ")}${paper.authors.length > 3 ? " et al." : ""}',
        );
      }
      buffer.writeln('Abstract: ${paper.abstract}');
      buffer.writeln('Relevance Score: ${paper.score.toStringAsFixed(2)}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Build grounded prompt with citations
  String _buildGroundedPrompt(
    String question,
    String context,
    List<SearchResult> sources,
  ) {
    return '''
You are a medical research assistant with access to PubMed literature.

IMPORTANT: Base your answer ONLY on the provided research papers. Cite sources using [Paper X] format.

Research Papers:
$context

User Question: $question

Instructions:
1. Answer the question using ONLY information from the papers above
2. Cite specific papers for each claim using [PMID: xxx], [PMID: yyy], etc.
3. If the papers don't contain enough information, say so
4. Highlight any contradictions between papers
5. Note the publication years when discussing findings
6. Be precise about what the research shows vs. what it suggests

Provide a clear, evidence-based answer with proper citations.
''';
  }

  /// Calculate confidence score based on search results
  double _calculateConfidence(List<SearchResult> results) {
    if (results.isEmpty) return 0.0;

    // Average of top 3 scores, normalized
    final topScores = results.take(3).map((r) => r.score).toList();

    final avgScore = topScores.reduce((a, b) => a + b) / topScores.length;

    // Normalize to 0-1 range (assuming max score around 20)
    return (avgScore / 20).clamp(0.0, 1.0);
  }
}

/// Response from RAG pipeline
class RagResponse {
  final String answer;
  final List<SearchResult> sources;
  final double confidence;
  final Duration? searchTime;

  RagResponse({
    required this.answer,
    required this.sources,
    required this.confidence,
    this.searchTime,
  });

  /// Get formatted response with citations
  String get formattedAnswer {
    final buffer = StringBuffer();
    buffer.writeln(answer);
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('Sources (${sources.length}):');
    for (int i = 0; i < sources.length; i++) {
      final paper = sources[i];
      buffer.writeln('[${i + 1}] ${paper.title} (PMID: ${paper.id})');
    }
    return buffer.toString();
  }
}
