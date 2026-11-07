enum UserRole {
  user('ROLE_USER'),
  technician('ROLE_TECHNICIAN'),
  admin('ROLE_ADMIN');

  const UserRole(this.roleName);
  final String roleName;

  bool get isAdmin => this == UserRole.admin;
  bool get isTechnician => this == UserRole.technician;
  bool get isUser => this == UserRole.user;
  bool get isAgent => isAdmin || isTechnician;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.user;
    final normalized = role.toUpperCase().replaceAll('ROLE_', '').trim();
    return switch (normalized) {
      'ADMIN' => UserRole.admin,
      'TECHNICIAN' => UserRole.technician,
      _ => UserRole.user,
    };
  }
}
