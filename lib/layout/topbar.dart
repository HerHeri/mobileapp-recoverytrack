import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/pages/login_page.dart';
import '../storage/token_storage.dart';
import '../services/auth_service.dart';
import '../features/dashboard/pages/profile_page.dart';

class TopBar extends StatelessWidget {
  final List<Widget>? actions;

  const TopBar({super.key, this.actions});

  Future<void> logout(BuildContext context) async {
    try {
      await AuthService.logout();
    } catch (e) {
      debugPrint("Server logout failed: $e");
    }

    await TokenStorage.clearToken();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [Color(0xff667eea), Color(0xff764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isDark ? theme.colorScheme.surface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? theme.colorScheme.surface : Colors.transparent,
          ),
        ),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Suntik Radar",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  if (version.isNotEmpty)
                    Text(
                      "v$version",
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                ],
              );
            },
          ),
          Row(
            children: [
              /// TOGGLE THEME
              ...?actions,
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () {
                  AppTheme.toggleTheme();
                },
              ),
              FutureBuilder<String?>(
                future: TokenStorage.getPhoto(),
                builder: (context, snapshot) {
                  final photoUrl = snapshot.data;
                  return PopupMenuButton<String>(
                    icon: (photoUrl != null && photoUrl.isNotEmpty)
                        ? CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(photoUrl),
                          )
                        : const Icon(Icons.person, color: Colors.white),
                    onSelected: (value) async {
                      if (value == 'profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      } else if (value == 'logout') {
                        await logout(context);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'profile',
                            child: ListTile(
                              leading: Icon(Icons.person_outline),
                              title: Text('Profil'),
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: ListTile(
                              leading: Icon(Icons.logout),
                              title: Text('Logout'),
                            ),
                          ),
                        ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
