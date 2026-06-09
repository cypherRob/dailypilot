class LiveRoomModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final int memberCount;
  final bool isActive;
  final String createdBy;
  final String createdByName;
  final String? createdByProfileImageUrl;

  LiveRoomModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.memberCount,
    required this.isActive,
    required this.createdBy,
    required this.createdByName,
    this.createdByProfileImageUrl,
  });

  factory LiveRoomModel.fromMap(Map<String, dynamic> map, String id) {
    return LiveRoomModel(
      id: id,
      title: map['title'] ?? 'Untitled room',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      memberCount: map['memberCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? 'Unknown author',
      createdByProfileImageUrl: _cleanImageUrl(map['createdByProfileImageUrl']),
    );
  }
}

String? _cleanImageUrl(Object? value) {
  final url = value?.toString().trim();
  if (url == null || url.isEmpty) return null;
  return url;
}
