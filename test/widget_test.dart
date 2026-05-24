import 'package:flutter_test/flutter_test.dart';
import 'package:ferrit_tool/main.dart';

void main() {
  testWidgets('app boots into the home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const FerritToolApp());
    await tester.pump();

    expect(find.text('Твой Ferrrit'), findsOneWidget);
  });
}
