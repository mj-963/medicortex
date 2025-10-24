#!/usr/bin/env dart

library;

/// Helper script to convert env.json to encoded format for --dart-define-from-file
///
/// Usage: dart scripts/encode_env.dart

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() {
  final envFile = File('env.json');

  if (!envFile.existsSync()) {
    print('❌ env.json not found in project root');
    print('Please create env.json from env.example.json');
    exit(1);
  }

  try {
    // Read the original env.json
    final jsonString = envFile.readAsStringSync();
    final config = jsonDecode(jsonString) as Map<String, dynamic>;

    // Create the encoded version
    final encodedConfig = <String, dynamic>{};

    for (final entry in config.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is Map || value is List) {
        // Encode objects and arrays as JSON strings
        encodedConfig[key] = jsonEncode(value);
      } else {
        // Keep primitives as-is
        encodedConfig[key] = value;
      }
    }

    // Backup original env.json
    final backupFile = File('env.original.json');
    if (!backupFile.existsSync()) {
      envFile.copySync('env.original.json');
      print('📦 Backed up original env.json to env.original.json');
    }

    // Overwrite env.json with encoded version
    envFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(encodedConfig),
    );

    print('✅ Converted env.json to encoded format');
    print('');
    print('Now you can run:');
    print('  flutter run --dart-define-from-file=env.json');
    print('');
    print('This works on ALL platforms (web, mobile, desktop).');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
