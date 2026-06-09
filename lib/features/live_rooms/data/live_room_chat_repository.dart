import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dailypilot/features/live_rooms/data/live_profile_repository.dart';
import 'package:dailypilot/shared/models/live_room_message_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'live_room_chat_repository.g.dart';

@riverpod
Stream<int> liveRoomMemberCount(LiveRoomMemberCountRef ref, String roomId) {
  if (Firebase.apps.isEmpty) return Stream.value(0);

  final controller = StreamController<int>();
  var latestPresence = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

  void emitOnlineCount() {
    final activeSince = DateTime.now().subtract(const Duration(minutes: 2));
    final count = latestPresence.where((doc) {
      final timestamp = doc.data()['timestamp'];
      return timestamp is Timestamp && timestamp.toDate().isAfter(activeSince);
    }).length;
    if (!controller.isClosed) controller.add(count);
  }

  final subscription = FirebaseFirestore.instance
      .collection('live_rooms')
      .doc(roomId)
      .collection('presence')
      .snapshots()
      .listen((snapshot) {
        latestPresence = snapshot.docs;
        emitOnlineCount();
      });
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    emitOnlineCount();
  });

  ref.onDispose(() {
    timer.cancel();
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
}

final liveRoomJoinedCountProvider = StreamProvider.autoDispose
    .family<int, String>((ref, roomId) {
      if (Firebase.apps.isEmpty) return Stream.value(0);

      return FirebaseFirestore.instance
          .collection('live_rooms')
          .doc(roomId)
          .collection('joined_members')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    });

@riverpod
class LiveRoomChatRepository extends _$LiveRoomChatRepository {
  @override
  Stream<List<LiveRoomMessageModel>> build(String roomId) async* {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not configured for live chat.');
    }

    await _currentUser;
    await _liveProfile;

    yield* FirebaseFirestore.instance
        .collection('live_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return LiveRoomMessageModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<void> sendMessage(String text) async {
    if (Firebase.apps.isEmpty) return;

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;
    final user = await _currentUser;
    final profile = await _liveProfile;

    final message = LiveRoomMessageModel(
      id: '',
      text: trimmedText,
      senderId: user.uid,
      senderName: profile.username,
      senderProfileImageUrl: profile.profileImageUrl,
      timestamp: DateTime.now(),
    );

    await _messagesCollection.add(message.toMap());
    await _recordJoinedMember(user: user, profile: profile);
  }

  Future<void> joinRoom() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final user = await _currentUser;
      final profile = await _liveProfile;

      await FirebaseFirestore.instance
          .collection('live_rooms')
          .doc(roomId)
          .collection('presence')
          .doc(user.uid)
          .set({
            'userId': user.uid,
            'username': profile.username,
            if (profile.profileImageUrl != null)
              'profileImageUrl': profile.profileImageUrl,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> leaveRoom() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final user = await _currentUser;
      await FirebaseFirestore.instance
          .collection('live_rooms')
          .doc(roomId)
          .collection('presence')
          .doc(user.uid)
          .delete();
    } catch (_) {}
  }

  CollectionReference<Map<String, dynamic>> get _messagesCollection =>
      FirebaseFirestore.instance
          .collection('live_rooms')
          .doc(roomId)
          .collection('messages');

  Future<void> _recordJoinedMember({
    required User user,
    required LiveProfile profile,
  }) async {
    final joinedRef = FirebaseFirestore.instance
        .collection('live_rooms')
        .doc(roomId)
        .collection('joined_members')
        .doc(user.uid);

    final data = <String, dynamic>{
      'userId': user.uid,
      'username': profile.username,
      'lastInteractionAt': FieldValue.serverTimestamp(),
      'interactionCount': FieldValue.increment(1),
    };
    if (profile.profileImageUrl != null) {
      data['profileImageUrl'] = profile.profileImageUrl;
    }

    try {
      await joinedRef.set(data, SetOptions(merge: true));
    } catch (_) {
      // The message is already sent; writer counters should not block chat.
    }
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
