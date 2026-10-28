import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/app_icons.dart';
import '../../services/audio/sleep_timer_service.dart';
import '../../l10n/app_localizations.dart';

class SleepTimerBottomSheet extends ConsumerStatefulWidget {
  const SleepTimerBottomSheet({super.key});

  @override
  ConsumerState<SleepTimerBottomSheet> createState() =>
      _SleepTimerBottomSheetState();
}

class _SleepTimerBottomSheetState extends ConsumerState<SleepTimerBottomSheet> {
  SleepTimerMode _selectedMode = SleepTimerMode.timeEndLock;
  int _minutes = 15;
  bool _closeApp = false;

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeDataProvider);
    final timerState = ref.watch(sleepTimerProvider);
    final timer = ref.read(sleepTimerProvider.notifier);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.primary.withAlpha(40), width: 1),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.onSurface.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Icon(Icons.bedtime_rounded, color: theme.primary, size: 24),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context)!.sleepTimer,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (timerState.isActive)
                  GestureDetector(
                    onTap: () {
                      timer.cancel();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withAlpha(80)),
                      ),
                      child: Text(AppLocalizations.of(context)!.cancelTimerBtn,
                          style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Mode Selection
            ...[
              _ModeOption(
                mode: SleepTimerMode.timeEndLock,
                title: AppLocalizations.of(context)!.stopAtTimerEnd,
                subtitle: AppLocalizations.of(context)!.stopAtTimerEndSub,
                icon: Icons.timer_rounded,
                selected: _selectedMode,
                theme: theme,
                onTap: (m) => setState(() => _selectedMode = m),
              ),
              _ModeOption(
                mode: SleepTimerMode.trackEndLock,
                title: AppLocalizations.of(context)!.stopAtTrackEnd,
                subtitle: AppLocalizations.of(context)!.stopAtTrackEndSub,
                icon: Icons.music_off_rounded,
                selected: _selectedMode,
                theme: theme,
                onTap: (m) => setState(() => _selectedMode = m),
              ),
              _ModeOption(
                mode: SleepTimerMode.playlistEndLock,
                title: AppLocalizations.of(context)!.stopAtPlaylistEnd,
                subtitle: AppLocalizations.of(context)!.stopAtPlaylistEndSub,
                icon: AppIcons.queueMusic,
                selected: _selectedMode,
                theme: theme,
                onTap: (m) => setState(() => _selectedMode = m),
              ),
            ],

            // Close App Toggle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: theme.background.withAlpha(100),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.onSurface.withAlpha(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.exit_to_app_rounded,
                      color: theme.onSurface.withAlpha(150), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        AppLocalizations.of(context)!.closeAppWhenStopped,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  Switch(
                    value: _closeApp,
                    activeThumbColor: theme.primary,
                    onChanged: (v) => setState(() => _closeApp = v),
                  ),
                ],
              ),
            ),

            // Duration Selection
            if (_selectedMode == SleepTimerMode.timeEndLock) ...[
              const SizedBox(height: 16),
              // Quick Presets
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [15, 30, 45, 60, 90].map((m) {
                    final isSel = _minutes == m;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${m}m',
                            style: TextStyle(
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        selected: isSel,
                        selectedColor: theme.primary.withAlpha(40),
                        backgroundColor: theme.background,
                        side: BorderSide(
                            color: isSel
                                ? theme.primary
                                : theme.onSurface.withAlpha(30)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (sel) {
                          if (sel) setState(() => _minutes = m);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.primary.withAlpha(30)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$_minutes',
                              style: TextStyle(
                                  color: theme.primary,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  height: 1)),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.minutes,
                              style: TextStyle(
                                color: theme.primary.withAlpha(180),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                height: 1,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context)!.slidePicker,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 10),
                  activeTrackColor: theme.primary,
                  inactiveTrackColor: theme.primary.withAlpha(30),
                  thumbColor: theme.primary,
                  overlayColor: theme.primary.withAlpha(30),
                ),
                child: Slider(
                  min: 1,
                  max: 120,
                  value: _minutes.toDouble().clamp(1.0, 120.0),
                  onChanged: (v) => setState(() => _minutes = v.round()),
                ),
              ),
            ],

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.alarm_rounded, size: 18),
                label: Text(_selectedMode == SleepTimerMode.timeEndLock
                    ? AppLocalizations.of(context)!.setTimerWithMin(_minutes)
                    : AppLocalizations.of(context)!.startSleepTimer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () async {
                  await timer.startTimer(
                    mode: _selectedMode,
                    minutes: _minutes,
                    closeApp: _closeApp,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final SleepTimerMode mode;
  final String title;
  final String subtitle;
  final IconData icon;
  final SleepTimerMode selected;
  final dynamic theme;
  final void Function(SleepTimerMode) onTap;

  const _ModeOption({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == selected;
    return GestureDetector(
      onTap: () => onTap(mode),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primary.withAlpha(20)
              : theme.background.withAlpha(100),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? theme.primary : theme.onSurface.withAlpha(30),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color:
                    isSelected ? theme.primary : theme.onSurface.withAlpha(120),
                size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected ? theme.primary : theme.onSurface,
                          )),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: theme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
