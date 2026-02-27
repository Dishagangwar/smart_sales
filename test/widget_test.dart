import 'package:flutter_test/flutter_test.dart';
import 'package:smart_sales/main.dart';

void main() {
  testWidgets('Login screen loads test', (WidgetTester tester) async {

    await tester.pumpWidget(SmartSalesApp());

    expect(find.text('Smart Sales'), findsOneWidget);

  });
}