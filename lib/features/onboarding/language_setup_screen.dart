import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_background.dart';
import '../../core/theme/theme_provider.dart';
import '../../l10n/app_localizations.dart';

class LanguageSetupScreen extends ConsumerWidget {
  const LanguageSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeDataProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: AppBackground(
        theme: theme,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Animated Icon/Logo
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: child,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.primary.withAlpha(20),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.primary.withAlpha(50), width: 2),
                  ),
                  child: Icon(Icons.language_rounded,
                      color: theme.primary, size: 64),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                l10n.chooseLanguage,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.onSurface,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.selectLanguagePrompt,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme.onSurface.withAlpha(150),
                    ),
              ),

              const Spacer(),

              // Language List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    _LanguageButton(
                      label: 'English',
                      subLabel: l10n.english,
                      onTap: () => _selectLanguage(context, ref, 'en'),
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _LanguageButton(
                      label: 'العربية',
                      subLabel: l10n.arabic,
                      onTap: () => _selectLanguage(context, ref, 'ar'),
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _LanguageButton(
                      label: 'فارسی',
                      subLabel: l10n.persian,
                      onTap: () => _selectLanguage(context, ref, 'fa'),
                      theme: theme,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _selectLanguage(BuildContext context, WidgetRef ref, String code) async {
    await ref.read(localeProvider.notifier).setLocale(Locale(code));
    if (context.mounted) {
      context.go('/');
    }
  }
}

class _LanguageButton extends StatelessWidget {
  final String label;
  final String subLabel;
  final VoidCallback onTap;
  final dynamic theme;

  const _LanguageButton({
    required this.label,
    required this.subLabel,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.primary.withAlpha(60), width: 1.5),
            color: theme.surface.withAlpha(100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    subLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(100),
                    ),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: theme.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
