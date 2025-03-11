class TeamModel {
  final String id;
  final String name;
  final String code;
  final String createdBy;
  final List<Map<String, dynamic>> members;
  final bool isTeacher; // Whether the current user is a teacher in this team
  final DateTime createdAt; // When the team was created

  TeamModel({
    required this.id,
    required this.name,
    required this.code,
    required this.createdBy,
    required this.members,
    required this.isTeacher,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['teamid'],
      name: json['teamname'],
      code: json['teamcode'],
      createdBy: json['createdby'],
      members: (json['members'] as List).cast<Map<String, dynamic>>(),
      isTeacher: json['is_teacher'] ?? false,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamid': id,
      'teamname': name,
      'teamcode': code,
      'createdby': createdBy,
      'members': members,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
