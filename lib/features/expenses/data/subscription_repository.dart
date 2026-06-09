import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dailypilot/core/sync/local_db.dart';
import 'package:dailypilot/shared/models/subscription_model.dart';
import 'package:dailypilot/shared/models/sync_status.dart';

part 'subscription_repository.g.dart';

@riverpod
class SubscriptionRepository extends _$SubscriptionRepository {
  @override
  Stream<List<SubscriptionModel>> build() {
    final isar = ref.watch(localDbProvider);
    return isar.subscriptionModels.where().watch(fireImmediately: true);
  }

  Future<void> addSubscription(SubscriptionModel subscription) async {
    final isar = ref.read(localDbProvider);
    subscription.createdAt = DateTime.now();
    subscription.updatedAt = DateTime.now();
    subscription.syncStatus = SyncStatus.pendingCreate;

    await isar.writeTxn(() async {
      await isar.subscriptionModels.put(subscription);
    });
  }
}
