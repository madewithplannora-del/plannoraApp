import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../storage/storage_service.dart';
import 'api_exception.dart';

bool _isUnauthorized(ApiException e) => e.statusCode == 401;

/*
    Called when an authenticated request is rejected with 401. The stored token
    is dead (expired without a refresh endpoint), so drop the stored session so
    the next app start lands on the login screen instead of failing forever.
*/
Future<void> _handleAuthRevoked(StorageService storage) async {
  try {
    await storage.clearAll();
  } catch (_) {
    // best effort; never mask the original API error
  }
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final StorageService _storage = StorageService();
  final http.Client _client = http.Client();

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final url = '${ApiConfig.baseUrl}$cleanPath';
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      return Uri.parse(url).replace(queryParameters: stringParams);
    }
    return Uri.parse(url);
  }

  Future<Map<String, String>> _headers({bool requiresAuth = true, bool isJson = true}) async {
    final headers = <String, String>{};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }
    if (requiresAuth) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      // Non-JSON response (e.g., HTML error or plain text)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'message': response.body};
      }
      throw ApiException(
        message: 'Server returned unexpected response (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    String message = 'An error occurred (${response.statusCode})';
    if (body is Map) {
      if (body['message'] != null) {
        message = body['message'].toString();
      } else if (body['error'] != null) {
        message = body['error'].toString();
      }
    }

    throw ApiException(
      message: message,
      statusCode: response.statusCode,
      details: body,
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(path, queryParams);
      final headers = await _headers(requiresAuth: requiresAuth);
      final response = await _client
          .get(uri, headers: headers)
          .timeout(ApiConfig.timeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Unable to connect to PlanEra server. Please check your internet connection.',
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out. The server may be waking up, please try again.',
      );
    } on ApiException catch (e) {
      if (requiresAuth && _isUnauthorized(e)) {
        await _handleAuthRevoked(_storage);
      }
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unexpected network error: $e');
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path);
      final baseHeaders = await _headers(requiresAuth: requiresAuth);
      baseHeaders.addAll(headers ?? const {});
      final payload = body != null ? jsonEncode(body) : null;
      final response = await _client
          .post(uri, headers: baseHeaders, body: payload)
          .timeout(ApiConfig.timeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Unable to connect to PlanEra server. Please check your internet connection.',
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out. The server may be waking up, please try again.',
      );
    } on ApiException catch (e) {
      if (requiresAuth && _isUnauthorized(e)) {
        await _handleAuthRevoked(_storage);
      }
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unexpected network error: $e');
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _headers(requiresAuth: requiresAuth);
      final payload = body != null ? jsonEncode(body) : null;
      final response = await _client
          .put(uri, headers: headers, body: payload)
          .timeout(ApiConfig.timeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Unable to connect to PlanEra server. Please check your internet connection.',
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out. The server may be waking up, please try again.',
      );
    } on ApiException catch (e) {
      if (requiresAuth && _isUnauthorized(e)) {
        await _handleAuthRevoked(_storage);
      }
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unexpected network error: $e');
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _headers(requiresAuth: requiresAuth);
      final payload = body != null ? jsonEncode(body) : null;
      final response = await _client
          .patch(uri, headers: headers, body: payload)
          .timeout(ApiConfig.timeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Unable to connect to PlanEra server. Please check your internet connection.',
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out. The server may be waking up, please try again.',
      );
    } on ApiException catch (e) {
      if (requiresAuth && _isUnauthorized(e)) {
        await _handleAuthRevoked(_storage);
      }
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unexpected network error: $e');
    }
  }

  Future<dynamic> delete(
    String path, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _headers(requiresAuth: requiresAuth);
      final response = await _client
          .delete(uri, headers: headers)
          .timeout(ApiConfig.timeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Unable to connect to PlanEra server. Please check your internet connection.',
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out. The server may be waking up, please try again.',
      );
    } on ApiException catch (e) {
      if (requiresAuth && _isUnauthorized(e)) {
        await _handleAuthRevoked(_storage);
      }
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unexpected network error: $e');
    }
  }

  Future<dynamic> multipartRequest({
    required String method,
    required String path,
    required Map<String, String> fields,
    String? fileField,
    String? filePath,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(path);
      final request = http.MultipartRequest(method, uri);

      if (requiresAuth) {
        final token = await _storage.getToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      if (fileField != null && filePath != null && filePath.isNotEmpty) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            request.files.add(
              await http.MultipartFile.fromPath(fileField, filePath),
            );
          }
        } catch (_) {
          // On web, file paths don't work the same way
          // File upload will be skipped but request continues
        }
      }

      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Unable to connect to PlanEra server. Please check your internet connection.',
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out. The upload took too long or server is waking up.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Unexpected multipart upload error: $e');
    }
  }
}
