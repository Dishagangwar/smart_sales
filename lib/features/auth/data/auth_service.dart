import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smart_sales/features/auth/data/models/create_admin_respone.dart';

import 'models/login_request_model.dart';

class AuthService {
  final String baseUrl = "https://chamanmarblel.onrender.com";

  Future<dynamic> login(LoginRequestModel request) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request.toJson()),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200 && decoded['success'] == true) {
      final data = decoded['data'];
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final sessionId = data['sessionId'];

      print("Login Success");

      return decoded;
    } else {
      throw Exception("Login Failed");
    }
  }
  
  Future<CreateAdminResponse> createAdmin({
  required String firstName,
  required String lastName,
  required String email,
  required List<String> phone,
  required Map<String, dynamic> location,
  required String token, // Pass the token from your secure storage
}) async {
  final response = await http.post(
    Uri.parse("$baseUrl/api/users"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token", // Required by your doc
    },
    body: jsonEncode({
      "firstName": firstName,
      "lastName": lastName,
      "email": email,
      "phone": phone,
      "location": location,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return CreateAdminResponse.fromJson(data);
  } else {
    return CreateAdminResponse(
      success: false,
      message: data['message'] ?? "Failed to create admin",
    );
  }
}
Future<Map<String, dynamic>> forgotPassword(String email) async {
  final response = await http.post(
    Uri.parse("$baseUrl/api/auth/forgot-password"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": email}),
  );

  return jsonDecode(response.body);
}
Future<Map<String, dynamic>> resetPassword({
  required String email,
  required String otp,
  required String newPassword,
}) async {
  final response = await http.post(
    Uri.parse("$baseUrl/api/auth/reset-password"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "email": email,
      "otp": otp,
      "newPassword": newPassword,
    }),
  );

  return jsonDecode(response.body);
}
}
