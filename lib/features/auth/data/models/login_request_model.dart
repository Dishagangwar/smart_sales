class LoginRequestModel {
  final String username;
  final String password;
  final String loginAsRole;

  LoginRequestModel({
    required this.username,
    required this.password,
    required this.loginAsRole,
  });

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "password": password,
      "loginAsRole": loginAsRole,
    };
  }
}