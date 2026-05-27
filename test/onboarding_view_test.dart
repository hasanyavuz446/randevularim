import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:randevularim/views/onboarding/onboarding_view.dart';

void main() {
  testWidgets('onboarding advances through all slides and completes', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingView(
          onCompleted: () async {
            completed = true;
          },
        ),
      ),
    );

    expect(find.text('Hoş Geldiniz'), findsOneWidget);
    expect(find.text('Sonraki'), findsOneWidget);

    await tester.tap(find.text('Sonraki'));
    await tester.pumpAndSettle();
    expect(find.text('Randevularını Yönet'), findsOneWidget);

    await tester.tap(find.text('Sonraki'));
    await tester.pumpAndSettle();
    expect(find.text('Müşterilerini Takip Et'), findsOneWidget);
    expect(find.text('Başla'), findsOneWidget);

    await tester.tap(find.text('Başla'));
    await tester.pump();
    expect(completed, isTrue);
  });
}
