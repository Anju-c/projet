class UserModel {
  final String id;
  final String email;
  final String name;

  final String role; // Added role field

  UserModel({
    required this.id,
    required this.email,
    required this.name,

    required this.role, // Include role in constructor
  });

  String get userid => id;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['userid'] as String,
      email: json['email'] as String,
      name: json['name'] as String,

      role: json['role'] as String, // Include role in fromJson
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': id,
      'email': email,
      'name': name,

      'role': role, // Include role in toJson
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,

    String? role, // Include role in copyWith
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,

      role: role ?? this.role, // Include role in copyWith
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          role == other.role; // Include role in equality check

  @override
  int get hashCode => Object.hash(id, email, name, role); // Include role in hashCode
}
