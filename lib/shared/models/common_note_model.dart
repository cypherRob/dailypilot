class CommonNoteModel {
  final String id;
  final String createdBy;
  final String username;
  final String text;
  final String category;
  final DateTime createdAt;
  final int likesCount;

  CommonNoteModel({
    required this.id,
    required this.createdBy,
    required this.username,
    required this.text,
    required this.category,
    required this.createdAt,
    this.likesCount = 0,
  });

  bool canBeDeletedBy(String? userId) {
    return userId != null && userId.isNotEmpty && userId == createdBy;
  }
}
