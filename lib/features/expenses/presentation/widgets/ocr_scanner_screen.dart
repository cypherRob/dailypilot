import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dailypilot/features/expenses/data/gemini_service.dart';
import 'package:dailypilot/shared/models/expense_model.dart';
import 'package:dailypilot/features/expenses/presentation/widgets/create_expense_dialog.dart';

class OcrScannerScreen extends ConsumerStatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  ConsumerState<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends ConsumerState<OcrScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _processImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() => _isProcessing = true);

    try {
      final gemini = ref.read(geminiServiceProvider);
      final result = await gemini.parseReceipt(image);

      if (mounted) {
        final catStr = result['category']?.toString().toLowerCase();
        final category = ExpenseCategory.values.firstWhere(
          (e) => e.name == catStr,
          orElse: () => ExpenseCategory.other,
        );

        Navigator.pop(context); // Close scanner screen

        showCreateExpenseDialog(
          context,
          ref,
          initialAmount: (result['amount'] as num?)?.toDouble(),
          initialCurrency: result['currency']?.toString(),
          initialCategory: category,
          initialType: ExpenseType.expense,
          initialNote: result['note']?.toString(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process receipt: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI is analyzing the receipt...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.document_scanner,
                    size: 100,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _processImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _processImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                  ),
                ],
              ),
      ),
    );
  }
}
