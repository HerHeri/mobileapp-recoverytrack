import 'package:flutter/material.dart';
import '../widgets/login_header.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = DateTime.now().year;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff667eea), Color(0xff764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                /// LOGIN CARD
                Container(
                  width: 380,
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),

                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),

                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LoginHeader(),
                      SizedBox(height: 24),
                      LoginForm(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// FOOTER (HANYA LOGIN PAGE)
                Text(
                  "© $year Suntik Radar · High Performance Vehicle Lookup System",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    // ignore: deprecated_member_use
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
