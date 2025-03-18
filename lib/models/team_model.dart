class TeamModel {
  final String teamid;
  final String teamname;
  final String teamcode;
  final String status;
  final String createdby;
   final bool hasJoined;

  TeamModel({
    required this.teamid,
    required this.teamname,
    required this.teamcode,
    required this.status,
    required this.createdby,
     this.hasJoined = false,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      teamid: json['teamid'] as String,
      teamname: json['teamname'] as String,
      teamcode: json['teamcode'] as String,
      status: json['status'] as String,
      createdby: json['createdby'] as String,
       hasJoined: json['hasJoined'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamid': teamid,
      'teamname': teamname,
      'teamcode': teamcode,
      'status': status,
      'createdby': createdby,
      'hasJoined': hasJoined,
      'hasJoined': hasJoined,
    };
  }

  TeamModel copyWith({
    String? teamid,
    String? teamname,
    String? teamcode,
    String? status,
    String? createdBy,
    bool? hasJoined,
  }) {
    return TeamModel(
      teamid: teamid ?? this.teamid,
      teamname: teamname ?? this.teamname,
      teamcode: teamcode ?? this.teamcode,
      status: status ?? this.status,
      createdby: createdBy ?? this.createdby,
      hasJoined: hasJoined ?? this.hasJoined,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamModel &&
        other.teamid == teamid &&
        other.teamname == teamname &&
        other.teamcode == teamcode &&
        other.status == status &&
        other.createdby == createdby &&
        other.hasJoined == hasJoined;
  }

  @override
  int get hashCode =>
      Object.hash(teamid, teamname, teamcode, status, createdby,hasJoined);
}
