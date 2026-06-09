import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dailypilot/core/sync/local_db.dart';
import 'package:dailypilot/shared/models/note_model.dart';
import 'package:dailypilot/shared/models/sync_status.dart';

part 'note_repository.g.dart';

@riverpod
class NoteRepository extends _$NoteRepository {
  @override
  Stream<List<NoteModel>> build() {
    final isar = ref.watch(localDbProvider);
    return isar.noteModels
        .filter()
        .isDeletedEqualTo(false)
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<void> addNote(String title, String body) async {
    final isar = ref.read(localDbProvider);
    final note = NoteModel()
      ..title = title
      ..body = body
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..syncStatus = SyncStatus.pendingCreate;

    await isar.writeTxn(() async {
      await isar.noteModels.put(note);
    });
  }

  Future<void> deleteNote(int id) async {
    final isar = ref.read(localDbProvider);
    final note = await isar.noteModels.get(id);
    if (note != null) {
      note.isDeleted = true;
      note.syncStatus = SyncStatus.pendingDelete;
      note.updatedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.noteModels.put(note);
      });
    }
  }
}
