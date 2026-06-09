import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailypilot/core/theme/app_theme.dart';
import 'package:dailypilot/features/live_rooms/data/live_profile_repository.dart';
import 'package:dailypilot/features/live_rooms/presentation/live_rooms_screen.dart';
import 'package:dailypilot/core/services/time_tracker_service.dart';
import 'package:dailypilot/shared/widgets/profile_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(liveProfileProvider);
    final timeSpentSeconds = ref.watch(timeTrackerProvider);
    final themeSettings = ref.watch(appThemeSettingsProvider);

    final hours = timeSpentSeconds ~/ 3600;
    final minutes = (timeSpentSeconds % 3600) ~/ 60;
    final seconds = timeSpentSeconds % 60;
    final timeString =
        '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No live profile found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showProfileDialog(context, ref, null),
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProfileAvatar(
                  imageUrl: profile.profileImageUrl,
                  radius: 50,
                  fallbackIcon: Icons.person,
                ),
                const SizedBox(height: 24),
                Text(
                  profile.username,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.email,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 32),
                const Divider(),
                _buildInfoTile(
                  context,
                  icon: Icons.timer_outlined,
                  title: 'Time Spent on App',
                  subtitle: timeString,
                ),
                _buildInfoTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'Bio',
                  subtitle: profile.bio.isNotEmpty
                      ? profile.bio
                      : 'No bio provided.',
                ),
                _buildInfoTile(
                  context,
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  subtitle: profile.location.isNotEmpty
                      ? profile.location
                      : 'Not specified.',
                ),
                const Divider(),
                _buildThemePanel(context, ref, themeSettings),
                const Divider(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showProfileDialog(context, ref, profile),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildThemePanel(
    BuildContext context,
    WidgetRef ref,
    AppThemeSettings settings,
  ) {
    final notifier = ref.read(appThemeSettingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.palette_outlined, color: colorScheme.primary),
          ),
          title: const Text(
            'Global app theme',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            settings.customThemeEnabled
                ? '${settings.displayPreset.label} tuning is active.'
                : 'Use the default system theme.',
          ),
          value: settings.customThemeEnabled,
          onChanged: (enabled) {
            notifier.update(settings.copyWith(customThemeEnabled: enabled));
          },
        ),
        if (settings.customThemeEnabled) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (selection) {
                notifier.update(settings.copyWith(themeMode: selection.first));
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Screen tuning',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppDisplayPreset.values.map((preset) {
              return ChoiceChip(
                label: Text(preset.label),
                selected: settings.displayPreset == preset,
                onSelected: (_) {
                  notifier.update(
                    settings.copyWith(
                      displayPreset: preset,
                      surfaceColor: preset.lightSurface,
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _ColorSwatchRow(
            label: 'Primary',
            selectedColor: settings.primaryColor,
            colors: const [
              Colors.indigo,
              Colors.teal,
              Colors.green,
              Colors.blue,
              Colors.deepPurple,
              Colors.pink,
            ],
            onSelected: (color) {
              notifier.update(settings.copyWith(primaryColor: color));
            },
          ),
          const SizedBox(height: 12),
          _ColorSwatchRow(
            label: 'Accent',
            selectedColor: settings.accentColor,
            colors: const [
              Colors.deepOrangeAccent,
              Colors.amber,
              Colors.cyan,
              Colors.lime,
              Colors.redAccent,
              Colors.purpleAccent,
            ],
            onSelected: (color) {
              notifier.update(settings.copyWith(accentColor: color));
            },
          ),
          const SizedBox(height: 12),
          _ColorSwatchRow(
            label: 'Light background',
            selectedColor: settings.surfaceColor,
            colors: const [
              Color(0xFFF5F7FA),
              Color(0xFFFFFFFF),
              Color(0xFFF1F8F5),
              Color(0xFFF7F4FF),
              Color(0xFFFFF7ED),
              Color(0xFFF3F7FF),
            ],
            onSelected: (color) {
              notifier.update(settings.copyWith(surfaceColor: color));
            },
          ),
        ],
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(subtitle),
      ),
    );
  }

  void _showProfileDialog(
    BuildContext context,
    WidgetRef ref,
    LiveProfile? profile,
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
}

class _ColorSwatchRow extends StatelessWidget {
  final String label;
  final Color selectedColor;
  final List<Color> colors;
  final ValueChanged<Color> onSelected;

  const _ColorSwatchRow({
    required this.label,
    required this.selectedColor,
    required this.colors,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((color) {
            final colorValue = color.toARGB32();
            final isSelected = colorValue == selectedColor.toARGB32();
            return Tooltip(
              message: '#${colorValue.toRadixString(16).padLeft(8, '0')}',
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onSelected(color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).dividerColor,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 18,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
