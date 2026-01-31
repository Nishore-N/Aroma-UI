import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

final Map<String, User> _tempUserStore = {};

class AuthService with ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  String? _token;
  User? _user;
  bool _isLoading = true;
  final Map<String, User> _tempUserStore = {};

  bool get isAuthenticated => _user != null && _user!.id.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get token => _token;
  User? get user => _user;

  // =========================
  // INIT
  // =========================
  Future<void> initialize() async {
    try {
      _isLoading = true;
      
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      final userData = prefs.getString(_userKey);

      if (userData != null) {
        final userMap = jsonDecode(userData) as Map<String, dynamic>;
        _user = User.fromJson(userMap);
        
        // If this is a temp user, add to temp store for login validation
        if (_token?.startsWith('temp_token_') == true) {
          _tempUserStore[_user!.phone] = _user!;
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _token = null;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // SAVE AUTH
  // =========================
  Future<void> _saveAuth(User user) async {
    debugPrint('=== SAVE AUTH DEBUG ===');
    debugPrint('Saving user: ${user.name}');
    debugPrint('User token: ${user.token}');
    debugPrint('User mobile: ${user.mobile_no}');
    debugPrint('User ID: ${user.id}');
    
    final prefs = await SharedPreferences.getInstance();
    
    // Save token if available, otherwise save user ID as authentication proof
    if (user.token != null && user.token!.isNotEmpty) {
      await prefs.setString(_tokenKey, user.token!);
      _token = user.token;
    } else {
      // Use user ID as authentication proof when no token is provided
      await prefs.setString(_tokenKey, user.id);
      _token = user.id;
    }
    
    // Convert user to JSON and ensure password is included
    final userJson = user.toJson();
    if (user.password != null) {
      userJson['password'] = user.password;
    }
    
    await prefs.setString(_userKey, jsonEncode(userJson));
    _user = user;
    
    debugPrint('Before notifyListeners - isAuthenticated: $isAuthenticated');
    debugPrint('Notifying listeners...');
    notifyListeners();
    debugPrint('After notifyListeners - isAuthenticated: $isAuthenticated');
    notifyListeners();
    debugPrint('=== SAVE AUTH COMPLETE ===');
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      _token = null;
      _user = null;
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Logout error: $e');
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // LOGIN
  // =========================
  Future<ApiResponse<User>> login({
    required String phone,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      debugPrint('Attempting login for phone: $phone');
      debugPrint('Temporary users: ${_tempUserStore.keys.toList()}');
      
      // First try to find user in temp storage
      if (_tempUserStore.containsKey(phone)) {
        debugPrint('Found user in temp storage');
        final user = _tempUserStore[phone]!;
        if (user.password == password) {
          debugPrint('Password matches, logging in');
          await _saveAuth(user);
          return ApiResponse<User>(
            success: true,
            message: 'Login successful',
            data: user,
            token: user.token,
          );
        } else {
          debugPrint('Invalid password');
          return ApiResponse<User>(
            success: false,
            message: 'Invalid password',
          );
        }
      }
      
      debugPrint('User not found in temp storage, trying API');
      // If not in temp storage, try API
      try {
        final response = await ApiService.loginUser(
          phone: phone,
          password: password,
        );
        
        if (response.success && response.data != null) {
          debugPrint('API login successful');
          await _saveAuth(response.data!);
          return response;
        }
        
        debugPrint('API login failed: ${response.message}');
        return ApiResponse<User>(
          success: false,
          message: response.message ?? 'Login failed',
        );
      } catch (e) {
        debugPrint('API login error: $e');
        return ApiResponse<User>(
          success: false,
          message: 'Login failed. Please check your credentials and try again.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Login error: $e\n$stackTrace');
      return ApiResponse<User>(
        success: false,
        message: 'An error occurred during login',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // LOGIN WITH OTP
  // =========================
  Future<ApiResponse<User>> loginWithOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      debugPrint('Attempting OTP login for phone: $phone');
      
      // Try OTP login with API
      try {
        final response = await ApiService.loginUserWithOtp(
          phone: phone,
          otp: otp,
        );
        
        if (response.success && response.data != null) {
          debugPrint('API OTP login successful');
          await _saveAuth(response.data!);
          return response;
        }
        
        debugPrint('API OTP login failed: ${response.message}');
        return ApiResponse<User>(
          success: false,
          message: response.message ?? 'OTP login failed',
        );
      } catch (e) {
        debugPrint('API OTP login error: $e');
        return ApiResponse<User>(
          success: false,
          message: 'OTP login failed. Please check your OTP and try again.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('OTP Login error: $e\n$stackTrace');
      return ApiResponse<User>(
        success: false,
        message: 'An error occurred during OTP login',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // REGISTER
  // =========================
  Future<ApiResponse<User>> register({
    required String phone,
    required String name,
    required String password,
  }) async {
    try {
      debugPrint('Starting registration for: $name');
      _isLoading = true;
      notifyListeners();
      
      // Try to register with the API
      debugPrint('Calling register API...');
      final response = await ApiService.registerUser(
        phone: phone,
        name: name,
        password: password,
      );

      debugPrint('API Response: ${response.success} - ${response.message}');
      
      if (response.success && response.data != null) {
        debugPrint('Registration successful via API');
        return response;
      }
      
      debugPrint('Using fallback registration');
      // Fallback: Store user in temporary storage
      final mockUser = User(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        mobile_no: phone,
        password: password,
        token: 'temp_token_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Store in temporary storage
      _tempUserStore[phone] = mockUser;

      
      debugPrint('Fallback registration successful');
      return ApiResponse<User>(
        success: true,
        message: 'Registration successful (temporary)',
        data: mockUser,
);
    } catch (e, stackTrace) {
      debugPrint('Registration error: $e');
      debugPrint('Stack trace: $stackTrace');
      return ApiResponse<User>(
        success: false,
        message: 'Registration failed: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('Registration process completed');
    }
  }
}