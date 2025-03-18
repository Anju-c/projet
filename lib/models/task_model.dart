import 'package:flutter/foundation.dart';

enum TaskStatus {
  todo,
  inProgress,
  done;

  String toJson() => name;
  static TaskStatus fromJson(String json) => values.byName(json);
}

class Comment {
  final String id;
  final String content;
  final String userId;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.content,
    required this.userId,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      content: json['content'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String teamId;
  final String assignedTo;
  final String createdBy;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime dueDate;
  final List<Comment> comments;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.teamId,
    required this.assignedTo,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.dueDate,
    List<Comment>? comments,
  }) : comments = comments ?? [];

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      teamId: json['team_id'] as String,
      assignedTo: json['assigned_to'] as String,
      createdBy: json['created_by'] as String,
      status: TaskStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      comments: (json['comments'] as List<dynamic>?)
          ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'team_id': teamId,
      'assigned_to': assignedTo,
      'created_by': createdBy,
      'status': status.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'comments': comments.map((e) => e.toJson()).toList(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? teamId,
    String? assignedTo,
    String? createdBy,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    List<Comment>? comments,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      teamId: teamId ?? this.teamId,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      comments: comments ?? this.comments,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          teamId == other.teamId &&
          assignedTo == other.assignedTo &&
          createdBy == other.createdBy &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          dueDate == other.dueDate &&
          listEquals(comments, other.comments);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        teamId,
        assignedTo,
        createdBy,
        status,
        createdAt,
        updatedAt,
        dueDate,
        Object.hashAll(comments),
      );
}
