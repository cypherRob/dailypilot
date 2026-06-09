import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/features/expenses/data/subscription_repository.dart';
import 'package:intl/intl.dart';

class SubscriptionManagerSection extends ConsumerWidget {
  const SubscriptionManagerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscriptions & Bills',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        subscriptionsAsync.when(
          data: (subscriptions) {
            if (subscriptions.isEmpty) {
              return const Center(child: Text('No active subscriptions.'));
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subscriptions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final sub = subscriptions[index];

                final now = DateTime.now();
                final daysUntil = sub.renewalDate.difference(now).inDays;

                Color statusColor = Colors.green;
                String statusText = 'in $daysUntil days';
                if (daysUntil < 0) {
                  statusColor = Colors.red;
                  statusText = 'Overdue by ${daysUntil.abs()} days';
                } else if (daysUntil <= 3) {
                  statusColor = Colors.orange;
                  statusText = 'Due in $daysUntil days';
                } else if (daysUntil == 0) {
                  statusColor = Colors.redAccent;
                  statusText = 'Due Today';
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.receipt_long,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Renews ${DateFormat.yMMMd().format(sub.renewalDate)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${sub.cost.toStringAsFixed(2)}/mo',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              const Center(child: Text('Error loading subscriptions')),
        ),
      ],
    );
  }
}
