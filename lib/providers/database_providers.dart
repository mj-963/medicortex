import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domains/conversation/services/conversation_database.dart';

/// Provider for Drift database instance
final driftDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  return await ConversationDatabase.initialize();
});

/// Provider to check if database is initialized
final isDatabaseInitializedProvider = Provider<bool>((ref) {
  final databaseAsync = ref.watch(driftDatabaseProvider);
  return databaseAsync.when(
    data: (_) => true,
    loading: () => false,
    error: (_, __) => false,
  );
});
