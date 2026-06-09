import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/features/live_rooms/data/live_profile_repository.dart';
import 'package:dailypilot/features/live_rooms/data/live_room_chat_repository.dart';
import 'package:dailypilot/shared/models/live_room_message_model.dart';
import 'package:dailypilot/shared/widgets/profile_avatar.dart';

class LiveRoomChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String roomTitle;

  const LiveRoomChatScreen({
    super.key,
    required this.roomId,
    required this.roomTitle,
  });

  @override
  ConsumerState<LiveRoomChatScreen> createState() => _LiveRoomChatScreenState();
}

class _LiveRoomChatScreenState extends ConsumerState<LiveRoomChatScreen> {
  final TextEditingController _textController = TextEditingController();
  Timer? _presenceHeartbeat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(liveRoomChatRepositoryProvider(widget.roomId).notifier)
          .joinRoom();
      _presenceHeartbeat = Timer.periodic(const Duration(seconds: 45), (_) {
        ref
            .read(liveRoomChatRepositoryProvider(widget.roomId).notifier)
            .joinRoom();
      });
    });
  }

  @override
  void dispose() {
    _presenceHeartbeat?.cancel();
    ref
        .read(liveRoomChatRepositoryProvider(widget.roomId).notifier)
        .leaveRoom();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      liveRoomChatRepositoryProvider(widget.roomId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomTitle, style: const TextStyle(fontSize: 18)),
            Consumer(
              builder: (context, ref, child) {
                final onlineCount =
                    ref
                        .watch(liveRoomMemberCountProvider(widget.roomId))
                        .valueOrNull ??
                    0;
                final joinedCount =
                    ref
                        .watch(liveRoomJoinedCountProvider(widget.roomId))
                        .valueOrNull ??
                    0;
                return Text(
                  '$onlineCount online now, $joinedCount writers',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe =
                        msg.senderId == FirebaseAuth.instance.currentUser?.uid;
                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.grey),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                onChanged: (val) {
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _textController.text.isNotEmpty ? _sendTextMessage : null,
              /* Audio recording hidden as requested
              onLongPressStart: _textController.text.isEmpty
                  ? (_) => _startRecording()
                  : null,
              onLongPressEnd: _textController.text.isEmpty
                  ? (_) => _stopRecordingAndSend()
                  : null,
              */
              child: CircleAvatar(
                backgroundColor: _textController.text.isNotEmpty
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTextMessage() async {
    final message = _textController.text;
    _textController.clear();
    setState(() {});

    try {
      await ref
          .read(liveRoomChatRepositoryProvider(widget.roomId).notifier)
          .sendMessage(message);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send message: $error')));
    }
  }
}

class _MessageBubble extends ConsumerWidget {
  final LiveRoomMessageModel message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = message.senderProfileImageUrl == null
        ? ref.watch(liveProfileByUserIdProvider(message.senderId)).valueOrNull
        : null;
    final profileImageUrl =
        message.senderProfileImageUrl ?? profile?.profileImageUrl;
    final senderName = profile?.username ?? message.senderName;
    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16).copyWith(
          topRight: isMe ? Radius.zero : const Radius.circular(16),
          topLeft: isMe ? const Radius.circular(16) : Radius.zero,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMe) ...[
            Text(
              senderName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
          ],
          if (message.isAudio)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  icon: Icon(
                    Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Voice message',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            )
          else
            Text(
              message.text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: isMe ? TextDirection.rtl : TextDirection.ltr,
        children: [
          ProfileAvatar(imageUrl: profileImageUrl, radius: 14),
          const SizedBox(width: 8),
          bubble,
        ],
      ),
    );
  }
}
