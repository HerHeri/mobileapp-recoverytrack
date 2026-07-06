import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/pages/login_page.dart';
import 'features/dashboard/pages/dashboard_page.dart';
import 'storage/token_storage.dart';
import 'package:screen_protector/screen_protector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent screenshots (Mobile only, will be ignored on Web)
  if (!kIsWeb) {
    await ScreenProtector.preventScreenshotOn();
  }

  // Check if token exists
  final token = await TokenStorage.getToken();
  final bool isLoggedIn = token != null && token.isNotEmpty;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AppTheme.themeNotifier,

      builder: (context, ThemeMode currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,

          themeMode: currentMode,

          home: isLoggedIn ? const DashboardPage() : const LoginPage(),
        );
      },
    );
  }
}
