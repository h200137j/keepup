import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:keep_up/main.dart';

void main() {
  testWidgets('KeepUpApp boots without throwing', (WidgetTester tester) async {
    // path_provider/Isar need real platform channels, unavailable under
    // flutter test, so this only asserts the first frame renders cleanly
    // (dashboard's async data load is exercised via `flutter run`/build).
    await tester.pumpWidget(const ProviderScope(child: KeepUpApp()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
