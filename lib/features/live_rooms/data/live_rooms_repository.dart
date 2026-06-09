import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dailypilot/features/live_rooms/data/live_profile_repository.dart';
import 'package:dailypilot/shared/models/live_room_model.dart';

part 'live_rooms_repository.g.dart';

@riverpod
class LiveRoomsRepository extends _$LiveRoomsRepository {
  @override
  Stream<List<LiveRoomModel>> build() async* {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not configured for live rooms.');
    }

    await _currentUser;
    await _liveProfile;

    yield* FirebaseFirestore.instance
        .collection('live_rooms')
        .where('isActive', isEqualTo: true)
        .orderBy('title')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return LiveRoomModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<void> createRoom({
    required String title,
    required String description,
    required String category,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not configured for live rooms.');
    }

    final profile = await _liveProfile;

    await FirebaseFirestore.instance.collection('live_rooms').add({
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim().isEmpty ? 'General' : category.trim(),
      'memberCount': 0,
      'isActive': true,
      'createdBy': (await _currentUser).uid,
      'createdByName': profile.username,
      'createdByProfileImageUrl': profile.profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRoom(String roomId) async {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not configured for live rooms.');
    }

    final user = await _currentUser;
    final roomRef = FirebaseFirestore.instance
        .collection('live_rooms')
        .doc(roomId);
    final snapshot = await roomRef.get();
    final room = snapshot.data();

    if (room == null) return;
    if (room['createdBy'] != user.uid) {
      throw StateError('Only the creator can delete this public note.');
    }

    await roomRef.delete();
  }

  Future<User> get _currentUser async {
    final auth = FirebaseAuth.instance;
    try {
      return auth.currentUser ?? (await auth.signInAnonymously()).user!;
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

  Future<LiveProfile> get _liveProfile async {
    final profile = await ref.read(liveProfileProvider.future);
    if (profile == null) {
      throw StateError('Live profile is required.');
    }

    return profile;
  }
}
