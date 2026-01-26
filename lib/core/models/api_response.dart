class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? token;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.token,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['status'] as bool? ?? json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['user'] != null ? fromJsonT(json['user']) : json['data'] != null ? fromJsonT(json['data']) : null,
      token: json['token'] as String?,
    );
  }
}

// In api_response.dart
class User {
  final String id;
  final String name;
  final String mobile_no;
  final String? token;
  final String? password;

  User({
    required this.id,
    required this.name,
    required this.mobile_no,
    this.token,
    this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      mobile_no: json['mobile_no'] ?? json['phone'] ?? '',
      token: json['token'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile_no': mobile_no,
      'phone': mobile_no,
      'token': token,
      'password': password,
    };
  }

  String get phone => mobile_no;
}