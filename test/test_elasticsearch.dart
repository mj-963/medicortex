import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicortex/providers/search_providers.dart';
import 'package:medicortex/domains/search/domain/entities/search_query.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ElasticsearchTestScreen(),
      ),
    ),
  );
}

class ElasticsearchTestScreen extends ConsumerStatefulWidget {
  const ElasticsearchTestScreen({super.key});

  @override
  ConsumerState<ElasticsearchTestScreen> createState() =>
      _ElasticsearchTestScreenState();
}

class _ElasticsearchTestScreenState
    extends ConsumerState<ElasticsearchTestScreen> {
  final _controller = TextEditingController(text: 'diabetes treatment');
  String _status = 'Ready to test connection';
  String _results = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-test connection on start
    Future.delayed(const Duration(milliseconds: 500), _testConnection);
  }

  Future<void> _testConnection() async {
    setState(() {
      _status = '🔌 Testing Elasticsearch connection...';
      _results = '';
      _isLoading = true;
    });

    try {
      final client = ref.read(elasticsearchClientProvider);
      final connected = await client.testConnection();

      if (connected) {
        final exists = await client.indexExists();
        if (exists) {
          final stats = await client.getIndexStats();
          final docCount = stats['document_count'] ?? 0;
          setState(() {
            _status = '✅ Connected! Index has $docCount documents';
          });
        } else {
          setState(() {
            _status = '⚠️  Connected, but index doesn\'t exist yet';
          });
        }
      } else {
        setState(() {
          _status = '❌ Connection failed';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createIndex() async {
    setState(() {
      _status = '🔨 Creating index...';
      _isLoading = true;
    });

    try {
      final repo = ref.read(searchRepositoryProvider);
      await repo.initialize();
      setState(() {
        _status = '✅ Index created successfully!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed to create index: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSearch() async {
    setState(() {
      _status = '🔍 Searching...';
      _results = '';
      _isLoading = true;
    });

    try {
      final repo = ref.read(searchRepositoryProvider);

      final query = SearchQuery(query: _controller.text, maxResults: 10);

      final results = await repo.search(query);

      if (results.isEmpty) {
        setState(() {
          _status = '📭 No results found. Index might be empty.';
          _results = 'Try ingesting data first using the Python script.';
        });
      } else {
        setState(() {
          _status = results.summary;
          _results = results.results
              .asMap()
              .entries
              .map((entry) {
                final i = entry.key + 1;
                final r = entry.value;
                return '''
$i. ${r.title}
   PMID: ${r.id}
   Score: ${r.score.toStringAsFixed(2)}
   Date: ${r.publicationDate?.toString().split(' ')[0] ?? 'N/A'}
   ${r.shortAbstract}
   ${r.sourceUrl}
''';
              })
              .join('\n${'=' * 60}\n');
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Search failed: $e';
        _results = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elasticsearch Connection Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Card(
              color:
                  _status.startsWith('✅')
                      ? Colors.green[50]
                      : _status.startsWith('❌')
                      ? Colors.red[50]
                      : Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (_isLoading) const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _status,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testConnection,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Test Connection'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createIndex,
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text('Create Index'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search section
            const Text(
              'Test Search',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Search Query',
                hintText: 'Enter medical term to search...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _isLoading ? null : (_) => _testSearch(),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testSearch,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Results section
            if (_results.isNotEmpty) ...[
              const Text(
                'Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      _results,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
