import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a configured Appwrite [Client].
final appwriteClientProvider = Provider<Client>((ref) {
  final client = Client()
      .setEndpoint('https://fra.cloud.appwrite.io/v1')
      .setProject(const String.fromEnvironment("APPW_PROJECT"));

  return client;
});

/// Provides an Appwrite [Functions] instance.
final appwriteFunctionsProvider = Provider<Functions>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Functions(client);
});

/// Lightweight wrapper for invoking the Firebase Manager function with arbitrary
/// method + path + data + auth header (JWT).
class FunctionsClient {
  FunctionsClient({
    required this.functions,
    required this.functionId,
    this.debug = false,
  });

  final Functions functions;
  final String functionId;
  final bool debug;

  /// Execute a request expecting JSON body in the function's response.
  ///
  /// [method] HTTP method (GET / POST / PUT / DELETE).
  /// [path] path like `/auth/login` or `/projects`.
  /// [data] optional JSON map body (will be encoded).
  ///
  /// Returns decoded JSON (Map or List). Throws [FunctionsClientException] on
  /// network or parse issues. Caller should still inspect the `success` field
  /// of the returned JSON if the API uses a success envelope.
  Future<dynamic> execJson({
    String? customFunctionId,
    required String method,
    required String path,
    Map<String, dynamic>? data,
  }) async {
    // Build headers (Authorization optional).
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final bodyString =
        data == null ? '' : jsonEncode(data, toEncodable: _toEncodable);

    if (debug) {
      debugPrint(
        '[FunctionsClient] -> $method $path '
        'headers=${headers.keys.toList()} body=$bodyString',
      );
    }

    try {
      final execution = await functions.createExecution(
        functionId: customFunctionId ?? functionId,
        method: _mapMethod(method),
        path: path.isEmpty ? '/' : path,
        body: bodyString,
        headers: headers,
      );

      final responseBody = execution.responseBody;
      if (debug) {
        debugPrint(
          '[FunctionsClient] <- status=${execution.status} '
          'code=${execution.responseStatusCode} body=$responseBody',
        );
      }

      if (responseBody.isEmpty) {
        throw FunctionsClientException(
          'EMPTY_RESPONSE',
          'Empty response body from function',
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(responseBody);
      } catch (e) {
        throw FunctionsClientException(
          'INVALID_JSON',
          'Failed to parse JSON: ${e.toString().split('\n').first}',
        );
      }

      return decoded;
    } on AppwriteException catch (e, st) {
      if (debug) {
        debugPrint('[FunctionsClient] AppwriteException: ${e.message} $st');
      }
      throw FunctionsClientException(
        e.code?.toString() ?? 'APPWRITE_ERROR',
        e.message ?? 'Unknown Appwrite error',
      );
    } catch (e, st) {
      if (debug) {
        debugPrint('[FunctionsClient] Unknown error: $e $st');
      }
      throw FunctionsClientException('UNKNOWN', e.toString());
    }
  }

  ExecutionMethod _mapMethod(String raw) {
    switch (raw.toUpperCase()) {
      case 'GET':
        return ExecutionMethod.gET;
      case 'POST':
        return ExecutionMethod.pOST;
      case 'PUT':
        return ExecutionMethod.pUT;
      case 'DELETE':
        return ExecutionMethod.dELETE;
      case 'PATCH':
        return ExecutionMethod.pATCH;
      default:
        return ExecutionMethod.pOST;
    }
  }

  /// Safe JSON encode for unsupported objects.
  dynamic _toEncodable(Object? value) {
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }
}

/// Exception thrown by [FunctionsClient].
class FunctionsClientException implements Exception {
  FunctionsClientException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'FunctionsClientException(code=$code, message=$message)';
}

/// High-level wrapper provider (auto picks up token changes).
final functionsClientProvider = Provider<FunctionsClient>((ref) {
  final functions = ref.watch(appwriteFunctionsProvider);
  return FunctionsClient(
    functions: functions,
    functionId: const String.fromEnvironment("ELASTIC_SEARCH"),
    debug: const String.fromEnvironment("DEBUG_LOGGING") == "true",
  );
});
