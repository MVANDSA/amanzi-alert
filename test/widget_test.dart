import 'package:flutter_test/flutter_test.dart';
import 'package:aqualink/main.dart';

void main() {
  testWidgets('AquaLink home page loads', (WidgetTester tester) async {
    await tester.pumpWidget(const AquaLinkApp());

    expect(find.text('AquaLink'), findsOneWidget);
    expect(find.text('Hello, Community!'), findsOneWidget);
    expect(find.text('Report a Problem'), findsOneWidget);
  });
}
