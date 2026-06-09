import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dailypilot/core/network/connectivity_service.dart';
import 'package:dailypilot/features/live_rooms/data/live_profile_repository.dart';
import 'package:dailypilot/features/live_rooms/data/live_rooms_repository.dart';
import 'package:dailypilot/features/live_rooms/data/live_room_chat_repository.dart';
import 'package:dailypilot/features/live_rooms/presentation/live_room_chat_screen.dart';
import 'package:dailypilot/shared/models/live_room_model.dart';
import 'package:dailypilot/shared/widgets/profile_avatar.dart';

class LiveRoomsScreen extends ConsumerWidget {
  const LiveRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(connectivityServiceProvider);
    final profileAsync = ref.watch(liveProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Public Notes')),
      floatingActionButton: isOnlineAsync.maybeWhen(
        data: (isOnline) => isOnline && profileAsync.valueOrNull != null
            ? FloatingActionButton(
                onPressed: () => _showCreateRoomDialog(context, ref),
                child: const Icon(Icons.add),
              )
            : null,
        orElse: () => null,
      ),
      body: isOnlineAsync.when(
        data: (isOnline) {
          if (!isOnline) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "You're offline.",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      "Public notes require internet. Your personal dashboard is still available.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          return profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return LiveProfileForm(
                  onSaved: () => ref.invalidate(liveProfileProvider),
                );
              }

              return _buildOnlineRoomsList(context, ref, profile);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildOnlineRoomsList(
    BuildContext context,
    WidgetRef ref,
    LiveProfile profile,
  ) {
    final roomsAsync = ref.watch(liveRoomsRepositoryProvider);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return roomsAsync.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Signed in as ${profile.username}'),
                const SizedBox(height: 12),
                const Text('No public notes yet.'),
              ],
            ),
          );
        }

        return Column(
          children: [
            ListTile(
              leading: ProfileAvatar(imageUrl: profile.profileImageUrl),
              title: Text(profile.username),
              subtitle: Text(profile.email),
              trailing: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Edit profile',
                    onPressed: () => _showProfileDialog(context, ref, profile),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        LiveProfileRepository.openGoogleGroupSubscribeEmail(
                          profile,
                        ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Join FiloBus'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  final canDeleteRoom = room.createdBy == currentUserId;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LiveRoomChatScreen(
                              roomId: room.id,
                              roomTitle: room.title,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _AuthorRow(room: room),
                            const SizedBox(height: 8),
                            _RoomCounters(roomId: room.id),
                            const SizedBox(height: 8),
                            Text(
                              room.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(
                                    room.category,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                Flexible(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      if (canDeleteRoom)
                                        IconButton.filledTonal(
                                          tooltip: 'Delete public note',
                                          onPressed: () => _confirmDeleteRoom(
                                            context,
                                            ref,
                                            room,
                                          ),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  LiveRoomChatScreen(
                                                    roomId: room.id,
                                                    roomTitle: room.title,
                                                  ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          minimumSize: Size.zero,
                                        ),
                                        child: const Text('Join Topic'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stackTrace) => Center(child: Text('Error: $err')),
    );
  }

  Future<void> _confirmDeleteRoom(
    BuildContext context,
    WidgetRef ref,
    LiveRoomModel room,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete public note?'),
          content: Text('This will remove "${room.title}" from Public Notes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await ref.read(liveRoomsRepositoryProvider.notifier).deleteRoom(room.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Public note deleted.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete public note: $error')),
        );
      }
    }
  }

  void _showProfileDialog(
    BuildContext context,
    WidgetRef ref,
    LiveProfile profile,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LiveProfileForm(
              initialProfile: profile,
              onSaved: () {
                ref.invalidate(liveProfileProvider);
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  void _showCreateRoomDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Post Public Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                await ref
                    .read(liveRoomsRepositoryProvider.notifier)
                    .createRoom(
                      title: title,
                      description: descriptionController.text,
                      category: categoryController.text,
                    );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

class _AuthorRow extends ConsumerWidget {
  final LiveRoomModel room;

  const _AuthorRow({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = room.createdByProfileImageUrl == null
        ? ref.watch(liveProfileByUserIdProvider(room.createdBy)).valueOrNull
        : null;
    final profileImageUrl =
        room.createdByProfileImageUrl ?? profile?.profileImageUrl;
    final authorName = profile?.username ?? room.createdByName;

    return Row(
      children: [
        ProfileAvatar(radius: 14, imageUrl: profileImageUrl),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _RoomCounters extends ConsumerWidget {
  final String roomId;

  const _RoomCounters({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineCount =
        ref.watch(liveRoomMemberCountProvider(roomId)).valueOrNull ?? 0;
    final joinedCount =
        ref.watch(liveRoomJoinedCountProvider(roomId)).valueOrNull ?? 0;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        _CounterPill(
          icon: Icons.circle,
          iconColor: Colors.green,
          label: '$onlineCount online now',
          foregroundColor: Colors.green,
        ),
        _CounterPill(
          icon: Icons.edit_note,
          iconColor: Colors.blueGrey,
          label: '$joinedCount writers',
          foregroundColor: Colors.blueGrey,
        ),
      ],
    );
  }
}

class _CounterPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color foregroundColor;

  const _CounterPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: foregroundColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 10),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class LiveProfileForm extends StatefulWidget {
  final LiveProfile? initialProfile;
  final VoidCallback onSaved;

  const LiveProfileForm({
    required this.onSaved,
    this.initialProfile,
    super.key,
  });

  @override
  State<LiveProfileForm> createState() => _LiveProfileFormState();
}

class _LiveProfileFormState extends State<LiveProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  bool _isSaving = false;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.initialProfile?.username,
    );
    _emailController = TextEditingController(
      text: widget.initialProfile?.email,
    );
    _bioController = TextEditingController(text: widget.initialProfile?.bio);
    _locationController = TextEditingController(
      text: widget.initialProfile?.location,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Live profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _avatarBytes != null
                            ? MemoryImage(_avatarBytes!)
                            : (widget.initialProfile?.profileImageUrl != null
                                  ? NetworkImage(
                                          widget
                                              .initialProfile!
                                              .profileImageUrl!,
                                        )
                                        as ImageProvider
                                  : null),
                        child:
                            _avatarBytes == null &&
                                widget.initialProfile?.profileImageUrl == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final file = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (file != null) {
                                final bytes = await file.readAsBytes();
                                setState(() => _avatarBytes = bytes);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final username = value?.trim() ?? '';
                    if (username.isEmpty) return 'Enter a username';
                    if (username.length > 80) return 'Username is too long';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Enter an email';
                    if (!email.contains('@') || !email.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if ((value ?? '').length > 200) return 'Bio is too long';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await LiveProfileRepository.save(
        username: _usernameController.text,
        email: _emailController.text,
        bio: _bioController.text,
        location: _locationController.text,
        avatarBytes: _avatarBytes,
        existingProfileImageUrl: widget.initialProfile?.profileImageUrl,
      );

      widget.onSaved();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save profile: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
