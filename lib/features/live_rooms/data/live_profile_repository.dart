import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _liveUsernameKey = 'live_username';
const _liveEmailKey = 'live_email';
const _liveBioKey = 'live_bio';
const _liveLocationKey = 'live_location';
const _liveProfileImageUrlKey = 'live_profile_image_url';
const googleGroupEmail = 'filobus_@googlegroups.com';
const googleGroupSubscribeEmail = 'filobus_+subscribe@googlegroups.com';
const _cloudinaryCloudName = String.fromEnvironment(
  'CLOUDINARY_CLOUD_NAME',
  defaultValue: 'ddarj1mal',
);
const _cloudinaryUploadPreset = String.fromEnvironment(
  'CLOUDINARY_UPLOAD_PRESET',
  defaultValue: 'finotes_profile_images_unsigned',
);
final liveProfileProvider = FutureProvider<LiveProfile?>((ref) async {
  final preferences = await SharedPreferences.getInstance();
  final username = preferences.getString(_liveUsernameKey)?.trim();
  final email = preferences.getString(_liveEmailKey)?.trim();

  final bio = preferences.getString(_liveBioKey)?.trim();
  final location = preferences.getString(_liveLocationKey)?.trim();
  final profileImageUrl = _cleanProfileImageUrl(
    preferences.getString(_liveProfileImageUrlKey),
  );

  if (username == null || username.isEmpty || email == null || email.isEmpty) {
    return null;
  }

  return LiveProfile(
    username: username,
    email: email,
    bio: bio ?? '',
    location: location ?? '',
    profileImageUrl: profileImageUrl,
  );
});

final liveProfileByUserIdProvider = FutureProvider.family<LiveProfile?, String>(
  (ref, userId) async {
    if (Firebase.apps.isEmpty || userId.isEmpty) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('live_profiles')
        .doc(userId)
        .get();
    final data = snapshot.data();
    if (data == null) return null;

    final username = data['username']?.toString().trim() ?? '';
    final email = data['email']?.toString().trim() ?? '';
    if (username.isEmpty || email.isEmpty) return null;

    return LiveProfile(
      username: username,
      email: email,
      bio: data['bio']?.toString().trim() ?? '',
      location: data['location']?.toString().trim() ?? '',
      profileImageUrl: _cleanProfileImageUrl(data['profileImageUrl']),
    );
  },
);

class LiveProfile {
  final String username;
  final String email;
  final String bio;
  final String location;
  final String? profileImageUrl;

  const LiveProfile({
    required this.username,
    required this.email,
    required this.bio,
    required this.location,
    this.profileImageUrl,
  });
}

class LiveProfileRepository {
  static Future<void> save({
    required String username,
    required String email,
    String bio = '',
    String location = '',
    Uint8List? avatarBytes,
    String? existingProfileImageUrl,
  }) async {
    final trimmedUsername = username.trim();
    final trimmedEmail = email.trim();
    final trimmedBio = bio.trim();
    final trimmedLocation = location.trim();

    if (trimmedUsername.isEmpty || trimmedEmail.isEmpty) {
      throw ArgumentError('Username and email are required.');
    }

    String? finalProfileImageUrl = existingProfileImageUrl;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_liveUsernameKey, trimmedUsername);
    await preferences.setString(_liveEmailKey, trimmedEmail);
    await preferences.setString(_liveBioKey, trimmedBio);
    await preferences.setString(_liveLocationKey, trimmedLocation);

    if (Firebase.apps.isEmpty) return;

    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ?? (await _signInAnonymously()).user;
    if (user == null) return;

    if (avatarBytes != null) {
      finalProfileImageUrl = await _uploadAvatarImage(
        avatarBytes: avatarBytes,
        userId: user.uid,
      );
    }

    if (finalProfileImageUrl != null) {
      await preferences.setString(
        _liveProfileImageUrlKey,
        finalProfileImageUrl,
      );
    }

    await user.updateDisplayName(trimmedUsername);
    if (finalProfileImageUrl != null) {
      await user.updatePhotoURL(finalProfileImageUrl);
    }

    final data = <String, dynamic>{
      'username': trimmedUsername,
      'email': trimmedEmail,
      'bio': trimmedBio,
      'location': trimmedLocation,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (finalProfileImageUrl != null) {
      data['profileImageUrl'] = finalProfileImageUrl;
    }

    await FirebaseFirestore.instance
        .collection('live_profiles')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  static Future<bool> openGoogleGroupSubscribeEmail(LiveProfile profile) {
    final uri = Uri(
      scheme: 'mailto',
      path: googleGroupSubscribeEmail,
      queryParameters: {
        'subject': 'Subscribe',
        'body':
            'Please subscribe ${profile.username} (${profile.email}) to $googleGroupEmail.',
      },
    );

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<UserCredential> _signInAnonymously() async {
    try {
      return await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'configuration-not-found' ||
          error.message?.contains('CONFIGURATION_NOT_FOUND') == true) {
        throw StateError(
          'Firebase Authentication is not initialized. Enable Anonymous sign-in in Firebase Console.',
        );
      }

      if (error.code == 'operation-not-allowed') {
        throw StateError(
          'Anonymous sign-in is disabled. Enable Anonymous sign-in in Firebase Console.',
        );
      }

      rethrow;
    }
  }

  static Future<String> _uploadAvatarImage({
    required Uint8List avatarBytes,
    required String userId,
  }) async {
    if (_cloudinaryCloudName.isEmpty || _cloudinaryUploadPreset.isEmpty) {
      throw StateError(
        'Cloudinary is required for profile images. Provide CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET.',
      );
    }

    final uri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$_cloudinaryCloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          avatarBytes,
          filename: 'profile_$userId.jpg',
        ),
      );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        json is Map<String, dynamic> &&
        json['secure_url'] is String) {
      return json['secure_url'] as String;
    }

    final error = json is Map<String, dynamic> ? json['error'] : null;
    final message = error is Map<String, dynamic>
        ? error['message']?.toString()
        : null;
    throw StateError(message ?? 'Cloudinary avatar upload failed.');
  }
}

String? _cleanProfileImageUrl(Object? value) {
  final url = value?.toString().trim();
  if (url == null || url.isEmpty) return null;
  return url;
}
