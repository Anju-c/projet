class CommentModel {
  final String commentid;
  final String taskid;
  final String userid;
  final String content;
  final DateTime createdat;

  CommentModel({
    required this.commentid,
    required this.taskid,
    required this.userid,
    required this.content,
    required this.createdat,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentid: json['commentid'] as String,
      taskid: json['taskid'] as String,
      userid: json['userid'] as String,
      content: json['content'] as String,
      createdat: DateTime.parse(json['createdat'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentid': commentid,
      'taskid': taskid,
      'userid': userid,
      'content': content,
      'createdat': createdat.toIso8601String(),
    };
  }
}
