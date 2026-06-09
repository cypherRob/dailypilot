// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_room_chat_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$liveRoomMemberCountHash() =>
    r'075dabfc07bbc755a3ef6792f062042d430c1e13';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [liveRoomMemberCount].
@ProviderFor(liveRoomMemberCount)
const liveRoomMemberCountProvider = LiveRoomMemberCountFamily();

/// See also [liveRoomMemberCount].
class LiveRoomMemberCountFamily extends Family<AsyncValue<int>> {
  /// See also [liveRoomMemberCount].
  const LiveRoomMemberCountFamily();

  /// See also [liveRoomMemberCount].
  LiveRoomMemberCountProvider call(
    String roomId,
  ) {
    return LiveRoomMemberCountProvider(
      roomId,
    );
  }

  @override
  LiveRoomMemberCountProvider getProviderOverride(
    covariant LiveRoomMemberCountProvider provider,
  ) {
    return call(
      provider.roomId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'liveRoomMemberCountProvider';
}

/// See also [liveRoomMemberCount].
class LiveRoomMemberCountProvider extends AutoDisposeStreamProvider<int> {
  /// See also [liveRoomMemberCount].
  LiveRoomMemberCountProvider(
    String roomId,
  ) : this._internal(
          (ref) => liveRoomMemberCount(
            ref as LiveRoomMemberCountRef,
            roomId,
          ),
          from: liveRoomMemberCountProvider,
          name: r'liveRoomMemberCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$liveRoomMemberCountHash,
          dependencies: LiveRoomMemberCountFamily._dependencies,
          allTransitiveDependencies:
              LiveRoomMemberCountFamily._allTransitiveDependencies,
          roomId: roomId,
        );

  LiveRoomMemberCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.roomId,
  }) : super.internal();

  final String roomId;

  @override
  Override overrideWith(
    Stream<int> Function(LiveRoomMemberCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LiveRoomMemberCountProvider._internal(
        (ref) => create(ref as LiveRoomMemberCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        roomId: roomId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<int> createElement() {
    return _LiveRoomMemberCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveRoomMemberCountProvider && other.roomId == roomId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, roomId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LiveRoomMemberCountRef on AutoDisposeStreamProviderRef<int> {
  /// The parameter `roomId` of this provider.
  String get roomId;
}

class _LiveRoomMemberCountProviderElement
    extends AutoDisposeStreamProviderElement<int> with LiveRoomMemberCountRef {
  _LiveRoomMemberCountProviderElement(super.provider);

  @override
  String get roomId => (origin as LiveRoomMemberCountProvider).roomId;
}

String _$liveRoomChatRepositoryHash() =>
    r'fdac60e6d2f6aa129ce0c121e69ba855f89405c4';

abstract class _$LiveRoomChatRepository
    extends BuildlessAutoDisposeStreamNotifier<List<LiveRoomMessageModel>> {
  late final String roomId;

  Stream<List<LiveRoomMessageModel>> build(
    String roomId,
  );
}

/// See also [LiveRoomChatRepository].
@ProviderFor(LiveRoomChatRepository)
const liveRoomChatRepositoryProvider = LiveRoomChatRepositoryFamily();

/// See also [LiveRoomChatRepository].
class LiveRoomChatRepositoryFamily
    extends Family<AsyncValue<List<LiveRoomMessageModel>>> {
  /// See also [LiveRoomChatRepository].
  const LiveRoomChatRepositoryFamily();

  /// See also [LiveRoomChatRepository].
  LiveRoomChatRepositoryProvider call(
    String roomId,
  ) {
    return LiveRoomChatRepositoryProvider(
      roomId,
    );
  }

  @override
  LiveRoomChatRepositoryProvider getProviderOverride(
    covariant LiveRoomChatRepositoryProvider provider,
  ) {
    return call(
      provider.roomId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'liveRoomChatRepositoryProvider';
}

/// See also [LiveRoomChatRepository].
class LiveRoomChatRepositoryProvider
    extends AutoDisposeStreamNotifierProviderImpl<LiveRoomChatRepository,
        List<LiveRoomMessageModel>> {
  /// See also [LiveRoomChatRepository].
  LiveRoomChatRepositoryProvider(
    String roomId,
  ) : this._internal(
          () => LiveRoomChatRepository()..roomId = roomId,
          from: liveRoomChatRepositoryProvider,
          name: r'liveRoomChatRepositoryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$liveRoomChatRepositoryHash,
          dependencies: LiveRoomChatRepositoryFamily._dependencies,
          allTransitiveDependencies:
              LiveRoomChatRepositoryFamily._allTransitiveDependencies,
          roomId: roomId,
        );

  LiveRoomChatRepositoryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.roomId,
  }) : super.internal();

  final String roomId;

  @override
  Stream<List<LiveRoomMessageModel>> runNotifierBuild(
    covariant LiveRoomChatRepository notifier,
  ) {
    return notifier.build(
      roomId,
    );
  }

  @override
  Override overrideWith(LiveRoomChatRepository Function() create) {
    return ProviderOverride(
      origin: this,
      override: LiveRoomChatRepositoryProvider._internal(
        () => create()..roomId = roomId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        roomId: roomId,
      ),
    );
  }

  @override
  AutoDisposeStreamNotifierProviderElement<LiveRoomChatRepository,
      List<LiveRoomMessageModel>> createElement() {
    return _LiveRoomChatRepositoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveRoomChatRepositoryProvider && other.roomId == roomId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, roomId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin LiveRoomChatRepositoryRef
    on AutoDisposeStreamNotifierProviderRef<List<LiveRoomMessageModel>> {
  /// The parameter `roomId` of this provider.
  String get roomId;
}

class _LiveRoomChatRepositoryProviderElement
    extends AutoDisposeStreamNotifierProviderElement<LiveRoomChatRepository,
        List<LiveRoomMessageModel>> with LiveRoomChatRepositoryRef {
  _LiveRoomChatRepositoryProviderElement(super.provider);

  @override
  String get roomId => (origin as LiveRoomChatRepositoryProvider).roomId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
