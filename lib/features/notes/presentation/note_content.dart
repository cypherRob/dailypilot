import 'dart:convert';

enum NoteContentType { document, spreadsheet }

class NoteContent {
  final NoteContentType type;
  final String text;
  final List<List<String>> cells;

  const NoteContent.document(this.text)
    : type = NoteContentType.document,
      cells = const [];

  const NoteContent.spreadsheet(this.cells)
    : type = NoteContentType.spreadsheet,
      text = '';

  factory NoteContent.parse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['kind'] == 'spreadsheet') {
        final rows = decoded['cells'];
        if (rows is List) {
          return NoteContent.spreadsheet(
            rows
                .map(
                  (row) => row is List
                      ? row.map((cell) => cell?.toString() ?? '').toList()
                      : <String>[],
                )
                .toList(),
          );
        }
      }

      if (decoded is Map<String, dynamic> && decoded['kind'] == 'document') {
        return NoteContent.document(decoded['text']?.toString() ?? '');
      }
    } catch (_) {}

    return NoteContent.document(body);
  }

  String serialize() {
    return switch (type) {
      NoteContentType.document => jsonEncode({
        'kind': 'document',
        'text': text,
      }),
      NoteContentType.spreadsheet => jsonEncode({
        'kind': 'spreadsheet',
        'cells': cells,
      }),
    };
  }

  String preview() {
    return switch (type) {
      NoteContentType.document =>
        text
            .replaceAll(RegExp(r'[*_~#>`\[\]]'), '')
            .replaceAll('\n', ' ')
            .trim(),
      NoteContentType.spreadsheet =>
        cells
            .expand((row) => row)
            .where((cell) => cell.trim().isNotEmpty)
            .take(6)
            .join(' | '),
    };
  }
}
