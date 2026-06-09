#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

const cloudName = 'YOUR_CLOUD_NAME';
const apiKey = 'YOUR_API_KEY';
const apiSecret = 'YOUR_API_SECRET';
const imageDatabase = 'finotes_images/onboarding';
const sampleImageUrl =
    'https://res.cloudinary.com/demo/image/upload/sample.jpg';

Future<void> main() async {
  final uploadResult = await uploadImage();
  final secureUrl = uploadResult['secure_url'] as String;
  final publicId = uploadResult['public_id'] as String;

  stdout.writeln('Uploaded image secure URL: $secureUrl');
  stdout.writeln('Uploaded image public ID: $publicId');

  final details = await getImageDetails(publicId);
  stdout.writeln('Image width: ${details['width']}');
  stdout.writeln('Image height: ${details['height']}');
  stdout.writeln('Image format: ${details['format']}');
  stdout.writeln('Image file size bytes: ${details['bytes']}');

  // f_auto lets Cloudinary select the best image format for the browser.
  // q_auto lets Cloudinary select a good quality/compression balance.
  final transformedUrl =
      'https://res.cloudinary.com/$cloudName/image/upload/f_auto,q_auto/$publicId';

  stdout.writeln(
    'Done! Click link below to see optimized version of the image. Check the size and the format.',
  );
  stdout.writeln(transformedUrl);
}

Future<Map<String, dynamic>> uploadImage() async {
  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final parameters = <String, String>{
    'folder': imageDatabase,
    'tags': 'finotes,onboarding,image_database',
    'timestamp': timestamp.toString(),
  };
  final signature = signParameters(parameters);

  final request =
      http.MultipartRequest(
          'POST',
          Uri.https('api.cloudinary.com', '/v1_1/$cloudName/image/upload'),
        )
        ..fields['file'] = sampleImageUrl
        ..fields['api_key'] = apiKey
        ..fields['folder'] = imageDatabase
        ..fields['tags'] = 'finotes,onboarding,image_database'
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature;

  final response = await request.send();
  final body = await response.stream.bytesToString();
  final json = jsonDecode(body);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError('Upload failed (${response.statusCode}): $body');
  }

  return json as Map<String, dynamic>;
}

Future<Map<String, dynamic>> getImageDetails(String publicId) async {
  final credentials = base64Encode(utf8.encode('$apiKey:$apiSecret'));
  final uri = Uri.https(
    'api.cloudinary.com',
    '/v1_1/$cloudName/resources/image/upload/$publicId',
  );
  final response = await http.get(
    uri,
    headers: {'Authorization': 'Basic $credentials'},
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError(
      'Metadata lookup failed (${response.statusCode}): ${response.body}',
    );
  }

  return jsonDecode(response.body) as Map<String, dynamic>;
}

String signParameters(Map<String, String> parameters) {
  final payload =
      parameters.entries.where((entry) => entry.value.isNotEmpty).toList()
        ..sort((a, b) => a.key.compareTo(b.key));
  final signatureBase =
      '${payload.map((entry) => '${entry.key}=${entry.value}').join('&')}$apiSecret';
  return sha1.convert(utf8.encode(signatureBase)).toString();
}
