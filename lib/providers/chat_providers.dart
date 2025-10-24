import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:medicortex/domains/ai/entity/ai_entities.dart';
import 'package:medicortex/domains/ai/repository/ai_repository.dart';
import 'package:medicortex/domains/chat/entity/chat_message.dart';
import 'package:medicortex/domains/chat/entity/chat_state.dart';
import 'package:medicortex/domains/mcp/entity/mcp_models.dart';
import 'package:medicortex/domains/mcp/repository/mcp_repository.dart';
import 'package:medicortex/domains/search/domain/entities/search_query.dart';
import 'package:medicortex/domains/search/domain/repository/search_repository.dart';
import 'package:medicortex/providers/ai_providers.dart';
import 'package:medicortex/providers/mcp_providers.dart';
import 'package:medicortex/providers/search_providers.dart';
import 'package:medicortex/providers/settings_providers.dart';
import 'package:medicortex/providers/rag_provider.dart';
import 'package:medicortex/providers/fulltext_provider.dart';
import 'package:medicortex/presentation/providers/selected_papers_provider.dart';
import 'package:medicortex/presentation/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  StreamSubscription<dynamic>? _messageSubscription;

  ChatNotifier(this._ref) : super(const ChatState()) {
    state = state.copyWith(isApiKeySet: _ref.read(apiKeyProvider) != null);

    _ref.listen<String?>(apiKeyProvider, (_, next) {
      if (mounted) {
        state = state.copyWith(isApiKeySet: next != null);
      }
    });

    _ref.onDispose(() {
      _messageSubscription?.cancel();
      debugPrint("ChatNotifier disposed, stream cancelled.");
    });
  }

  AiRepository? get _aiRepo => _ref.read(aiRepositoryProvider);
  McpRepository get _mcpRepo => _ref.read(mcpRepositoryProvider);
  SearchRepository get _searchRepo => _ref.read(searchRepositoryProvider);

  void _addDisplayMessage(ChatMessage message) {
    if (!mounted) return;
    state = state.copyWith(
      displayMessages: [...state.displayMessages, message],
    );
  }

  void _updateLastDisplayMessage(ChatMessage updatedMessage) {
    if (!mounted) return;
    final currentMessages = List<ChatMessage>.from(state.displayMessages);
    // Check if last message is an AI message (not user) and update it
    // If no AI message exists, add it as new message
    if (currentMessages.isNotEmpty && !currentMessages.last.isUser) {
      currentMessages[currentMessages.length - 1] = updatedMessage;
      state = state.copyWith(displayMessages: currentMessages);
    } else {
      // No AI message to update, add as new message
      _addDisplayMessage(updatedMessage);
    }
  }

  void _addErrorMessage(String errorText, {bool setLoadingFalse = true}) {
    final errorMessage = ChatMessage(
      text: "Error: $errorText",
      isUser: false,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    if (!mounted) return;

    final currentMessages = List<ChatMessage>.from(state.displayMessages);
    if (currentMessages.isNotEmpty &&
        !currentMessages.last.isUser &&
        currentMessages.last.text.isEmpty) {
      currentMessages[currentMessages.length - 1] = errorMessage;
    } else {
      currentMessages.add(errorMessage);
    }

    state = state.copyWith(
      displayMessages: currentMessages,
      isLoading: setLoadingFalse ? false : state.isLoading,
    );
    if (kDebugMode && setLoadingFalse) {
      debugPrint(
        "ChatNotifier: Added error message, set isLoading=$setLoadingFalse",
      );
    }
  }

  void _setLoading(bool loading, {String? status}) {
    if (!mounted) return;
    if (state.isLoading != loading ||
        (status != null && state.loadingStatus != status)) {
      state = state.copyWith(
        isLoading: loading,
        loadingStatus:
            status ?? (loading ? 'AI is thinking...' : state.loadingStatus),
      );
      debugPrint(
        "ChatNotifier: Set isLoading=$loading${status != null ? ', status=$status' : ''}",
      );
    }
  }

  void _updateLoadingStatus(String status) {
    if (!mounted) return;
    if (state.isLoading && state.loadingStatus != status) {
      state = state.copyWith(loadingStatus: status);
      debugPrint("ChatNotifier: Updated loading status: $status");
    }
  }

  /// Public method to set loading state (for direct RAG execution)
  void setLoading(bool loading) {
    _setLoading(loading);
  }

  /// Delete a message by timestamp
  void deleteMessage(int timestamp) {
    if (!mounted) return;
    final updatedMessages =
        state.displayMessages
            .where((message) => message.timestamp != timestamp)
            .toList();
    state = state.copyWith(displayMessages: updatedMessages);
    debugPrint("ChatNotifier: Deleted message with timestamp $timestamp");
  }

  /// Public method to add AI message directly (for direct RAG execution)
  void addAiMessage(String text) {
    if (!mounted) return;
    final aiMessage = ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _addDisplayMessage(aiMessage);

    // Also add to chat history for context
    final aiContent = AiContent.model(text);
    state = state.copyWith(chatHistory: [...state.chatHistory, aiContent]);

    debugPrint(
      "ChatNotifier: Added AI message directly: ${text.substring(0, text.length > 50 ? 50 : text.length)}...",
    );
  }

  // --- Message Sending Logic ---
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) {
      debugPrint(
        "ChatNotifier: sendMessage blocked (empty or loading: ${state.isLoading})",
      );
      return;
    }

    await _messageSubscription?.cancel();
    _messageSubscription = null;

    final aiRepo = _aiRepo;
    if (aiRepo == null || !aiRepo.isInitialized) {
      _addErrorMessage(
        "AI Service not available (check API Key).",
        setLoadingFalse: false,
      );
      return;
    }

    final userMessageText = text.trim();
    final userMessageForDisplay = ChatMessage(
      text: userMessageText,
      isUser: true,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    final userMessageForHistory = AiContent.user(userMessageText);
    final historyForApi = List<AiContent>.from(state.chatHistory);

    _addDisplayMessage(userMessageForDisplay);
    _setLoading(true);
    // Don't add empty placeholder - loading indicator will show instead

    // Decide path based on available tools (built-in or MCP)
    final mcpState = _ref.read(mcpClientProvider);

    // We always have built-in tools (search_medical_literature + RAG tools)
    // So we should always use the tool orchestration path
    final bool hasMcpTools =
        mcpState.hasActiveConnections &&
        mcpState.uniqueAvailableToolNames.isNotEmpty;
    final bool hasBuiltInTools = true; // search + RAG tools always available
    final bool useToolOrchestration = hasBuiltInTools;

    /* OLD LOGIC (kept for reference):
    // This required at least one MCP connection to use ANY tools
    final bool useMcp =
        mcpState.hasActiveConnections &&
        mcpState.uniqueAvailableToolNames.isNotEmpty;
    */

    try {
      if (useToolOrchestration) {
        // --- Tool Orchestration Path (Built-in + MCP Tools) ---
        debugPrint(
          "ChatNotifier: Orchestrating query with tools (Built-in: $hasBuiltInTools, MCP: $hasMcpTools)...",
        );
        final AiResponse finalAiResponse = await _orchestrateMcpQuery(
          userMessageText,
          historyForApi,
          aiRepo,
          _mcpRepo,
          mcpState,
        );

        final finalContent = finalAiResponse.firstCandidateContent;
        final historyUpdate = [
          ...historyForApi,
          userMessageForHistory,
          if (finalContent != null) finalContent,
        ];

        if (mounted) {
          final finalMessage = ChatMessage(
            text: finalContent?.text ?? "(No response from orchestration)",
            isUser: false,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          _updateLastDisplayMessage(finalMessage);
          state = state.copyWith(chatHistory: historyUpdate);
          _setLoading(false);
        }
      }
      /* COMMENTED OUT - Direct streaming path without tools
      // This code path is no longer used since we always use tool orchestration
      // Kept for reference in case you want to restore direct streaming
      else {
        // --- Direct AI Streaming Path ---
        debugPrint("ChatNotifier: Processing query via Direct AI Stream...");
        final responseStream = aiRepo.sendMessageStream(
          userMessageText,
          historyForApi,
        );
        final fullResponseBuffer = StringBuffer();
        ChatMessage lastAiMessage = aiPlaceholderMessage;

        _messageSubscription = responseStream.listen(
          (AiStreamChunk chunk) {
            if (!mounted || !state.isLoading) {
              debugPrint(
                "ChatNotifier: Stream chunk received but state changed. Cancelling.",
              );
              _messageSubscription?.cancel();
              _messageSubscription = null;
              if (mounted && state.isLoading) _setLoading(false);
              return;
            }
            fullResponseBuffer.write(chunk.textDelta);
            lastAiMessage = lastAiMessage.copyWith(
              text: fullResponseBuffer.toString(),
            );
            _updateLastDisplayMessage(lastAiMessage);
          },
          onError: (error) {
            debugPrint(
              "ChatNotifier: Error receiving direct stream chunk: $error",
            );
            _addErrorMessage(error.toString());
            _setLoading(false);
            _messageSubscription = null;
          },
          onDone: () {
            debugPrint("ChatNotifier: Direct stream finished.");
            if (fullResponseBuffer.isNotEmpty && mounted) {
              final aiContentForHistory = AiContent.model(
                fullResponseBuffer.toString(),
              );
              state = state.copyWith(
                chatHistory: [
                  ...historyForApi,
                  userMessageForHistory,
                  aiContentForHistory,
                ],
              );
            }
            _setLoading(false);
            _messageSubscription = null;
          },
          cancelOnError: true,
        );
      }
      */
    } catch (e) {
      debugPrint("ChatNotifier: Error in sendMessage: $e");
      _addErrorMessage(e.toString());
      _setLoading(false);
      _messageSubscription = null;
    }
  }

  /// Creates RAG tool definitions for analyzing papers
  List<AiFunctionDeclaration> _createRagTools() {
    return [
      // Get full text tool
      AiFunctionDeclaration(
        name: 'get_full_paper_text',
        description: '''
Fetch the full text of a paper from PubMed Central (PMC) by its PMID.
Use this when you need the complete paper content beyond just the abstract.

WHEN TO USE:
- User asks for detailed analysis that requires full paper
- Need to check specific methodologies, data, or results sections
- Abstract doesn't provide enough information
- User explicitly asks for "full text" or "full paper"

IMPORTANT:
- Only works for papers available in PMC Open Access
- Returns null if paper is not available in PMC
- Full text can be very long (10,000+ words)
- Use sparingly - only when abstract is insufficient

EXAMPLE:
User: "Can you analyze the methodology in detail for PMID 12345678?"
→ Use this tool to get full text, then analyze the Methods section
''',
        parameters: AiObjectSchema(
          properties: {
            'pmid': AiStringSchema(
              description: 'The PMID of the paper to fetch full text for',
            ),
          },
          requiredProperties: ['pmid'],
        ),
      ),

      // Synthesize papers tool
      AiFunctionDeclaration(
        name: 'synthesize_papers',
        description: '''
Synthesize findings from specific papers by their PMIDs.
Use this when you want to combine insights from multiple papers you found via search.

WHEN TO USE:
- After searching, you want to analyze specific papers
- User asks to "synthesize", "combine", or "summarize" papers
- You want to provide an overview of findings across studies

HOW TO USE:
1. First use search_medical_literature to find relevant papers
2. Note the PMIDs of relevant papers from search results
3. Call this tool with those PMIDs and the topic

IMPORTANT:
- Pass PMIDs as a list of strings (e.g., ["12345", "67890"])
- If user has pre-selected papers, those PMIDs will be in the context
- Cite each paper by title and PMID, not "Paper 1"
- Identify consensus and contradictions
''',
        parameters: AiObjectSchema(
          properties: {
            'pmids': AiArraySchema(
              items: AiStringSchema(description: 'PMID of a paper'),
              description:
                  'List of PMIDs to synthesize (e.g., ["12345", "67890"])',
            ),
            'topic': AiStringSchema(
              description:
                  'The main topic or aspect to focus on when synthesizing',
            ),
          },
          requiredProperties: ['pmids', 'topic'],
        ),
      ),

      // Compare studies tool
      AiFunctionDeclaration(
        name: 'compare_studies',
        description: '''
Compare methodologies, findings, or other aspects of specific papers by their PMIDs.
Use this when you want to see differences/similarities between studies.

WHEN TO USE:
- After searching, you want to compare specific papers
- User asks to "compare" papers
- You want to analyze methodological differences or conflicting findings

HOW TO USE:
1. First use search_medical_literature to find relevant papers
2. Note the PMIDs of papers to compare
3. Call this tool with those PMIDs and comparison aspect

IMPORTANT:
- Requires at least 2 PMIDs
- Pass PMIDs as a list of strings
- Focus on the specified comparison aspect
- Cite papers by title and PMID
''',
        parameters: AiObjectSchema(
          properties: {
            'pmids': AiArraySchema(
              items: AiStringSchema(description: 'PMID of a paper'),
              description: 'List of PMIDs to compare (minimum 2)',
            ),
            'aspect': AiStringSchema(
              description:
                  'What to compare: methodology, findings, efficacy, safety, etc.',
            ),
          },
          requiredProperties: ['pmids', 'aspect'],
        ),
      ),

      // Extract insights tool
      AiFunctionDeclaration(
        name: 'extract_insights',
        description: '''
Extract key actionable insights from specific papers by their PMIDs.
Use this when you want practical takeaways or clinical implications.

WHEN TO USE:
- After searching, you want to extract insights from specific papers
- User asks for "insights", "takeaways", or "key findings"
- You want to provide clinical implications

HOW TO USE:
1. First use search_medical_literature to find relevant papers
2. Note the PMIDs of relevant papers
3. Call this tool with those PMIDs

IMPORTANT:
- Pass PMIDs as a list of strings
- Focus on actionable, practical insights
- Prioritize novel or surprising findings
- Cite sources for each insight
''',
        parameters: AiObjectSchema(
          properties: {
            'pmids': AiArraySchema(
              items: AiStringSchema(description: 'PMID of a paper'),
              description: 'List of PMIDs to extract insights from',
            ),
          },
          requiredProperties: ['pmids'],
        ),
      ),

      // Suggest follow-ups tool
      AiFunctionDeclaration(
        name: 'suggest_followup_questions',
        description: '''
Generate follow-up research questions based on specific papers or conversation.
Use this when you want to suggest deeper exploration or related topics.

WHEN TO USE:
- After analyzing papers, to suggest next research directions
- User asks for "follow-up questions" or "what else should I research"
- You want to guide further exploration

HOW TO USE:
1. If analyzing papers: pass their PMIDs
2. If based on conversation: pass empty array and provide context in query
3. Call this tool with PMIDs (or empty array) and original query/context

IMPORTANT:
- Generate 3-5 specific, actionable questions
- Base questions on gaps or interesting findings
- Make questions searchable (good for next queries)
''',
        parameters: AiObjectSchema(
          properties: {
            'pmids': AiArraySchema(
              items: AiStringSchema(description: 'PMID of a paper'),
              description:
                  'List of PMIDs to base questions on (can be empty for conversation-based)',
            ),
            'context': AiStringSchema(
              description: 'The context or topic for generating questions',
            ),
          },
          requiredProperties: ['pmids', 'context'],
        ),
      ),
    ];
  }

  /// Creates the medical search tool definition for Gemini
  AiFunctionDeclaration _createMedicalSearchTool() {
    return AiFunctionDeclaration(
      name: 'search_medical_literature',
      description: '''
Search PubMed medical literature database (6,000+ articles) using hybrid search.
Use this tool to find authoritative medical information, research studies, treatment guidelines, and clinical evidence.

WHEN TO USE:
- Medical conditions, symptoms, or diagnoses
- Treatment options, effectiveness, or side effects
- Drug information or comparisons
- Health and wellness topics
- Medical research or latest findings
- Clinical guidelines or best practices

IMPORTANT:
- Always cite sources using [PMID: xxx] format in your response
- Provide evidence-based information from the search results
- When discussing symptoms, recommend consulting healthcare provider
''',
      parameters: AiObjectSchema(
        properties: {
          'query': AiStringSchema(
            description: '''
The search query. Be specific and use medical terminology when appropriate.
Examples:
- "type 2 diabetes treatment guidelines"
- "cognitive behavioral therapy anxiety effectiveness"
- "intermittent fasting metabolic effects"
- "COVID-19 vaccine efficacy"
- "migraine prevention medications"
''',
          ),
          'max_results': AiNumberSchema(
            description:
                'Number of results to return (default: 10, max: 20). Use more for comprehensive topics.',
          ),
        },
        requiredProperties: ['query'],
      ),
    );
  }

  /// Orchestrates AI and MCP interactions with agentic behavior for multi-step reasoning.
  Future<AiResponse> _orchestrateMcpQuery(
    String text,
    List<AiContent> history,
    AiRepository aiRepo,
    McpRepository mcpRepo,
    McpClientState mcpState,
  ) async {
    debugPrint("\n${"=" * 80}");
    debugPrint("🔵 USER QUERY: $text");
    debugPrint("=" * 80);

    // Get selected papers context
    final selectedPmids = _ref.read(selectedPapersProvider);
    final workspaceState = _ref.read(workspaceProvider);
    final allResults = workspaceState.searchResults;
    final selectedPapers =
        allResults.where((paper) => selectedPmids.contains(paper.id)).toList();

    // Configure agent behavior
    const int maxIterations = 15; // Prevent infinite loops

    final aiTool = AiTool(
      functionDeclarations: [
        // Add medical search tool
        _createMedicalSearchTool(),
        // Add RAG tools for analyzing selected papers
        ..._createRagTools(),
        // Add MCP tools
        for (var tools in mcpState.discoveredTools.entries)
          for (var mcpTool in tools.value)
            AiFunctionDeclaration(
              name: mcpTool.name,
              description: mcpTool.description ?? "",
              parameters: AiSchema.fromSchemaMap(mcpTool.inputSchema),
            ),
      ],
    );

    debugPrint(
      "🔧 Available tools: ${aiTool.functionDeclarations.map((t) => t.name).join(', ')}",
    );
    if (selectedPapers.isNotEmpty) {
      debugPrint("📄 Selected papers: ${selectedPapers.length}");
      for (var paper in selectedPapers.take(3)) {
        final titlePreview =
            paper.title.length > 60
                ? '${paper.title.substring(0, 60)}...'
                : paper.title;
        debugPrint("   • PMID ${paper.id}: $titlePreview");
      }
    }

    if (aiTool.functionDeclarations.isEmpty) {
      debugPrint("⚠️  No tools available, proceeding without tools.");
      return await aiRepo.generateContent([...history, AiContent.user(text)]);
    }

    // Build context-aware user message
    String contextualMessage = text;
    if (selectedPapers.isNotEmpty) {
      final papersList = selectedPapers
          .asMap()
          .entries
          .map((e) {
            final paper = e.value;
            return '${e.key + 1}. [PMID: ${paper.id}] ${paper.title}';
          })
          .join('\n');

      contextualMessage =
          '''CONTEXT: The user has selected ${selectedPapers.length} papers from search results:
$papersList

USER REQUEST: $text

IMPORTANT: The user has pre-selected these papers. When analyzing, you can use the RAG tools (synthesize_papers, compare_studies, extract_insights, suggest_followup_questions) with these PMIDs. You can also search for additional papers and analyze those.''';

      debugPrint(
        "📝 Added context about ${selectedPapers.length} selected papers",
      );
    }

    // Prepare history with agentic system prompt
    final userMessage = AiContent.user(contextualMessage);
    final historyWithAgentPrompt = [...history, userMessage];

    // Agent state tracking
    List<AiContent> agentConversation = [...historyWithAgentPrompt];
    int iterationCount = 0;
    bool agentThinking = true;

    _updateLoadingStatus("Planning approach to answer your question...");

    try {
      // Agent loop - continue until agent decides to answer directly or max iterations reached
      while (agentThinking && iterationCount < maxIterations) {
        iterationCount++;
        debugPrint("\n${"─" * 80}");
        debugPrint("🔄 ITERATION $iterationCount");
        debugPrint("─" * 80);

        // Get AI response with tools
        final aiResponse = await aiRepo.generateContent(
          agentConversation,
          tools: [aiTool],
        );

        final aiContent = aiResponse.firstCandidateContent;
        if (aiContent == null) {
          throw Exception("Empty response from AI");
        }

        // Add AI response to conversation history
        agentConversation = [...agentConversation, aiContent];

        // Extract function calls from response
        final functionCalls =
            aiContent.parts.whereType<AiFunctionCallPart>().toList();

        // If no function calls, agent is done thinking and ready to respond directly
        if (functionCalls.isEmpty) {
          debugPrint("✅ Agent ready to respond (no tool calls)");

          // Extract text response
          final textParts = aiContent.parts.whereType<AiTextPart>();
          if (textParts.isNotEmpty) {
            final responseText = textParts.map((p) => p.text).join('\n');
            debugPrint("\n${"=" * 80}");
            debugPrint("🟢 FINAL RESPONSE:");
            debugPrint("=" * 80);
            debugPrint(
              responseText.length > 500
                  ? '${responseText.substring(0, 500)}...'
                  : responseText,
            );
            debugPrint("=" * 80 + "\n");
          }

          agentThinking = false;
          continue; // Break the loop with final response
        }

        debugPrint("🛠️  Agent calling ${functionCalls.length} tool(s):");

        // Execute each tool call and add results to conversation
        final List<AiFunctionResponsePart> functionResponses = [];

        for (final functionCall in functionCalls) {
          final toolName = functionCall.name;

          // Handle medical search tool separately
          if (toolName == 'search_medical_literature') {
            try {
              final args = functionCall.args;
              final query = args['query'] as String;
              final maxResults = (args['max_results'] as num?)?.toInt() ?? 10;

              debugPrint("  📚 $toolName");
              debugPrint("     Query: '$query'");
              debugPrint("     Max results: $maxResults");

              _updateLoadingStatus("Searching medical literature for: $query");

              // Execute search
              final searchQuery = SearchQuery(
                query: query,
                maxResults: maxResults.clamp(1, 20),
              );

              final results = await _searchRepo.search(searchQuery);

              debugPrint(
                "     ✓ Found ${results.totalHits} articles (returning ${results.count})",
              );
              for (var i = 0; i < results.count && i < 3; i++) {
                final title = results.results[i].title;
                final preview =
                    title.length > 60 ? '${title.substring(0, 60)}...' : title;
                debugPrint("       • PMID ${results.results[i].id}: $preview");
              }

              // Format results for Gemini
              final formattedResults = StringBuffer();
              formattedResults.writeln(
                'Found ${results.totalHits} articles (showing top ${results.count}):',
              );
              formattedResults.writeln();

              for (var i = 0; i < results.results.length; i++) {
                final result = results.results[i];
                formattedResults.writeln('[${i + 1}] PMID: ${result.id}');
                formattedResults.writeln('Title: ${result.title}');
                if (result.publicationDate != null) {
                  formattedResults.writeln(
                    'Date: ${result.publicationDate!.year}',
                  );
                }
                formattedResults.writeln('Abstract: ${result.abstract}');
                formattedResults.writeln('URL: ${result.sourceUrl}');
                formattedResults.writeln();
              }

              functionResponses.add(
                AiFunctionResponsePart(
                  name: toolName,
                  response: {'results': formattedResults.toString()},
                ),
              );
            } catch (e) {
              debugPrint("     ❌ Search failed: $e");
              functionResponses.add(
                AiFunctionResponsePart(
                  name: toolName,
                  response: {'error': "Search failed: $e"},
                ),
              );
            }
            continue;
          }

          // Handle RAG tools with PMIDs
          if (toolName == 'synthesize_papers' ||
              toolName == 'compare_studies' ||
              toolName == 'extract_insights' ||
              toolName == 'suggest_followup_questions') {
            try {
              final ragService = _ref.read(ragServiceProvider);
              if (ragService == null) {
                throw Exception(
                  'RAG service not available. Please configure Gemini API key.',
                );
              }

              // Get PMIDs from function arguments
              final args = functionCall.args;
              final pmidsArg = args['pmids'];
              List<String> pmids = [];

              if (pmidsArg is List) {
                pmids = pmidsArg.map((e) => e.toString()).toList();
              }

              if (pmids.isEmpty) {
                throw Exception(
                  'No PMIDs provided. Please specify which papers to analyze by their PMIDs.',
                );
              }

              // Get all search results and filter to specified PMIDs
              final workspaceState = _ref.read(workspaceProvider);
              final allResults = workspaceState.searchResults;
              final targetPapers =
                  allResults
                      .where((paper) => pmids.contains(paper.id))
                      .toList();

              if (targetPapers.isEmpty) {
                throw Exception(
                  'Papers with PMIDs ${pmids.join(", ")} not found in current search results. Please search first.',
                );
              }

              debugPrint("  🤖 $toolName");
              debugPrint("     Target papers: ${targetPapers.length}");
              for (var i = 0; i < targetPapers.take(3).length; i++) {
                final title = targetPapers[i].title;
                final preview =
                    title.length > 60 ? '${title.substring(0, 60)}...' : title;
                debugPrint("       • PMID ${targetPapers[i].id}: $preview");
              }

              String result;

              switch (toolName) {
                case 'get_full_paper_text':
                  final pmid = args['pmid'] as String;

                  _updateLoadingStatus(
                    "Fetching full text for PMID: $pmid from PubMed Central...",
                  );

                  final fullTextService = _ref.read(fullTextServiceProvider);
                  final fullTextResult = await fullTextService.fetchFullText(
                    pmid,
                  );

                  if (fullTextResult != null) {
                    result = '''
Full text retrieved successfully from PMC (${fullTextResult.pmcId})
Word count: ${fullTextResult.wordCount}

${fullTextResult.fullText}
''';
                  } else {
                    result = '''
Full text not available for PMID: $pmid

This paper may not be available in PubMed Central Open Access.
Only the abstract is available. Would you like me to work with the abstract instead?
''';
                  }
                  break;

                case 'synthesize_papers':
                  final topic = args['topic'] as String;

                  _updateLoadingStatus(
                    "Synthesizing ${targetPapers.length} papers on: $topic",
                  );

                  result = await ragService.synthesizePapers(
                    papers: targetPapers,
                    topic: topic,
                  );
                  break;

                case 'compare_studies':
                  if (targetPapers.length < 2) {
                    throw Exception(
                      'Need at least 2 papers to compare. Provided: ${targetPapers.length}',
                    );
                  }

                  final aspect = args['aspect'] as String;

                  _updateLoadingStatus(
                    "Comparing ${targetPapers.length} studies: $aspect",
                  );

                  result = await ragService.compareStudies(
                    papers: targetPapers,
                    comparisonAspect: aspect,
                  );
                  break;

                case 'extract_insights':
                  _updateLoadingStatus(
                    "Extracting insights from ${targetPapers.length} papers",
                  );

                  final insights = await ragService.extractKeyInsights(
                    targetPapers,
                  );
                  result = insights
                      .asMap()
                      .entries
                      .map((e) => '${e.key + 1}. ${e.value}')
                      .join('\n\n');
                  break;

                case 'suggest_followup_questions':
                  final context = args['context'] as String;

                  _updateLoadingStatus(
                    "Generating follow-up questions${targetPapers.isNotEmpty ? ' based on ${targetPapers.length} papers' : ''}",
                  );

                  final questions = await ragService.suggestFollowUpQuestions(
                    originalQuery: context,
                    papers: targetPapers,
                  );
                  result = questions
                      .asMap()
                      .entries
                      .map((e) => '${e.key + 1}. ${e.value}')
                      .join('\n\n');
                  break;

                default:
                  throw Exception('Unknown RAG tool: $toolName');
              }

              debugPrint("     ✓ RAG operation completed");
              debugPrint("     Result length: ${result.length} characters");

              functionResponses.add(
                AiFunctionResponsePart(
                  name: toolName,
                  response: {'result': result},
                ),
              );
            } catch (e) {
              debugPrint("     ❌ RAG operation failed: $e");
              functionResponses.add(
                AiFunctionResponsePart(
                  name: toolName,
                  response: {'error': e.toString()},
                ),
              );
            }
            continue;
          }

          // Handle MCP tools
          final serverId = mcpState.getServerIdForTool(toolName);

          if (serverId == null) {
            debugPrint("  ⚠️  MCP tool '$toolName' not found");
            functionResponses.add(
              AiFunctionResponsePart(
                name: toolName,
                response: {
                  'error': "Tool '$toolName' not found or has duplicates.",
                },
              ),
            );
            continue;
          }

          try {
            debugPrint("  🔧 $toolName (MCP)");
            debugPrint("     Args: ${functionCall.args}");
            // Display message indicating tool call
            final serverName =
                _ref
                    .read(mcpServerListProvider)
                    .firstWhereOrNull((s) => s.id == serverId)
                    ?.name ??
                serverId;

            _updateLoadingStatus(
              "Step $iterationCount: Using $toolName on $serverName",
            );

            // Execute tool and get result
            final toolResult = await mcpRepo.executeTool(
              serverId: serverId,
              toolName: toolName,
              arguments: functionCall.args,
            );

            final resultText = toolResult
                .whereType<McpTextContent>()
                .map((t) => t.text)
                .join('\n');

            debugPrint(
              "     ✓ Result: ${resultText.substring(0, resultText.length > 100 ? 100 : resultText.length)}${resultText.length > 100 ? '...' : ''}",
            );

            // Add successful response
            functionResponses.add(
              AiFunctionResponsePart(
                name: toolName,
                response: {'result': resultText},
              ),
            );
          } catch (e) {
            debugPrint("     ❌ Error: $e");

            // Add error response
            functionResponses.add(
              AiFunctionResponsePart(
                name: toolName,
                response: {'error': "Execution failed: $e"},
              ),
            );
          }
        }

        debugPrint("\n📊 Iteration $iterationCount summary:");
        debugPrint("   Tools called: ${functionCalls.length}");
        debugPrint("   Responses collected: ${functionResponses.length}");

        // Create tool response content and add to agent conversation
        if (functionResponses.isNotEmpty) {
          final toolResponseContent = AiContent(
            role: 'tool',
            parts: functionResponses,
          );

          agentConversation = [...agentConversation, toolResponseContent];
        }
      }

      // Generate final response based on all agent interactions
      _updateLoadingStatus("Preparing answer...");

      // If we reached max iterations without an answer, force a final response
      if (agentThinking) {
        debugPrint(
          "\n⚠️  Max iterations ($maxIterations) reached, forcing final answer",
        );

        // Add a system message instructing to provide final answer
        agentConversation = [
          ...agentConversation,
          AiContent(
            role: 'tool',
            parts: [
              AiTextPart(
                "You've gathered enough information. Please provide your final answer to the user's question now.",
              ),
            ],
          ),
        ];

        // Final call without tools to get conclusion
        final finalResponse = await aiRepo.generateContent(agentConversation);

        debugPrint("\n${"=" * 80}");
        debugPrint("🎯 ORCHESTRATION COMPLETE (forced)");
        debugPrint("=" * 80 + "\n");

        return finalResponse;
      } else {
        debugPrint("\n${"=" * 80}");
        debugPrint("🎯 ORCHESTRATION COMPLETE");
        debugPrint("   Total iterations: $iterationCount");
        debugPrint("=" * 80 + "\n");

        // The last response in agentConversation is already the final answer
        return AiResponse(
          candidates: [AiCandidate(content: agentConversation.last)],
        );
      }
    } catch (e) {
      debugPrint("\n❌ ERROR in orchestration: $e\n");
      return AiResponse(
        candidates: [
          AiCandidate(content: AiContent.model("Error during processing: $e")),
        ],
      );
    }
  }

  // Method to clear chat history and display messages
  void clearChat() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    if (!mounted) return;
    state = state.copyWith(
      displayMessages: [],
      chatHistory: [],
      isLoading: false,
    );
    debugPrint("ChatNotifier: Chat cleared.");
  }

  // Method to restore messages from a saved conversation
  void restoreMessages(List<ChatMessage> messages) {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    if (!mounted) return;

    // Convert ChatMessages to AiContent for chat history
    final aiHistory =
        messages.map((msg) {
          return msg.isUser
              ? AiContent.user(msg.text)
              : AiContent.model(msg.text);
        }).toList();

    state = state.copyWith(
      displayMessages: messages,
      chatHistory: aiHistory,
      isLoading: false,
    );
    debugPrint("ChatNotifier: Restored ${messages.length} messages.");
  }
}

// --- Provider ---
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
