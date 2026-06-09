import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/features/notes/data/note_repository.dart';
import 'package:dailypilot/features/notes/presentation/note_content.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _spreadsheetControllers = List.generate(
    8,
    (_) => List.generate(5, (_) => TextEditingController()),
  );
  NoteContentType _type = NoteContentType.document;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    for (final row in _spreadsheetControllers) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<NoteContentType>(
                    segments: const [
                      ButtonSegment(
                        value: NoteContentType.document,
                        icon: Icon(Icons.description_outlined),
                        label: Text('Document'),
                      ),
                      ButtonSegment(
                        value: NoteContentType.spreadsheet,
                        icon: Icon(Icons.grid_on_outlined),
                        label: Text('Spreadsheet'),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (selection) {
                      setState(() => _type = selection.first);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _type == NoteContentType.document
                  ? _buildDocumentEditor()
                  : _buildSpreadsheetEditor(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentEditor() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _formatButton(Icons.title, 'Heading', () => _prefixLine('# ')),
              _formatButton(Icons.format_bold, 'Bold', () {
                _wrapSelection('**', '**');
              }),
              _formatButton(Icons.format_italic, 'Italic', () {
                _wrapSelection('_', '_');
              }),
              _formatButton(Icons.format_underlined, 'Underline', () {
                _wrapSelection('~', '~');
              }),
              _formatButton(Icons.format_list_bulleted, 'Bullet', () {
                _prefixLine('- ');
              }),
              _formatButton(Icons.format_align_center, 'Center', () {
                _prefixLine('[center]');
              }),
              _formatButton(Icons.format_align_right, 'Right', () {
                _prefixLine('[right]');
              }),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TextField(
            controller: _bodyController,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Write your note...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpreadsheetEditor() {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(140),
            border: TableBorder.all(color: Colors.grey.shade300),
            children: [
              TableRow(
                children: [
                  for (var column = 0; column < 5; column++)
                    _headerCell(String.fromCharCode(65 + column)),
                ],
              ),
              for (var row = 0; row < _spreadsheetControllers.length; row++)
                TableRow(
                  children: [
                    for (
                      var column = 0;
                      column < _spreadsheetControllers[row].length;
                      column++
                    )
                      _spreadsheetCell(row, column),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String label) {
    return Container(
      height: 36,
      alignment: Alignment.center,
      color: Colors.grey.shade100,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _spreadsheetCell(int row, int column) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _spreadsheetControllers[row][column],
        decoration: InputDecoration(
          hintText: '${String.fromCharCode(65 + column)}${row + 1}',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _formatButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }

  void _wrapSelection(String before, String after) {
    final selection = _bodyController.selection;
    final text = _bodyController.text;
    if (!selection.isValid || selection.isCollapsed) {
      final offset = selection.baseOffset < 0
          ? text.length
          : selection.baseOffset;
      _bodyController.text = text.replaceRange(offset, offset, '$before$after');
      _bodyController.selection = TextSelection.collapsed(
        offset: offset + before.length,
      );
      return;
    }

    _bodyController.text = text.replaceRange(
      selection.start,
      selection.end,
      '$before${text.substring(selection.start, selection.end)}$after',
    );
    _bodyController.selection = TextSelection(
      baseOffset: selection.start + before.length,
      extentOffset: selection.end + before.length,
    );
  }

  void _prefixLine(String prefix) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    final offset = selection.baseOffset < 0
        ? text.length
        : selection.baseOffset;
    final lineStart = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0) + 1;

    _bodyController.text = text.replaceRange(lineStart, lineStart, prefix);
    _bodyController.selection = TextSelection.collapsed(
      offset: offset + prefix.length,
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final content = _type == NoteContentType.document
        ? NoteContent.document(_bodyController.text.trim())
        : NoteContent.spreadsheet(
            _spreadsheetControllers
                .map((row) => row.map((cell) => cell.text.trim()).toList())
                .toList(),
          );

    if (content.preview().isEmpty) return;

    setState(() => _isSaving = true);
    await ref
        .read(noteRepositoryProvider.notifier)
        .addNote(title, content.serialize());

    if (mounted) Navigator.pop(context);
  }
}
