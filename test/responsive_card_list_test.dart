import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/components/ResponsiveCardList.dart';

void main() {
  test('phones get one column, tablets two or three', () {
    expect(responsiveColumns(390), 1);
    expect(responsiveColumns(599), 1);
    expect(responsiveColumns(744), 2); // iPad mini portrait
    expect(responsiveColumns(1024), 3); // iPad Pro portrait
    expect(responsiveColumns(1366), 3); // capped
  });

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ResponsiveCardList(
          itemCount: 5,
          itemBuilder: (_, i) => SizedBox(height: 60 + i * 10.0, child: Text('card $i')),
        ),
      ),
    ));
  }

  testWidgets('tablet lays cards side by side', (tester) async {
    await pump(tester, const Size(1024, 1366));
    expect(tester.takeException(), isNull);
    // 1024 wide minus padding -> 2 columns: cards 0 and 1 share a row.
    expect(tester.getTopLeft(find.text('card 0')).dy,
        tester.getTopLeft(find.text('card 1')).dy);
    expect(tester.getTopLeft(find.text('card 1')).dx,
        greaterThan(tester.getTopLeft(find.text('card 0')).dx));
    expect(find.text('card 4'), findsOneWidget);
  });

  testWidgets('phone keeps a single column', (tester) async {
    await pump(tester, const Size(390, 844));
    expect(tester.getTopLeft(find.text('card 0')).dx,
        tester.getTopLeft(find.text('card 1')).dx);
  });
}
