import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/platform_utils.dart';

class CustomLibrary {
  final List<String> folders;
  final List<String> files;
  final List<String> excludedFiles;
  final Map<String, String> customTitles;

  const CustomLibrary({
    this.folders = const [],
    this.files = const [],
    this.excludedFiles = const [],
    this.customTitles = const {},
  });
}

final customLibraryProvider =
    StateNotifierProvider<CustomLibraryNotifier, CustomLibrary>((ref) {
  return CustomLibraryNotifier();
});

class CustomLibraryNotifier extends StateNotifier<CustomLibrary> {
  static const _foldersKey = 'custom_music_folders';
  static const _filesKey = 'custom_music_files';
  static const _excludedKey = 'custom_music_excluded';
  static const _titlesKey = 'custom_song_titles';
  SharedPreferences? _prefs;
  late final Future<void> ready = _init();

  CustomLibraryNotifier() : super(const CustomLibrary()) {
    ready;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final folders = _prefs?.getStringList(_foldersKey) ?? [];
    final files = _prefs?.getStringList(_filesKey) ?? [];
    final excluded = _prefs?.getStringList(_excludedKey) ?? [];
    final titlesRaw = _prefs?.getString(_titlesKey);
    final customTitles = <String, String>{};
    if (titlesRaw != null) {
      try {
        final decoded = jsonDecode(titlesRaw) as Map<String, dynamic>;
        customTitles.addAll(decoded.map((k, v) => MapEntry(k, v.toString())));
      } catch (_) {}
    }
    state = CustomLibrary(
      folders: folders,
      files: files,
      excludedFiles: excluded,
      customTitles: customTitles,
    );
    // Desktop paths can live on disconnected drives. Keep their exclusions so
    // a later refresh can ask before restoring them.
    if (isMobile) pruneNonExistentExclusions();
  }

  Future<void> setSongTitle(String path, String newTitle) async {
    await ready;
    if (!mounted) return;
    final normalized = normalizePath(path);
    final newTitles = Map<String, String>.from(state.customTitles);
    newTitles[normalized] = newTitle;
    state = CustomLibrary(
      folders: state.folders,
      files: state.files,
      excludedFiles: state.excludedFiles,
      customTitles: newTitles,
    );
    await _prefs?.setString(_titlesKey, jsonEncode(newTitles));
  }

  Future<void> addFolder(String path) async {
    await ready;
    if (!mounted) return;
    final separator = Platform.pathSeparator;
    final normalizedAddPath = normalizePath(path);
    final folderPrefix = normalizedAddPath.endsWith(separator)
        ? normalizedAddPath
        : '$normalizedAddPath$separator';

    // Always remove from exclusions if it was there (using normalized comparison)
    final newExcluded = state.excludedFiles.where((p) {
      final normalizedP = normalizePath(p);
      return !normalizedP.startsWith(folderPrefix) &&
          normalizedP != normalizedAddPath;
    }).toList();

    if (!state.folders.contains(path)) {
      final newFolders = [...state.folders, path];
      state = CustomLibrary(
        folders: newFolders,
        files: state.files,
        excludedFiles: newExcluded,
        customTitles: state.customTitles,
      );
      await _prefs?.setStringList(_foldersKey, newFolders);
    } else {
      state = CustomLibrary(
        folders: state.folders,
        files: state.files,
        excludedFiles: newExcluded,
        customTitles: state.customTitles,
      );
    }
    await _prefs?.setStringList(_excludedKey, newExcluded);
  }

  Future<void> addFile(String path) => addFiles([path]);

  /// One notification and two preference writes for an entire import. Perform
  /// filesystem checks asynchronously and merge against the latest state.
  Future<void> addFiles(Iterable<String> paths) async {
    await ready;
    if (!mounted) return;
    final additions = <String, String>{};
    for (final path in paths) {
      if (path.trim().isEmpty) continue;
      final normalized = normalizePath(path);
      if (additions.containsKey(normalized)) continue;
      try {
        if (await FileSystemEntity.type(path) ==
            FileSystemEntityType.directory) {
          continue;
        }
      } catch (_) {}
      if (!mounted) return;
      additions[normalized] = path;
    }
    if (additions.isEmpty) return;
    final known = state.files.map(normalizePath).toSet();
    final newFiles = [
      ...state.files,
      for (final entry in additions.entries)
        if (known.add(entry.key)) entry.value
    ];
    final newExcluded = state.excludedFiles
        .where((p) => !additions.containsKey(normalizePath(p)))
        .toList();
    if (newFiles.length == state.files.length &&
        newExcluded.length == state.excludedFiles.length) {
      return;
    }

    state = CustomLibrary(
      folders: state.folders,
      files: newFiles,
      excludedFiles: newExcluded,
      customTitles: state.customTitles,
    );
    await _prefs?.setStringList(_filesKey, newFiles);
    await _prefs?.setStringList(_excludedKey, newExcluded);
  }

  Future<void> removeFolder(String path) async {
    await ready;
    if (!mounted) return;
    final newFolders = state.folders.where((p) => p != path).toList();
    // Keep the exclusions - dropping them silently un-hid every file the user
    // had removed from the library.
    state = CustomLibrary(
      folders: newFolders,
      files: state.files,
      excludedFiles: state.excludedFiles,
      customTitles: state.customTitles,
    );
    await _prefs?.setStringList(_foldersKey, newFolders);
  }

  Future<void> removeFile(String path) async {
    await ready;
    if (!mounted) return;
    final newFiles = state.files.where((p) => p != path).toList();
    state = CustomLibrary(
      folders: state.folders,
      files: newFiles,
      excludedFiles: state.excludedFiles,
      customTitles: state.customTitles,
    );
    await _prefs?.setStringList(_filesKey, newFiles);
  }

  Future<void> excludeFile(String path) async {
    await ready;
    if (!mounted) return;
    // Store the normalised path: the scanner compares normalised exclusions,
    // so a raw path could silently fail to hide the file.
    final normalized = normalizePath(path);
    if (!state.excludedFiles.any((p) => normalizePath(p) == normalized)) {
      final newExcluded = [...state.excludedFiles, normalized];
      state = CustomLibrary(
        folders: state.folders,
        files: state.files,
        excludedFiles: newExcluded,
        customTitles: state.customTitles,
      );
      await _prefs?.setStringList(_excludedKey, newExcluded);
    }
  }

  Future<void> excludeFiles(Iterable<String> paths) async {
    await ready;
    if (!mounted) return;
    final excluded = state.excludedFiles.map(normalizePath).toSet()
      ..addAll(paths.map(normalizePath));
    final list = excluded.toList();
    state = CustomLibrary(
        folders: state.folders,
        files: state.files,
        excludedFiles: list,
        customTitles: state.customTitles);
    await _prefs?.setStringList(_excludedKey, list);
  }

  Future<void> unexcludeFile(String path) async {
    await ready;
    if (!mounted) return;
    final normalized = normalizePath(path);
    final newExcluded = state.excludedFiles
        .where((p) => normalizePath(p) != normalized)
        .toList();
    if (newExcluded.length != state.excludedFiles.length) {
      state = CustomLibrary(
        folders: state.folders,
        files: state.files,
        excludedFiles: newExcluded,
        customTitles: state.customTitles,
      );
      await _prefs?.setStringList(_excludedKey, newExcluded);
    }
  }

  Future<void> unexcludeFiles(Iterable<String> paths) async {
    await ready;
    if (!mounted) return;
    if (paths.isEmpty) return;
    final normalizedSet = paths.map(normalizePath).toSet();
    final newExcluded = state.excludedFiles
        .where((p) => !normalizedSet.contains(normalizePath(p)))
        .toList();
    if (newExcluded.length != state.excludedFiles.length) {
      state = CustomLibrary(
        folders: state.folders,
        files: state.files,
        excludedFiles: newExcluded,
        customTitles: state.customTitles,
      );
      await _prefs?.setStringList(_excludedKey, newExcluded);
    }
  }

  Future<void> pruneNonExistentExclusions() async {
    await ready;
    if (!mounted) return;
    if (state.excludedFiles.isEmpty) return;
    final initial = state.excludedFiles;
    final validExclusions = <String>[];
    for (final p in initial) {
      try {
        if (await File(p).exists()) {
          validExclusions.add(p);
        }
      } catch (_) {}
    }
    if (!mounted || !identical(state.excludedFiles, initial)) return;
    if (validExclusions.length != state.excludedFiles.length) {
      state = CustomLibrary(
        folders: state.folders,
        files: state.files,
        excludedFiles: validExclusions,
        customTitles: state.customTitles,
      );
      await _prefs?.setStringList(_excludedKey, validExclusions);
    }
  }

  Future<void> clearExclusions() async {
    await ready;
    if (!mounted) return;
    state = CustomLibrary(
      folders: state.folders,
      files: state.files,
      excludedFiles: const [],
      customTitles: state.customTitles,
    );
    await _prefs?.remove(_excludedKey);
  }
}
