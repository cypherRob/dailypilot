import 'package:flutter/material.dart';
import 'package:dailypilot/features/notes/presentation/note_content.dart';
import 'package:dailypilot/features/notes/presentation/widgets/formatted_note_body.dart';
import 'package:dailypilot/shared/models/note_model.dart';

class NoteDetailScreen extends StatelessWidget {
  final NoteModel note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final content = NoteContent.parse(note.body);

    return Scaffold(
      appBar: AppBar(title: Text(note.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    content.type == NoteContentType.spreadsheet
                        ? Icons.grid_on_outlined
                        : Icons.description_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    content.type == NoteContentType.spreadsheet
                        ? 'Spreadsheet'
                        : 'Document',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (content.type == NoteContentType.document)
                FormattedNoteBody(text: content.text)
              else
                _SpreadsheetView(cells: content.cells),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpreadsheetView extends StatelessWidget {
  final List<List<String>> cells;

  const _SpreadsheetView({required this.cells});

  @override
  Widget build(BuildContext context) {
    final columnCount = cells.fold<int>(
      0,
      (max, row) => row.length > max ? row.length : max,
    );
    final safeColumnCount = columnCount == 0 ? 1 : columnCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(140),
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          TableRow(
            children: [
              for (var column = 0; column < safeColumnCount; column++)
                _cell(String.fromCharCode(65 + column), isHeader: true),
            ],
          ),
          for (final row in cells)
            TableRow(
              children: [
                for (var column = 0; column < safeColumnCount; column++)
                  _cell(column < row.length ? row[column] : ''),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool isHeader = false}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      color: isHeader ? Colors.grey.shade100 : null,
      alignment: isHeader ? Alignment.center : Alignment.centerLeft,
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(fontWeight: isHeader ? FontWeight.bold : null),
      ),
    );
  }
}
