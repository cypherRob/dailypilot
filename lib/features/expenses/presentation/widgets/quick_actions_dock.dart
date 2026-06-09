import 'package:flutter/material.dart';
import 'package:dailypilot/features/expenses/presentation/widgets/create_expense_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/features/expenses/presentation/widgets/nlp_input_sheet.dart';
import 'package:dailypilot/features/expenses/presentation/widgets/ocr_scanner_screen.dart';
import 'package:dailypilot/shared/models/expense_model.dart';

class QuickActionsDock extends ConsumerWidget {
  const QuickActionsDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DockButton(
            icon: Icons.remove,
            label: 'Manual',
            onTap: () => showCreateExpenseDialog(context, ref),
          ),
          const SizedBox(width: 16),
          _DockButton(
            icon: Icons.add,
            label: 'Income',
            onTap: () => showCreateExpenseDialog(
              context,
              ref,
              initialType: ExpenseType.income,
            ),
          ),
          const SizedBox(width: 16),
          _DockButton(
            icon: Icons.chat,
            label: 'Smart Input',
            onTap: () => showNlpInputSheet(context, ref),
          ),
          const SizedBox(width: 16),
          _DockButton(
            icon: Icons.document_scanner,
            label: 'Scan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OcrScannerScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DockButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
