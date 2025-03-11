class FileModel {
  final String filePath;
  final String fileName;
  final String uploadedBy;
  final DateTime uploadedAt;

  FileModel({
    required this.filePath,
    required this.fileName,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      filePath: json['file_path'],
      fileName: json['file_name'],
      uploadedBy: json['uploaded_by'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_path': filePath,
      'file_name': fileName,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}
