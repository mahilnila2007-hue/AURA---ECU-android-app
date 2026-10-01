import 'package:flutter_test/flutter_test.dart';
import 'package:aura_ecu/main.dart';

void main() {
  testWidgets('AuraEcuApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AuraEcuApp());

    // Verify that the title or navigation shell renders.
    expect(find.text('AURA-ECU'), findsWidgets);
    expect(find.text('HOME'), findsWidgets);
  });
}
