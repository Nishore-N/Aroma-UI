import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../constants/api_endpoints.dart';

class ApiService {
  static String get baseUrl => ApiEndpoints.baseUrl;

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // =========================
  // INTERNAL REQUEST HANDLER
  // =========================
  static Future<ApiResponse<T>> _handleRequest<T>(
    Future<http.Response> request,
    T Function(Object? json) fromJsonT,
  ) async {
    try {
      debugPrint('Making API request...');
      final response = await request;
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      final contentType = response.headers['content-type'] ?? '';
      debugPrint('Content-Type: $contentType');

      // 🚨 CRITICAL CHECK
      if (!contentType.contains('application/json')) {
        debugPrint('Non-JSON response received');
        return ApiResponse<T>(
          success: false,
          message: 'Server returned non-JSON response: ${response.body}',
          data: null,
        );
      }

      final Map<String, dynamic> responseData =
          jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('Parsed response: $responseData');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<T>.fromJson(responseData, fromJsonT);
      } else {
        debugPrint('API Error: ${response.statusCode} - ${responseData['message']}');
        return ApiResponse<T>(
          success: false,
          message: responseData['message']?.toString() ?? 'An error occurred',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Network/Parse error: $e');
      return ApiResponse<T>(
        success: false,
        message: 'Connection error: $e',
        data: null,
      );
    }
  }

  // =========================
  // REGISTER USER
  // =========================
  static Future<ApiResponse<User>> registerUser({
    required String phone,
    required String name,
    // required String email, // Removed - not required by API
    required String password,
  }) {
    final url = Uri.parse(ApiEndpoints.registerUser);
    debugPrint('Register URL: $url');
    debugPrint('Register data: mobile_no=$phone, name=$name');

    return _handleRequest<User>(
      http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'mobile_no': phone, // Changed from phone to mobile_no
          'name': name,
          // 'email': email, // Removed - not required by API
          'password': password,
        }),
      ),
      (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  // =========================
  // LOGIN USER
  // =========================
  static Future<ApiResponse<User>> loginUser({
    required String phone,
    required String password,
  }) {
    final url = Uri.parse(ApiEndpoints.loginUser);
    debugPrint('Login URL: $url');
    debugPrint('Login data: mobile_no=$phone');

    return _handleRequest<User>(
      http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'mobile_no': phone, // Changed from phone to mobile_no
          'password': password,
        }),
      ),
      (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  // =========================
  // LOGIN USER WITH OTP
  // =========================
  static Future<ApiResponse<User>> loginUserWithOtp({
    required String phone,
    required String otp,
  }) {
    final url = Uri.parse(ApiEndpoints.loginUserOtp);
    debugPrint('OTP Login URL: $url');
    debugPrint('OTP Login data: mobile_no=$phone, otp=$otp');

    return _handleRequest<User>(
      http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'mobile_no': phone, // Changed from phone to mobile_no
          'otp': otp,
        }),
      ),
      (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }
}
