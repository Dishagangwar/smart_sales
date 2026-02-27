enum UserRole {
  ADMIN,
  SUPER_ADMIN,
}
extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.ADMIN:
        return "ADMIN";
      case UserRole.SUPER_ADMIN:
        return "SUPER_ADMIN";
    }
  }
}