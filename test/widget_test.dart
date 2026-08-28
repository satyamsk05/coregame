import 'package:flutter_test/flutter_test.dart';
import 'package:core_game/main.dart';

void main() {
  testWidgets('Welcome screen elements test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CoreGameApp());

    // Verify that our game title 'CORE' is displayed.
    expect(find.text('CORE'), findsOneWidget);

    // Verify that the 'LOGIN' and 'SIGN UP' buttons are present.
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('SIGN UP'), findsOneWidget);
  });
}
