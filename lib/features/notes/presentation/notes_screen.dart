import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/features/notes/data/note_repository.dart';
import 'package:dailypilot/features/notes/presentation/note_content.dart';
import 'package:dailypilot/features/notes/presentation/note_detail_screen.dart';
import 'package:dailypilot/features/notes/presentation/widgets/create_note_dialog.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(noteRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Private Notes')),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('No notes yet. Create one!'));
          }
          return ListView.builder(
            itemCount: notes.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final note = notes[index];
              final content = NoteContent.parse(note.body);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoteDetailScreen(note: note),
                      ),
                    );
                  },
                  leading: Icon(
                    content.type == NoteContentType.spreadsheet
                        ? Icons.grid_on_outlined
                        : Icons.description_outlined,
                  ),
                  title: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    content.preview().isEmpty
                        ? 'Tap to read note'
                        : content.preview(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      ref
                          .read(noteRepositoryProvider.notifier)
                          .deleteNote(note.id);
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showCreateNoteDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
