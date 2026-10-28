import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toneharbor/features/desktop/harbor_settings.dart';
import 'package:toneharbor/features/desktop/toneharbor_desktop.dart';
import 'package:toneharbor/features/desktop/harbor_themes.dart';
import 'package:toneharbor/core/localization/locale_provider.dart';
import 'package:toneharbor/l10n/app_localizations.dart';

Future<void> mountSettings(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
      child: Consumer(
          builder: (_, ref, __) => MaterialApp(
              locale: ref.watch(localeProvider),
              theme: buildHarborTheme(ref.watch(harborThemeProvider)),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: HarborSettings())))));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('artwork filters separate player defaults from home artwork',
      (tester) async {
    await mountSettings(tester);
    await tester.tap(find.byKey(const ValueKey('settings-category-1')));
    await tester.pumpAndSettle();
    final filter = find.byKey(const ValueKey('settings-picture-filter'));
    await tester.ensureVisible(filter);
    await tester.tap(filter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Player and library').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('change-default:player')), findsOneWidget);
    expect(find.byKey(const ValueKey('change-home:header')), findsNothing);
    await tester.tap(filter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home artwork').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('change-home:header')), findsOneWidget);
    expect(find.byKey(const ValueKey('change-default:player')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'shortcut search shows matching actions and an honest empty state',
      (tester) async {
    await mountSettings(tester);
    await tester.tap(find.byKey(const ValueKey('settings-category-2')));
    await tester.pumpAndSettle();
    final search = find.byKey(const ValueKey('settings-shortcut-search'));
    await tester.enterText(search, 'volume');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shortcut-binding-volumeUp')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('shortcut-binding-next')), findsNothing);
    await tester.enterText(search, 'not-a-shortcut');
    await tester.pumpAndSettle();
    expect(find.text('No matching shortcuts'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shortcut-binding-next')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'language settings apply Arabic immediately and persist the choice',
      (tester) async {
    await mountSettings(tester);
    await tester.tap(find.byKey(const ValueKey('settings-category-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-language-en')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العربية').last);
    await tester.pumpAndSettle();
    expect(find.text('لغة الواجهة'), findsOneWidget);
    expect(
        (await SharedPreferences.getInstance()).getString('app_locale'), 'ar');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
