import 'package:flutter_test/flutter_test.dart';
import 'package:glazia_home_secure_app/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows authentication screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const GlaziaHomeSecureApp());
    await tester.pump();

    expect(find.text('Glazia Home Secure'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.text('Backend URL'), findsNothing);
  });
}
