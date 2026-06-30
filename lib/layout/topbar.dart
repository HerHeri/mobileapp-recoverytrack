import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/pages/login_page.dart';
import '../storage/token_storage.dart';
import '../services/auth_service.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/dashboard/pages/history_log.dart';
import '../features/dashboard/pages/kendaraan_management_page.dart';
import '../features/dashboard/pages/keyboard_setting_page.dart';
import '../features/dashboard/pages/payment_page.dart';
import '../features/dashboard/pages/profile_page.dart';

class TopBar extends StatelessWidget {
  final List<Widget>? actions;
  final int activeIndex;
  final Future<void> Function()? onKeyboardSettings;

  const TopBar({
    super.key,
    this.actions,
    required this.activeIndex,
    this.onKeyboardSettings,
  });

  static const _menuItems = [
    _NavigationItem(
      'Riwayat',
      'Lihat aktivitas pencarian',
      Icons.history_rounded,
    ),
    _NavigationItem('Pencarian', 'Cari data kendaraan', Icons.search_rounded),
    _NavigationItem(
      'Pembayaran',
      'Paket dan transaksi',
      Icons.payments_rounded,
    ),
    _NavigationItem('Profil', 'Informasi akun Anda', Icons.person_rounded),
  ];

  void _navigate(BuildContext context, int index) {
    if (index == activeIndex) return;

    final Widget page = switch (index) {
      0 => const HistoryLogPage(),
      1 => const DashboardPage(),
      2 => const PaymentPage(),
      _ => const ProfilePage(),
    };

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

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

  Future<void> _openKeyboardSettings(BuildContext context) async {
    if (onKeyboardSettings != null) {
      await onKeyboardSettings!();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KeyboardSettingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(9, 2, 9, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [Color(0xFF536DFE), Color(0xFF7C4DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isDark ? theme.colorScheme.surface : null,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 390;

          return Row(
            children: [
              Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.track_changes_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version ?? '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          compact ? "Recovery Track" : "Recovery Track",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (version.isNotEmpty)
                          Text(
                            "v$version",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              ...?actions?.map(_actionSurface),
              _headerButton(
                tooltip: isDark ? 'Mode terang' : 'Mode gelap',
                icon: isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                onPressed: AppTheme.toggleTheme,
              ),
              FutureBuilder<Map<String, dynamic>>(
                future: AuthService.getProfile().catchError(
                  (_) => <String, dynamic>{},
                ),
                builder: (context, profileSnapshot) {
                  final res = profileSnapshot.data;
                  final data = res != null
                      ? ((res['data'] as Map<String, dynamic>?) ??
                            (res['user'] as Map<String, dynamic>?) ??
                            res)
                      : null;
                  final role = data?['role']?.toString().trim().toLowerCase();
                  const allowedRoles = {
                    'super_admin',
                    'admin',
                    'admin_leasing',
                    'super admin',
                    'admin leasing',
                  };
                  final hasAccess = role != null && allowedRoles.contains(role);

                  return PopupMenuButton<int>(
                    tooltip: 'Menu',
                    offset: const Offset(0, 52),
                    constraints: const BoxConstraints(
                      minWidth: 360,
                      maxWidth: 360,
                    ),
                    color: theme.colorScheme.surface,
                    elevation: 16,
                    shadowColor: Colors.black.withValues(alpha: 0.22),
                    clipBehavior: Clip.antiAlias,
                    menuPadding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                    onSelected: (value) async {
                      if (value == -1) {
                        await logout(context);
                      } else if (value == 4) {
                        await _openKeyboardSettings(context);
                      } else if (value == 5) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const KendaraanManagementPage(),
                          ),
                        );
                      } else {
                        _navigate(context, value);
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        for (var index = 0; index < _menuItems.length; index++)
                          PopupMenuItem<int>(
                            value: index,
                            height: 62,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: _menuTile(
                              context,
                              _menuItems[index],
                              index == activeIndex,
                            ),
                          ),
                        const PopupMenuDivider(height: 12),
                        PopupMenuItem<int>(
                          value: 4,
                          height: 62,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: _menuTile(
                            context,
                            const _NavigationItem(
                              'Setting Keyboard',
                              'Layout, ukuran, dan getaran',
                              Icons.keyboard_alt_outlined,
                            ),
                            false,
                          ),
                        ),
                        // Item Manajemen Kendaraan — hanya untuk role admin
                        if (hasAccess)
                          PopupMenuItem<int>(
                            value: 5,
                            height: 62,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: _AdminMenuItemWrapper(
                              child: _menuTile(
                                context,
                                const _NavigationItem(
                                  'Manajemen Kendaraan',
                                  'Import & input data kendaraan',
                                  Icons.directions_car_rounded,
                                ),
                                false,
                                accent: const Color(0xFF536DFE),
                              ),
                            ),
                          ),
                        const PopupMenuDivider(height: 12),
                        PopupMenuItem<int>(
                          value: -1,
                          height: 62,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: _menuTile(
                            context,
                            const _NavigationItem(
                              'Logout',
                              'Keluar dari akun ini',
                              Icons.logout_rounded,
                            ),
                            false,
                            destructive: true,
                          ),
                        ),
                      ];
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _actionSurface(Widget action) {
    return IconTheme(
      data: const IconThemeData(color: Colors.white, size: 21),
      child: SizedBox(width: 40, height: 40, child: action),
    );
  }

  Widget _headerButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    _NavigationItem item,
    bool selected, {
    bool destructive = false,
    Color? accent,
  }) {
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : accent ??
              (selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.7)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: destructive
                  ? Theme.of(
                      context,
                    ).colorScheme.errorContainer.withValues(alpha: 0.7)
                  : selected
                  ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.14)
                  : Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(item.icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: destructive
                        ? color.withValues(alpha: 0.72)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 16,
              ),
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              color: themeColor(context).withValues(alpha: 0.38),
              size: 20,
            ),
        ],
      ),
    );
  }

  Color themeColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

class _NavigationItem {
  final String label;
  final String subtitle;
  final IconData icon;

  const _NavigationItem(this.label, this.subtitle, this.icon);
}

/// Wrapper untuk item menu Manajemen Kendaraan — selalu tampil,
/// role guard ditangani di dalam halaman KendaraanManagementPage.
class _AdminMenuItemWrapper extends StatelessWidget {
  final Widget child;
  const _AdminMenuItemWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: 4,
          top: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF536DFE).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF536DFE).withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF536DFE),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
