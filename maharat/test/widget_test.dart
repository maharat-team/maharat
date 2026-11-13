import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maharat/features/customer/customer_main_screen.dart';
import 'package:maharat/features/onboarding/email_auth_screen.dart';
import 'package:maharat/features/onboarding/language_selection_screen.dart';
import 'package:maharat/main.dart';
import 'package:maharat/state/app_state.dart';
import 'package:provider/provider.dart';
import 'fixtures/fake_backend.dart';

void main() {
  Future<void> finishSplash(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('a guest lands on language selection', (tester) async {
    final state = FakeBackend(userId: null).createState();
    await tester.pumpWidget(MaharatApp(appState: state));

    expect(find.text('MAHARAT'), findsOneWidget);
    await finishSplash(tester);

    expect(find.byType(LanguageSelectionScreen), findsOneWidget);
  });

  testWidgets('a returning customer skips onboarding', (tester) async {
    final state = FakeBackend().createState();
    await tester.pumpWidget(MaharatApp(appState: state));
    await finishSplash(tester);

    expect(find.byType(CustomerMainScreen), findsOneWidget);
  });

  testWidgets('losing the session returns to onboarding', (tester) async {
    final backend = FakeBackend();
    final state = backend.createState();
    await tester.pumpWidget(MaharatApp(appState: state));
    await finishSplash(tester);

    await state.signOut();
    await tester.pumpAndSettle();

    expect(find.byType(LanguageSelectionScreen), findsOneWidget);
    expect(find.byType(CustomerMainScreen), findsNothing);
  });

  group('email sign-in', () {
    Future<AppState> openCodeEntry(WidgetTester tester) async {
      final state = FakeBackend(userId: null).createState();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(home: EmailAuthScreen()),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'Test@Example.com ');
      await tester.tap(find.text('Send Verification Code'));
      await tester.pump();
      return state;
    }

    testWidgets('an invalid address is not sent', (tester) async {
      final state = FakeBackend(userId: null).createState();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: const MaterialApp(home: EmailAuthScreen()),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.tap(find.text('Send Verification Code'));
      await tester.pump();

      expect(find.text('Verification Code'), findsNothing);
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows six boxes and the normalised address', (tester) async {
      await openCodeEntry(tester);

      expect(find.byType(TextFormField), findsNWidgets(6));
      expect(find.text('Code sent to test@example.com'), findsOneWidget);
    });

    testWidgets('a pasted code fills every box', (tester) async {
      await openCodeEntry(tester);

      await tester.enterText(find.byType(TextFormField).first, '482913');
      await tester.pump();

      for (final (index, digit) in '482913'.split('').indexed) {
        final field = tester.widget<TextFormField>(
          find.byType(TextFormField).at(index),
        );
        expect(field.controller!.text, digit);
      }
    });

    testWidgets('letters cannot be typed into the code', (tester) async {
      await openCodeEntry(tester);

      await tester.enterText(find.byType(TextFormField).first, 'a');
      await tester.pump();

      final field = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('an incomplete code is not submitted', (tester) async {
      await openCodeEntry(tester);

      await tester.enterText(find.byType(TextFormField).first, '123');
      await tester.pump();
      await tester.tap(find.text('Verify & Proceed'));
      await tester.pump();

      expect(
        find.text('Please enter all 6 digits of the code'),
        findsOneWidget,
      );
    });

    testWidgets('code entry fits a small phone', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openCodeEntry(tester);

      expect(tester.takeException(), isNull);
    });
  });
}
