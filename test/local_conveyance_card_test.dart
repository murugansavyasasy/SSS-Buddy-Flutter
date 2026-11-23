import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/LocalConveyenceModel.dart';
import 'package:sssbuddy/components/LocalConveyenceCard.dart';

Localconveyencemodel _item(String status) => Localconveyencemodel.fromJson({
      'idLocalExpense': '1',
      'Username': 'Venkataravi C R',
      'monthOfClaim': 'November 2026',
      'RefId': 'LC-2026-11-0042',
      'TotalLocalExpense': '1250.5',
      'Description': 'School visits in Chennai',
      'Status': status,
      'LocalExpenseItems': [],
    });

void main() {
  for (final status in ['Paid', 'Waiting for approval from Reporting Manager']) {
    testWidgets('status "$status" is shown in full on a phone', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LocalConveyenceCard(item: _item(status)),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      final text = find.text(status);
      expect(text, findsOneWidget);
      // Not cut with an ellipsis: the laid-out text fits its box.
      final para = tester.renderObject<RenderParagraph>(text);
      expect(para.didExceedMaxLines, isFalse);
    });
  }
}
