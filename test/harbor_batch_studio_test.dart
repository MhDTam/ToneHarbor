import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toneharbor/features/desktop/harbor_batch_studio.dart';
import 'package:toneharbor/features/desktop/toneharbor_desktop.dart';
import 'package:toneharbor/l10n/app_localizations.dart';

class _Picker extends FilePicker {
  bool multiple = false;
  @override
  Future<FilePickerResult?> pickFiles(
      {String? dialogTitle,
      String? initialDirectory,
      FileType type = FileType.any,
      List<String>? allowedExtensions,
      Function(FilePickerStatus)? onFileLoading,
      bool allowCompression = true,
      int compressionQuality = 30,
      bool allowMultiple = false,
      bool withData = false,
      bool withReadStream = false,
      bool lockParentWindow = false,
      bool readSequential = false}) async {
    multiple = allowMultiple;
    return FilePickerResult([
      PlatformFile(name: 'First.mp4', path: r'C:\Media\First.mp4', size: 1),
      PlatformFile(name: 'Second.wav', path: r'C:\Media\Second.wav', size: 1),
    ]);
  }
}

void main() {
  testWidgets('converter picks multiple files and supports queue removal',
      (tester) async {
    final picker = _Picker();
    FilePicker.platform = picker;
    tester.view.physicalSize = const Size(900, 650);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(MaterialApp(
      theme: buildHarborTheme(),
      home: const Scaffold(body: HarborBatchStudio()),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose files'));
    await tester.pumpAndSettle();
    expect(picker.multiple, isTrue);
    expect(find.text('First.mp4'), findsOneWidget);
    expect(find.text('Second.wav'), findsOneWidget);
    expect(find.text('2 files'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove').first);
    await tester.pumpAndSettle();
    expect(find.text('First.mp4'), findsNothing);
    expect(find.text('1 file'), findsOneWidget);
    await tester.tap(find.text('Add files'));
    await tester.pumpAndSettle();
    expect(find.text('2 files'), findsOneWidget);
    expect(find.text('Second.wav'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
