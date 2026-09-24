import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

/// Standardised exception for all API errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Low-level HTTP client wrapper.
/// All requests go through here so auth headers and error handling are centralised.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  String? _token;

  void setToken(String? token) => _token = token;
  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final baseUri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return baseUri.replace(queryParameters: queryParameters);
    }
    return baseUri;
  }

  /// Decode response and throw [ApiException] for non-2xx status.
  dynamic _process(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      body['message'] as String? ?? 'Request failed',
      statusCode: response.statusCode,
    );
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParameters}) async {
    try {
      final res = await http
          .get(_uri(path, queryParameters: queryParameters), headers: _headers)
          .timeout(ApiConfig.timeout);
      return _process(res);
    } on SocketException {
      throw const ApiException('Cannot reach the server. Check your network connection.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(ApiConfig.timeout);
      return _process(res);
    } on SocketException {
      throw const ApiException('Cannot reach the server. Check your network connection.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .put(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(ApiConfig.timeout);
      return _process(res);
    } on SocketException {
      throw const ApiException('Cannot reach the server. Check your network connection.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    try {
      final res = await http
          .patch(
            _uri(path),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);
      return _process(res);
    } on SocketException {
      throw const ApiException('Cannot reach the server. Check your network connection.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final res = await http
          .delete(_uri(path), headers: _headers)
          .timeout(ApiConfig.timeout);
      return _process(res);
    } on SocketException {
      throw const ApiException('Cannot reach the server. Check your network connection.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }
}
