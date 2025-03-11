class TaskModel {
  final String taskId;
  final String title;
  final String description;
  final String createdBy;
  final String assignedTo;
  final String teamId;
  final String status;
  final DateTime dueDate;
  final String priority;
  final List<dynamic> attachments;
  final List<dynamic> comments;

  TaskModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.assignedTo,
    required this.teamId,
    required this.status,
    required this.dueDate,
    required this.priority,
    required this.attachments,
    required this.comments,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      taskId: map['taskid'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdby'] ?? '',
      assignedTo: map['assignedto'] ?? '',
      teamId: map['teamid'] ?? '',
      status: map['status'] ?? '',
      dueDate: DateTime.tryParse(map['duedate'] ?? '') ?? DateTime.now(),
      priority: map['priority'] ?? '',
      attachments: map['attachments'] ?? [],
      comments: map['comments'] ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskid': taskId,
      'title': title,
      'description': description,
      'createdby': createdBy,
      'assignedto': assignedTo,
      'teamid': teamId,
      'status': status,
      'duedate': dueDate.toIso8601String(),
      'priority': priority,
      'attachments': attachments,
      'comments': comments,
    };
  }
}
