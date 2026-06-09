class LiveRoomMessageModel {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final String? senderProfileImageUrl;
  final DateTime timestamp;
  final bool isAudio;
  final String? audioUrl;

  LiveRoomMessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    this.senderProfileImageUrl,
    required this.timestamp,
    this.isAudio = false,
    this.audioUrl,
  });

  factory LiveRoomMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return LiveRoomMessageModel(
      id: id,
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Anonymous',
      senderProfileImageUrl: _cleanImageUrl(map['senderProfileImageUrl']),
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      isAudio: map['isAudio'] ?? false,
      audioUrl: map['audioUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isAudio': isAudio,
    };
    if (senderProfileImageUrl != null) {
      map['senderProfileImageUrl'] = senderProfileImageUrl!;
    }
    if (audioUrl != null) {
      map['audioUrl'] = audioUrl!;
    }

    return map;
  }
}

String? _cleanImageUrl(Object? value) {
  final url = value?.toString().trim();
  if (url == null || url.isEmpty) return null;
  return url;
}
