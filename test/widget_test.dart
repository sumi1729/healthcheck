import 'package:flutter_test/flutter_test.dart';
import 'package:healthcheck/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HealthCheckApp());
    expect(find.text('登録'), findsWidgets);
  });
}
