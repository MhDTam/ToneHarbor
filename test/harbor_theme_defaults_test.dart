import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toneharbor/features/desktop/harbor_themes.dart';

void main() {
  test('Ocean is the new default and replaces the old initial Forest only once',
      () async {
    SharedPreferences.setMockInitialValues({'harbor_theme': 'forest'});
    final notifier = HarborThemeNotifier();
    expect(notifier.state, HarborTheme.ocean);
    await notifier.ready;
    expect(notifier.state, HarborTheme.ocean);
    await notifier.setTheme(HarborTheme.forest);
    final reloaded = HarborThemeNotifier();
    await reloaded.ready;
    expect(reloaded.state, HarborTheme.forest);
    notifier.dispose();
    reloaded.dispose();
  });
  test('existing custom palettes and a fast manual choice are preserved',
      () async {
    SharedPreferences.setMockInitialValues({'harbor_theme': 'amber'});
    final existing = HarborThemeNotifier();
    await existing.ready;
    expect(existing.state, HarborTheme.amber);
    existing.dispose();
    SharedPreferences.setMockInitialValues({});
    final changing = HarborThemeNotifier();
    await changing.setTheme(HarborTheme.violet);
    await changing.ready;
    expect(changing.state, HarborTheme.violet);
    final reloaded = HarborThemeNotifier();
    await reloaded.ready;
    expect(reloaded.state, HarborTheme.violet);
    changing.dispose();
    reloaded.dispose();
  });
}
