import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/features/notes/presentation/note_editor_screen.dart';

void showCreateNoteDialog(BuildContext context, WidgetRef ref) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const NoteEditorScreen()),
  );
}
