import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:image_picker/image_picker.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class GeminiService {
  final GenerativeModel _model;

  GeminiService()
    : _model = FirebaseAI.vertexAI().generativeModel(
        model: 'gemini-2.0-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: _transactionSchema,
        ),
      );

  static final Schema _transactionSchema = Schema.object(
    properties: {
      'amount': Schema.number(),
      'currency': Schema.string(),
      'category': Schema.enumString(
        enumValues: [
          'food',
          'transport',
          'bills',
          'shopping',
          'school',
          'work',
          'health',
          'entertainment',
          'other',
        ],
      ),
      'type': Schema.enumString(enumValues: ['expense', 'income']),
      'note': Schema.string(),
    },
  );

  Future<Map<String, dynamic>> parseNaturalLanguage(String text) async {
    final prompt =
        '''
You are a financial assistant. Parse the following text and extract one transaction into JSON.
Use type "income" for salary, allowance, pocket money, stipend, refund, or money received. Use type "expense" for spending.
Ensure the output matches this schema exactly:
{
  "amount": number (e.g. 50.5),
  "currency": string (3 letter code, e.g. "USD", "JPY", "EUR". Default to "USD" if unknown),
  "category": string (must be one of: food, transport, bills, shopping, school, work, health, entertainment, other),
  "type": string (must be "expense" or "income"),
  "note": string (a short description)
}

Text: "$text"
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    return _decodeTransaction(response.text);
  }

  Future<Map<String, dynamic>> parseReceipt(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();

    final prompt = '''
You are a financial assistant. Read this receipt image and extract the total expense details into JSON format.
Ensure the output matches this schema exactly:
{
  "amount": number (e.g. 50.5),
  "currency": string (3 letter code, e.g. "USD", "JPY", "EUR". Default to "USD" if unknown),
  "category": string (guess one of: food, transport, bills, shopping, school, work, health, entertainment, other),
  "type": string (always "expense"),
  "note": string (store name or short description)
}
''';

    final response = await _model.generateContent([
      Content.multi([
        TextPart(prompt),
        InlineDataPart(imageFile.mimeType ?? 'image/jpeg', bytes),
      ]),
    ]);

    final parsed = _decodeTransaction(response.text);
    parsed['type'] = 'expense';
    return parsed;
  }

  Map<String, dynamic> _decodeTransaction(String? text) {
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('No response from AI.');
    }

    final trimmed = text.trim();
    final jsonStart = trimmed.indexOf('{');
    final jsonEnd = trimmed.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd <= jsonStart) {
      throw FormatException('AI returned invalid JSON: $trimmed');
    }

    final decoded = jsonDecode(trimmed.substring(jsonStart, jsonEnd + 1));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('AI response was not a JSON object.');
    }

    return {
      'amount': decoded['amount'],
      'currency': (decoded['currency'] ?? 'USD').toString().toUpperCase(),
      'category': (decoded['category'] ?? 'other').toString().toLowerCase(),
      'type': (decoded['type'] ?? 'expense').toString().toLowerCase(),
      'note': (decoded['note'] ?? '').toString(),
    };
  }
}
