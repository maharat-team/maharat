import 'package:flutter_test/flutter_test.dart';
import 'package:maharat/main.dart';

void main() {
  testWidgets('Maharat app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaharatApp());

    // Verify splash screen renders title or logo text
    expect(find.text('MAHARAT'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2500));
  });
}
