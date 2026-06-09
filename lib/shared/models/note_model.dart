import 'package:isar/isar.dart';
import 'package:dailypilot/shared/models/sync_status.dart';

part 'note_model.g.dart';

@collection
class NoteModel {
  Id id = Isar.autoIncrement;

  String? userId;

  late String title;

  late String body;

  List<String> tags = [];

  bool isPinned = false;

  bool isFavorite = false;

  late DateTime createdAt;

  late DateTime updatedAt;

  @enumerated
  SyncStatus syncStatus = SyncStatus.localOnly;

  bool isDeleted = false;
}
