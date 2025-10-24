import 'dart:io';

import 'package:flutter/material.dart';
import 'package:medicortex/domains/settings/entity/mcp_server_config.dart';
import 'package:medicortex/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'domains/conversation/services/conversation_database.dart';
import 'domains/settings/data/settings_repository_impl.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/pages/analytics_page.dart';
import 'presentation/screens/research_workspace_screen.dart';
import 'providers/theme_provider.dart';
import 'utils/env_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Initialize Drift database
  await ConversationDatabase.initialize();

  // Create directory for filesystem MCP server
  await _ensureMedicortexDirectory();

  final initialSettingsRepo = SettingsRepositoryImpl(prefs);

  // Get API key from settings, fallback to environment variable
  String? initialApiKey = await initialSettingsRepo.getApiKey();
  if (initialApiKey == null || initialApiKey.isEmpty) {
    final envApiKey = EnvLoader.geminiApiKey;
    if (envApiKey.isNotEmpty) {
      initialApiKey = envApiKey;
      debugPrint('✅ Using Gemini API key from environment');
    }
  }

  final savedServerList = await initialSettingsRepo.getMcpServerList();

  // Merge default servers with saved servers
  final initialServerList = _mergeWithDefaultServers(savedServerList);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        settingsRepositoryProvider.overrideWith(
          (ref) => SettingsRepositoryImpl(ref.watch(sharedPreferencesProvider)),
        ),
        apiKeyProvider.overrideWith((ref) => initialApiKey),
        mcpServerListProvider.overrideWith((ref) => initialServerList),
      ],
      child: const MyApp(),
    ),
  );
}

/// Merges default MCP servers with user's saved servers
List<McpServerConfig> _mergeWithDefaultServers(
  List<McpServerConfig> savedServers,
) {
  // Default servers
  final defaultServers = [
    // McpServerConfig(
    //   id: 'default-filesystem',
    //   name: 'File System (Research Notes)',
    //   command: 'npx',
    //   args: '-y @modelcontextprotocol/server-filesystem /tmp/medicortex',
    //   isActive: true,
    //   customEnvironment: const {},
    // ),
  ];

  // Get IDs of saved servers
  final savedIds = savedServers.map((s) => s.id).toSet();

  // Add default servers that aren't already saved
  final defaultsToAdd =
      defaultServers.where((d) => !savedIds.contains(d.id)).toList();

  // Merge: defaults first, then user's servers
  return [...defaultsToAdd, ...savedServers];
}

/// Ensures the MediCortex directory exists for the filesystem MCP server
Future<void> _ensureMedicortexDirectory() async {
  try {
    final dir = Directory('/tmp/medicortex');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      debugPrint('Created MediCortex directory: ${dir.path}');
    }
  } catch (e) {
    debugPrint('Warning: Could not create MediCortex directory: $e');
    // Non-fatal, app can still function
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Medicortex AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const ResearchWorkspaceScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/analytics': (context) => const AnalyticsPage(),
      },
    );
  }
}
