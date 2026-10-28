import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/locale_provider.dart';
import '../../data/repositories/artwork_preferences.dart';
import 'harbor_artwork.dart';
import 'harbor_collections.dart';
import 'harbor_custom_images.dart';
import 'harbor_shortcuts.dart';
import 'harbor_strings.dart';
import 'harbor_themes.dart';

class HarborSettings extends ConsumerStatefulWidget {
  const HarborSettings({super.key});
  @override
  ConsumerState<HarborSettings> createState() => _HarborSettingsState();
}

class _HarborSettingsState extends ConsumerState<HarborSettings> {
  int section = 0;
  String pictureGroup = 'All pictures';
  final shortcutSearch = TextEditingController();
  String t(String value) => harborText(context, value);
  static const categories = [
    ('Appearance', 'Colors and visual style', Icons.palette_outlined),
    ('Pictures', 'Covers and interface artwork', Icons.photo_library_outlined),
    ('Keyboard shortcuts', 'Global playback controls', Icons.keyboard_outlined),
    ('Language', 'Display language', Icons.translate_rounded),
  ];
  @override
  void dispose() {
    shortcutSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(harborThemeProvider);
    final rail = MediaQuery.sizeOf(context).width >= 1000;
    return Padding(
      key: const ValueKey('desktop-settings'),
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(t('Settings'),
              style:
                  const TextStyle(fontSize: 29, fontWeight: FontWeight.w700)),
          const Spacer(),
          Icon(Icons.check_circle_outline,
              size: 15, color: theme.accent.withAlpha(170)),
          const SizedBox(width: 7),
          Text(t('Auto-save'),
              style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ]),
        const SizedBox(height: 22),
        Expanded(child: LayoutBuilder(builder: (_, bounds) {
          final showRail = rail && bounds.maxWidth >= 680;
          final content = SingleChildScrollView(
            key: ValueKey('settings-content-$section'),
            padding: const EdgeInsets.only(bottom: 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t(categories[section].$1),
                  style: const TextStyle(
                      fontSize: 23, fontWeight: FontWeight.w600)),
              const SizedBox(height: 7),
              Text(
                  t(section == 3
                      ? 'Changes apply immediately.'
                      : categories[section].$2),
                  style: const TextStyle(fontSize: 12, color: Colors.white54)),
              const SizedBox(height: 24),
              switch (section) {
                0 => _appearance(theme),
                1 => _pictures(theme),
                2 => _shortcuts(theme),
                _ => _language(theme),
              },
            ]),
          );
          return showRail
              ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SizedBox(width: 204, child: _navigation(theme)),
                  const SizedBox(width: 26),
                  Expanded(child: content),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        for (var i = 0; i < categories.length; i++)
                          _category(theme, i, compact: true)
                      ])),
                  const SizedBox(height: 24),
                  Expanded(child: content),
                ]);
        })),
      ]),
    );
  }

  Widget _navigation(HarborTheme theme) => Container(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 14),
      decoration: BoxDecoration(
          color: theme.surface.withAlpha(150),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
            child: Text(t('Preferences'),
                style: const TextStyle(
                    color: Colors.white38, fontSize: 10, letterSpacing: 1.2))),
        for (var i = 0; i < categories.length; i++) _category(theme, i),
        const Spacer(),
        const Divider(),
        const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Text('ToneHarbor Desktop',
                style: TextStyle(color: Colors.white38, fontSize: 11))),
      ]));

  Widget _category(HarborTheme theme, int index, {bool compact = false}) {
    final selected = section == index, item = categories[index];
    return Padding(
        padding:
            EdgeInsets.only(bottom: compact ? 0 : 6, right: compact ? 8 : 0),
        child: Material(
            color: selected ? theme.accent.withAlpha(17) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            child: InkWell(
              key: ValueKey('settings-category-$index'),
              borderRadius: BorderRadius.circular(7),
              onTap: () => setState(() => section = index),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                      mainAxisSize:
                          compact ? MainAxisSize.min : MainAxisSize.max,
                      children: [
                        Icon(item.$3,
                            size: 18,
                            color: selected ? theme.accent : Colors.white54),
                        const SizedBox(width: 10),
                        if (compact)
                          Text(t(item.$1),
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      selected ? theme.accent : Colors.white70))
                        else
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(t(item.$1),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: selected
                                            ? theme.accent
                                            : Colors.white70,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w400)),
                                const SizedBox(height: 5),
                                Text(t(item.$2),
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.white38)),
                              ])),
                      ])),
            )));
  }

  Widget _panel(HarborTheme theme,
          {required String title, String? subtitle, required Widget child}) =>
      Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: theme.surface.withAlpha(140),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t(title),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(t(subtitle),
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11, height: 1.5))
            ],
            const SizedBox(height: 20),
            child,
          ]));

  Widget _appearance(HarborTheme theme) => LayoutBuilder(builder: (_, bounds) {
        final previewBeside = bounds.maxWidth >= 820;
        final palette = _panel(theme,
            title: 'Themes',
            subtitle: 'Ocean is the default. Your choice is remembered.',
            child: LayoutBuilder(builder: (_, area) {
          final columns = area.maxWidth >= 560 ? 3 : 2;
          final width = (area.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(spacing: 12, runSpacing: 14, children: [
            for (final option in [
              HarborTheme.ocean,
              HarborTheme.forest,
              HarborTheme.violet,
              HarborTheme.amber,
              HarborTheme.crimson
            ])
              SizedBox(
                  width: width,
                  child: Material(
                      color: option.background,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                          side: BorderSide(
                              color: theme == option
                                  ? option.accent
                                  : option.border,
                              width: theme == option ? 1.5 : 1)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: ValueKey('settings-theme-${option.name}'),
                        onTap: () => ref
                            .read(harborThemeProvider.notifier)
                            .setTheme(option),
                        child: Column(children: [
                          SizedBox(
                              height: 88,
                              width: double.infinity,
                              child: CustomPaint(
                                  painter: _PaletteMiniature(option))),
                          Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 10, 10, 12),
                              child: Row(children: [
                                Expanded(
                                    child: Text(t(option.label),
                                        style: TextStyle(
                                            color: option.accent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600))),
                                if (theme == option)
                                  Icon(Icons.check_circle,
                                      size: 16, color: option.accent),
                              ])),
                        ]),
                      ))),
          ]);
        }));
        final preview = _preview(theme);
        return previewBeside
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: palette),
                const SizedBox(width: 20),
                SizedBox(width: 276, child: preview),
              ])
            : Column(children: [palette, const SizedBox(height: 18), preview]);
      });

  Widget _preview(HarborTheme theme) => _panel(theme,
          title: 'Live preview',
          subtitle: 'Default artwork follows your theme.',
          child: LayoutBuilder(builder: (_, area) {
        final side = area.maxWidth.clamp(150.0, 236.0);
        return Center(
            child: SizedBox(
                width: side,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HarborArtwork(size: side, playback: true),
                      const SizedBox(height: 15),
                      Text(t('Your music, your space.'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 5),
                      const Text('ToneHarbor Sessions',
                          style:
                              TextStyle(fontSize: 11, color: Colors.white54)),
                      const SizedBox(height: 18),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                              value: .42,
                              minHeight: 3,
                              color: theme.accent,
                              backgroundColor: theme.border)),
                      const SizedBox(height: 16),
                      ExcludeSemantics(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            const Icon(Icons.skip_previous_rounded,
                                size: 21, color: Colors.white60),
                            const SizedBox(width: 22),
                            Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: theme.accent.withAlpha(180))),
                                child:
                                    const Icon(Icons.pause_rounded, size: 23)),
                            const SizedBox(width: 22),
                            const Icon(Icons.skip_next_rounded,
                                size: 21, color: Colors.white60),
                          ])),
                    ])));
      }));

  Widget _pictures(HarborTheme theme) {
    final custom = ref.watch(artworkPreferencesProvider);
    final chosen = PlaybackCover.fromPreferences(custom);
    final entries = [
      ('default:player', 'Default player picture', 'player'),
      ('default:track', 'Default track cover', 'track'),
      ('default:playlist', 'Default playlist cover', 'playlist'),
      ('home:header', 'Home header', 'header'),
      ('collection:green-studio-v2', 'Recently added', 'green-studio-v2'),
      ('collection:mountain-listens', 'Long listens', 'mountain-listens'),
      ('collection:city-favorites', 'Favorites', 'city-favorites'),
      ('collection:leaves-playlists', 'Playlists', 'leaves-playlists'),
    ]
        .where((entry) =>
            pictureGroup == 'All pictures' ||
            (pictureGroup == 'Player and library'
                ? entry.$1.startsWith('default:')
                : !entry.$1.startsWith('default:')))
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _panel(theme,
          title: 'Playback picture',
          subtitle: 'Used when a track has no cover of its own.',
          child: LayoutBuilder(
              builder: (_, area) =>
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    for (final cover in PlaybackCover.values)
                      SizedBox(
                          width: area.maxWidth >= 540
                              ? (area.maxWidth - 12) / 2
                              : area.maxWidth,
                          child: Material(
                              color: theme.background,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  side: BorderSide(
                                      color: !custom.containsKey(
                                                  'default:player') &&
                                              chosen == cover
                                          ? theme.accent
                                          : theme.border)),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                key: ValueKey('playback-cover-${cover.name}'),
                                onTap: () => ref
                                    .read(artworkPreferencesProvider.notifier)
                                    .selectPlaybackCover(cover),
                                child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(children: [
                                      ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: HarborCoverImage(
                                              size: 76, cover: cover)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                          child: Text(t(cover.label),
                                              style: const TextStyle(
                                                  fontSize: 12))),
                                      const SizedBox(width: 8),
                                      Icon(
                                          !custom.containsKey(
                                                      'default:player') &&
                                                  chosen == cover
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          size: 19,
                                          color: chosen == cover
                                              ? theme.accent
                                              : Colors.white38),
                                    ])),
                              ))),
                  ]))),
      const SizedBox(height: 12),
      Text(t('Library tracks without artwork use the theme waveform.'),
          style: const TextStyle(fontSize: 11, color: Colors.white54)),
      const SizedBox(height: 26),
      Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(t('Interface pictures'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  key: const ValueKey('settings-picture-filter'),
                  initialValue: pictureGroup,
                  isDense: true,
                  decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  items: [
                    for (final group in [
                      'All pictures',
                      'Player and library',
                      'Home artwork'
                    ])
                      DropdownMenuItem(
                          value: group,
                          child: Text(t(group),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)))
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => pictureGroup = value);
                  },
                )),
          ]),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (_, area) {
        final columns = area.maxWidth >= 900
            ? 3
            : area.maxWidth >= 480
                ? 2
                : 1;
        final width = (area.maxWidth - (columns - 1) * 14) / columns;
        return Wrap(spacing: 14, runSpacing: 14, children: [
          for (final (key, label, kind) in entries)
            SizedBox(
                width: width,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.border)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: 108,
                            width: double.infinity,
                            child: ClipRect(
                                child: kind == 'track' ||
                                        kind == 'playlist' ||
                                        kind == 'player'
                                    ? FittedBox(
                                        fit: BoxFit.cover,
                                        child: HarborArtwork(
                                            size: 240,
                                            playlist: kind == 'playlist',
                                            playback: kind == 'player'))
                                    : HarborCustomImage(
                                        imageKey: key,
                                        cacheWidth: 480,
                                        fallback: Image.asset(
                                            kind == 'header'
                                                ? harborHomeBackdropAsset
                                                : harborCollectionAsset(
                                                    theme, kind),
                                            fit: BoxFit.cover,
                                            cacheWidth: 480)))),
                        Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                            child: Row(children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(t(label),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(
                                        t(custom.containsKey(key)
                                            ? 'Custom picture'
                                            : 'Theme default'),
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white38)),
                                  ])),
                              IconButton(
                                  key: ValueKey('change-$key'),
                                  tooltip: t('Change picture'),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      chooseHarborPicture(context, ref, key),
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 17)),
                              IconButton(
                                  key: ValueKey('reset-$key'),
                                  tooltip: t('Restore default picture'),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: custom.containsKey(key)
                                      ? () => ref
                                          .read(artworkPreferencesProvider
                                              .notifier)
                                          .reset(key)
                                      : null,
                                  icon: const Icon(Icons.restore_rounded,
                                      size: 17)),
                            ])),
                      ]),
                )),
        ]);
      }),
    ]);
  }

  Widget _shortcuts(HarborTheme theme) => _panel(theme,
      title: 'Edit shortcuts',
      subtitle: 'Customize playback shortcuts, including global shortcuts.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 310,
            child: TextField(
              key: const ValueKey('settings-shortcut-search'),
              controller: shortcutSearch,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  hintText: t('Search shortcuts'),
                  hintStyle: const TextStyle(fontSize: 12),
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: shortcutSearch.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          tooltip: t('Clear search'),
                          onPressed: () =>
                              setState(() => shortcutSearch.clear()))),
            )),
        const SizedBox(height: 20),
        ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: HarborShortcutEditor(query: shortcutSearch.text)),
      ]));

  Widget _language(HarborTheme theme) {
    final language = ref.watch(localeProvider).languageCode;
    final control = SizedBox(
        width: 236,
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          key: ValueKey('settings-language-$language'),
          initialValue: language,
          decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              filled: true,
              fillColor: theme.input,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide(color: theme.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide(color: theme.border))),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          items: const [
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'ar', child: Text('العربية')),
            DropdownMenuItem(value: 'fa', child: Text('فارسی')),
          ],
          onChanged: (code) {
            if (code != null) {
              ref.read(localeProvider.notifier).setLocale(Locale(code));
            }
          },
        ));
    return Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: theme.surface.withAlpha(140),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.border)),
              child: LayoutBuilder(builder: (_, area) {
                final label = Text(t('Interface language'),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500));
                return area.maxWidth >= 450
                    ? Row(children: [
                        Expanded(child: label),
                        const SizedBox(width: 24),
                        control
                      ])
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [label, const SizedBox(height: 12), control]);
              }),
            )));
  }
}

/// A small actual-layout color sample, painted once per theme choice.
class _PaletteMiniature extends CustomPainter {
  final HarborTheme theme;
  const _PaletteMiniature(this.theme);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final fill = Paint();
    void box(double x, double y, double width, double height, Color color,
        [double radius = 2]) {
      fill.color = color;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, width, height), Radius.circular(radius)),
          fill);
    }

    box(0, 0, w, h, theme.background, 0);
    box(0, 0, w * .18, h, theme.surface, 0);
    for (var i = 0; i < 4; i++) {
      box(w * .04, h * (.25 + i * .15), w * .10, 3,
          i == 1 ? theme.accent : theme.border);
    }
    box(w * .23, h * .13, w * .42, 5, theme.input);
    box(w * .23, h * .30, w * .30, h * .48, theme.accent.withAlpha(35), 4);
    for (var i = 0; i < 5; i++) {
      box(w * (.29 + i * .04), h * (.47 - (i % 3) * .035), 2,
          h * (.15 + (i % 3) * .07), theme.accent.withAlpha(170), 1);
    }
    for (var i = 0; i < 3; i++) {
      box(w * .59, h * (.33 + i * .14), w * .31, 3, theme.border);
      box(w * .59, h * (.38 + i * .14), w * .20, 2,
          theme.border.withAlpha(130));
    }
    box(w * .23, h * .87, w * .67, 2, theme.border);
    box(w * .23, h * .87, w * .31, 2, theme.accent);
  }

  @override
  bool shouldRepaint(covariant _PaletteMiniature old) => old.theme != theme;
}
