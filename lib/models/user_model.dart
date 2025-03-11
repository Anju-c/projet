class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? accessCode;
  final bool isTeacher; // Derived from role

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.accessCode,
  }) : isTeacher = role == 'teacher';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['userid'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      accessCode: json['accesscode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': id,
      'name': name,
      'email': email,
      'role': role,
      'accesscode': accessCode,
    };
  }
}
