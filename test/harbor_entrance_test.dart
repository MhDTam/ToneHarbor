import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toneharbor/features/desktop/harbor_entrance.dart';

void main() {
  testWidgets('rapid changes keep only the latest surface and stable bounds',
      (tester) async {
    Widget view(int id, {bool reduced = false}) => MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: SizedBox(
                width: 400,
                height: 300,
                child: HarborEntrance(
                    trigger: id,
                    child: Text('Track $id', key: ValueKey(id))))));
    await tester.pumpWidget(view(1));
    final before = tester.getSize(find.byType(HarborEntrance));
    for (var i = 2; i < 9; i++) {
      await tester.pumpWidget(view(i));
      await tester.pump(const Duration(milliseconds: 15));
      expect(find.text('Track ${i - 1}'), findsNothing);
      expect(find.text('Track $i'), findsOneWidget);
      expect(tester.getSize(find.byType(HarborEntrance)), before);
    }
    await tester.pumpAndSettle();
    await tester.pumpWidget(view(9, reduced: true));
    expect(
        tester
            .widget<Opacity>(find.descendant(
                of: find.byType(HarborEntrance),
                matching: find.byType(Opacity)))
            .opacity,
        1);
    expect(tester.takeException(), isNull);
  });
}
