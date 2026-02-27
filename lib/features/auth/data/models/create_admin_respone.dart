class CreateAdminResponse {
  final bool success;
  final String message;
  final AdminData? data;

  CreateAdminResponse({required this.success, required this.message, this.data});

  factory CreateAdminResponse.fromJson(Map<String, dynamic> json) {
    return CreateAdminResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AdminData.fromJson(json['data']) : null,
    );
  }
}

class AdminData {
  final String id;
  final String username;
  final String password;

  AdminData({required this.id, required this.username, required this.password});

  factory AdminData.fromJson(Map<String, dynamic> json) {
    return AdminData(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
    );
  }
}