import 'package:flutter/material.dart';

class FormattedNoteBody extends StatelessWidget {
  final String text;

  const FormattedNoteBody({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final line in lines) _buildLine(context, line)],
    );
  }

  Widget _buildLine(BuildContext context, String line) {
    final trimmed = line.trimRight();
    final theme = Theme.of(context);
    TextAlign align = TextAlign.start;
    var content = trimmed;

    if (content.startsWith('[center]')) {
      align = TextAlign.center;
      content = content.substring(8);
    } else if (content.startsWith('[right]')) {
      align = TextAlign.right;
      content = content.substring(7);
    }

    if (content.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          content.substring(2),
          textAlign: align,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final isBullet = content.startsWith('- ');
    final body = isBullet ? content.substring(2) : content;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBullet) ...[const Text('•  ', style: TextStyle(fontSize: 16))],
          Expanded(
            child: RichText(
              textAlign: align,
              text: TextSpan(
                style: theme.textTheme.bodyLarge,
                children: _parseInline(body),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _parseInline(String text) {
    final spans = <TextSpan>[];
    var index = 0;

    while (index < text.length) {
      final markers = <_Marker>[
        _Marker('**', '**', const TextStyle(fontWeight: FontWeight.bold)),
        _Marker('_', '_', const TextStyle(fontStyle: FontStyle.italic)),
        _Marker(
          '~',
          '~',
          const TextStyle(decoration: TextDecoration.underline),
        ),
      ];
      _Match? best;

      for (final marker in markers) {
        final start = text.indexOf(marker.open, index);
        if (start == -1) continue;
        final end = text.indexOf(marker.close, start + marker.open.length);
        if (end == -1) continue;
        final match = _Match(marker, start, end);
        if (best == null || match.start < best.start) best = match;
      }

      if (best == null) {
        spans.add(TextSpan(text: text.substring(index)));
        break;
      }

      if (best.start > index) {
        spans.add(TextSpan(text: text.substring(index, best.start)));
      }

      spans.add(
        TextSpan(
          text: text.substring(best.start + best.marker.open.length, best.end),
          style: best.marker.style,
        ),
      );
      index = best.end + best.marker.close.length;
    }

    return spans;
  }
}

class _Marker {
  final String open;
  final String close;
  final TextStyle style;

  const _Marker(this.open, this.close, this.style);
}

class _Match {
  final _Marker marker;
  final int start;
  final int end;

  const _Match(this.marker, this.start, this.end);
}
