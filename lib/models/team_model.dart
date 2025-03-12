class TeamModel {
  final String id;
  final String name;
  final String code;
  final String createdBy;
  final List<Map<String, dynamic>> members;
  final bool isTeacher;
  final DateTime createdAt;
  final String? status;

  TeamModel({
    required this.id,
    required this.name,
    required this.code,
    required this.createdBy,
    required this.members,
    required this.isTeacher,
    DateTime? createdAt,
    this.status,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    print("Raw JSON from Supabase: $json");
    try {
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
        status: json['status'],
      );
    } catch (e) {
      print("Error parsing team JSON: $e");
      print("JSON keys: ${json.keys.toList()}");
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'teamid': id,
      'teamname': name,
      'teamcode': code,
      'createdby': createdBy,
      'members': members,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }
}
