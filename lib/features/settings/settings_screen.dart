import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_background.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/app_info.dart';
import '../../core/utils/platform_utils.dart';
import '../../services/audio/audio_player_service.dart';
import '../../core/localization/locale_provider.dart';
import '../../services/cache_cleanup_service.dart';
import '../../core/utils/app_toast.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ref.watch(currentThemeDataProvider);
    final currentThemeId = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final audioHandler = ref.read(audioHandlerProvider);
    return Scaffold(
      body: AppBackground(
        theme: theme,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: theme.onSurface,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        l10n.settings,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Theme Section ─────────────────────────────────────────────
              if (!isDesktop) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(label: l10n.theme, theme: theme),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: kAppThemes.entries.map((entry) {
                        final t = entry.value;
                        final isSelected = currentThemeId == t.id;
                        return GestureDetector(
                          onTap: () =>
                              themeNotifier.setTheme(t.id, audioHandler),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: (MediaQuery.of(context).size.width - 64) / 2,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: t.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? t.primary
                                    : t.primary.withAlpha(40),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: t.primary.withAlpha(50),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Color swatches
                                    _Swatch(color: t.primary),
                                    const SizedBox(width: 4),
                                    _Swatch(color: t.secondary),
                                    const SizedBox(width: 4),
                                    _Swatch(color: t.accent),
                                    const Spacer(),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: t.primary,
                                        size: 18,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _themeName(context, t.nameKey),
                                  style: TextStyle(
                                    color: t.onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.isDark
                                      ? '🌙 ${l10n.dark}'
                                      : '☀️ ${l10n.light}',
                                  style: TextStyle(
                                    color: t.onSurface.withAlpha(140),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],

              // ── Language Section ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionHeader(label: l10n.language, theme: theme),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.primary.withAlpha(40)),
                    ),
                    child: Consumer(
                      builder: (context, ref, _) {
                        final currentLocale = ref.watch(localeProvider);
                        final notifier = ref.read(localeProvider.notifier);

                        return Column(
                          children: [
                            _LanguageTile(
                              label: 'English',
                              isSelected: currentLocale.languageCode == 'en',
                              onTap: () =>
                                  notifier.setLocale(const Locale('en')),
                              theme: theme,
                            ),
                            const Divider(height: 1),
                            _LanguageTile(
                              label: 'العربية',
                              isSelected: currentLocale.languageCode == 'ar',
                              onTap: () =>
                                  notifier.setLocale(const Locale('ar')),
                              theme: theme,
                            ),
                            const Divider(height: 1),
                            _LanguageTile(
                              label: 'فارسی',
                              isSelected: currentLocale.languageCode == 'fa',
                              onTap: () =>
                                  notifier.setLocale(const Locale('fa')),
                              theme: theme,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Storage & Cache Section ───────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionHeader(
                  label: l10n.storageAndCache,
                  theme: theme,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _CacheSection(theme: theme),
                ),
              ),

              // ── About Section ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionHeader(label: l10n.about, theme: theme),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.primary.withAlpha(40)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: theme.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: theme.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ToneHarbor',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.appSlogan,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.version} $kAppVersion',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: theme.onSurface.withAlpha(100)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  String _themeName(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'darkOcean':
        return l10n.darkOcean;
      case 'desertSand':
        return l10n.desertSand;
      case 'aurora':
        return l10n.aurora;
      case 'midnight':
        return l10n.midnight;
      case 'lightBreeze':
        return l10n.lightBreeze;
      case 'goldBlack':
        return l10n.themeGoldBlack;
      case 'greenGrey':
        return l10n.themeGreenGrey;
      case 'warmBrown':
        return l10n.themeWarmBrown;
      case 'quran':
        return l10n.themeQuran;
      case 'ashura':
        return l10n.themeAshura;
      case 'muharram':
        return l10n.themeMuharram;
      case 'hussaini':
        return l10n.themeHussaini;
      case 'ramadan':
        return l10n.themeRamadan;
      case 'blueSky':
        return l10n.themeBlueSky;
      case 'royalRed':
        return l10n.themeMuharram;
      case 'emeraldGold':
        return l10n.themeEmeraldGold;
      case 'lavender':
        return l10n.themeLavender;
      case 'crescentTeal':
        return l10n.themeCrescentTeal;
      case 'royalCrimson':
        return l10n.themeRoyalCrimson;
      default:
        return key;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final dynamic theme;
  const _SectionHeader({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: theme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  const _Swatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final dynamic theme;

  const _LanguageTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: theme.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}

class _CacheSection extends StatefulWidget {
  final dynamic theme;
  const _CacheSection({required this.theme});

  @override
  State<_CacheSection> createState() => _CacheSectionState();
}

class _CacheSectionState extends State<_CacheSection> {
  int _cacheBytes = 0;
  bool _isLoading = true;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final bytes = await CacheCleanupService.getCacheSizeBytes();
    if (mounted) {
      setState(() {
        _cacheBytes = bytes;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    if (_isClearing) return;
    setState(() => _isClearing = true);
    await CacheCleanupService.clearAllCache();
    final newBytes = await CacheCleanupService.getCacheSizeBytes();
    if (mounted) {
      setState(() {
        _cacheBytes = newBytes;
        _isClearing = false;
      });
      AppToast.success(
        context,
        AppLocalizations.of(context)!.clearCacheSuccess,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final l10n = AppLocalizations.of(context)!;
    final isClean = _cacheBytes <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.cleaning_services_rounded,
                  color: theme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.cacheSize,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (_isLoading)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.primary,
                        ),
                      )
                    else
                      Text(
                        isClean
                            ? l10n.cacheClean
                            : CacheCleanupService.formatBytes(_cacheBytes),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isClean ? Colors.green : theme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              if (_isClearing)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.primary,
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: isClean ? null : _clearCache,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: Text(
                    l10n.clearCache,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: theme.primary.withAlpha(30),
                    disabledForegroundColor: theme.onSurface.withAlpha(80),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.clearCacheDesc,
            style: TextStyle(
              fontSize: 11,
              color: theme.onSurface.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }
}
