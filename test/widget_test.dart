import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vistara_mobile/main.dart';

void main() {
  testWidgets('home introduces the preview catalogue', (tester) async {
    await tester.pumpWidget(const VistaraApp());

    expect(find.text('Movie lover'), findsOneWidget);
    expect(find.text('Preview catalogue'), findsOneWidget);
    expect(
      find.text('SAMPLE ARTWORK · NOT AVAILABLE TO WATCH'),
      findsOneWidget,
    );
  });

  testWidgets('catalogue search filters preview listings', (tester) async {
    await tester.pumpWidget(const VistaraApp());
    await tester.tap(find.text('Discover').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('catalogue-search')),
      'adventure',
    );
    await tester.pumpAndSettle();

    expect(find.text('Sample title 01'), findsOneWidget);
    expect(find.text('Sample title 02'), findsNothing);
  });

  testWidgets('offline passes never show fabricated prices', (tester) async {
    await tester.pumpWidget(const VistaraApp());
    await tester.tap(find.text('Passes').last);
    await tester.pumpAndSettle();

    expect(find.text('Vistara server not configured'), findsOneWidget);
    expect(find.text('Checkout not enabled'), findsOneWidget);
    expect(find.text('UGX 1,500'), findsNothing);
  });

  testWidgets('movie detail clearly states that playback is unavailable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const VistaraApp());
    await tester.tap(find.text('Discover').last);
    await tester.pumpAndSettle();

    final firstMovie = find.text('Sample title 01');
    await tester.ensureVisible(firstMovie);
    await tester.tap(firstMovie);
    await tester.pumpAndSettle();

    expect(find.text('Playback not available'), findsOneWidget);
    expect(find.text('Playback unavailable'), findsOneWidget);

    await tester.tap(find.text('Playback unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('PREVIEW PLAYER · NO VIDEO AVAILABLE'), findsOneWidget);
    expect(
      find.text(
        'No video is attached to this sample listing: '
        'Sample title 01.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('account form does not claim to authenticate', (tester) async {
    await tester.pumpWidget(const VistaraApp());
    await tester.tap(find.byIcon(Icons.person_outline).first);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Vistara server not configured'), findsOneWidget);
  });
}
