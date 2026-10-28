import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:toneharbor/services/cache_cleanup_service.dart';

class _Paths extends PathProviderPlatform {
  final String temp;
  _Paths(this.temp);
  @override
  Future<String?> getTemporaryPath() async => temp;
}

void main() {
  late Directory root;
  late PathProviderPlatform original;
  setUp(() async {
    root = await Directory.systemTemp.createTemp(
      'toneharbor-cache-scope-test-',
    );
    original = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(root.path);
  });
  tearDown(() async {
    PathProviderPlatform.instance = original;
    expect(p.basename(root.path), startsWith('toneharbor-cache-scope-test-'));
    await root.delete(recursive: true);
  });

  test(
    'clear and cache size never touch unrelated or similarly named Temp entries',
    () async {
      final unrelated = File(p.join(root.path, 'other-app', 'session.txt'));
      await unrelated.parent.create();
      await unrelated.writeAsString('private application state');
      final sibling = File(
        p.join(root.path, 'toneharbor-cache-other', 'keep.txt'),
      );
      await sibling.parent.create();
      await sibling.writeAsString('keep');
      final working = await CacheCleanupService.createTemporaryDirectory(
        'editor-',
      );
      final owned = File(p.join(working.path, 'preview.wav'));
      await owned.writeAsBytes(List.filled(64, 1));
      expect(await CacheCleanupService.getCacheSizeBytes(), 64);
      expect(
        await CacheCleanupService.deleteIfTemporary(unrelated.path),
        isFalse,
      );
      expect(
        await CacheCleanupService.deleteIfTemporary(sibling.path),
        isFalse,
      );
      await CacheCleanupService.clearAllCache();
      expect(await unrelated.readAsString(), 'private application state');
      expect(await sibling.readAsString(), 'keep');
      expect(await owned.exists(), isFalse);
      expect(await CacheCleanupService.getCacheSizeBytes(), 0);
    },
  );

  test(
    'startup age threshold keeps fresh working files and removes stale owned files',
    () async {
      final cache = await CacheCleanupService.directory();
      final fresh = File(p.join(cache.path, 'fresh.wav'));
      final stale = File(p.join(cache.path, 'stale.wav'));
      await fresh.writeAsString('fresh');
      await stale.writeAsString('stale');
      await stale.setLastModified(
        DateTime.now().subtract(const Duration(days: 3)),
      );
      await CacheCleanupService.clearAllCache(
        olderThan: const Duration(days: 1),
      );
      expect(await fresh.readAsString(), 'fresh');
      expect(await stale.exists(), isFalse);
      expect(await CacheCleanupService.deleteIfTemporary(fresh.path), isTrue);
    },
  );
}
