import 'package:flutter_test/flutter_test.dart';
import 'package:recovery_track/features/auth/pages/login_page.dart';
import 'package:recovery_track/main.dart';

void main() {
  testWidgets('shows login page when signed out', (tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
