import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  String? _token;

  Future<String?> get token async {
    _token ??= await _storage.read(key: AppConstants.prefToken);
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _storage.write(key: AppConstants.prefToken, value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: AppConstants.prefToken);
  }

  Future<Map<String, String>> _headers() async {
    final t = await token;
    return {'Content-Type': 'application/json', if (t != null) 'Authorization': 'Bearer $t'};
  }

  Future<ApiResponse> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}$endpoint'), headers: await _headers());
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.post(Uri.parse('${AppConstants.baseUrl}$endpoint'), headers: await _headers(), body: body != null ? jsonEncode(body) : null);
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final response = await http.put(Uri.parse('${AppConstants.baseUrl}$endpoint'), headers: await _headers(), body: body != null ? jsonEncode(body) : null);
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }

  Future<ApiResponse> delete(String endpoint) async {
    try {
      final response = await http.delete(Uri.parse('${AppConstants.baseUrl}$endpoint'), headers: await _headers());
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      return ApiResponse(success: false, message: 'Connection error: $e');
    }
  }
}

class ApiResponse {
  final bool success;
  final String? message;
  final dynamic data;
  final int? statusCode;

  ApiResponse({required this.success, this.message, this.data, this.statusCode});

  factory ApiResponse.fromHttpResponse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = {'message': response.body};
    }
    return ApiResponse(
      success: response.statusCode >= 200 && response.statusCode < 300,
      message: body['message']?.toString(),
      data: body['data'],
      statusCode: response.statusCode,
    );
  }
}
