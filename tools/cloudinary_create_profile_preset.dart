#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const cloudName = 'YOUR_CLOUD_NAME';
const apiKey = 'YOUR_API_KEY';
const apiSecret = 'YOUR_API_SECRET';
const presetName = 'finotes_profile_images_unsigned';
const imageDatabase = 'finotes_images/profile_pictures';

Future<void> main() async {
  final credentials = base64Encode(utf8.encode('$apiKey:$apiSecret'));
  final response = await http.post(
    Uri.https('api.cloudinary.com', '/v1_1/$cloudName/upload_presets'),
    headers: {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'name': presetName,
      'unsigned': 'true',
      'folder': imageDatabase,
      'tags': 'finotes,user_profile,image_database',
      'use_filename': 'false',
      'unique_filename': 'true',
    },
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    stdout.writeln('Created unsigned upload preset: $presetName');
    stdout.writeln('Folder: $imageDatabase');
    return;
  }

  if (response.statusCode == 409 || response.body.contains('already exists')) {
    stdout.writeln('Unsigned upload preset already exists: $presetName');
    stdout.writeln('Folder: $imageDatabase');
    return;
  }

  throw StateError(
    'Could not create upload preset (${response.statusCode}): ${response.body}',
  );
}
