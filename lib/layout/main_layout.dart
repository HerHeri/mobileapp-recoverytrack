import 'package:flutter/material.dart';
import 'topbar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final int activeIndex;
  final List<Widget>? appBarActions;
  final Future<void> Function()? onKeyboardSettings;
  final EdgeInsetsGeometry contentPadding;

  const MainLayout({
    super.key,
    required this.child,
    this.activeIndex = 1,
    this.appBarActions,
    this.onKeyboardSettings,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: theme.brightness == Brightness.light
                ? const LinearGradient(
                    colors: [Color(0xFFF1F5FF), Color(0xFFF8FAFC)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
          ),
          child: Column(
            children: [
              TopBar(
                activeIndex: activeIndex,
                actions: appBarActions,
                onKeyboardSettings: onKeyboardSettings,
              ),
              Expanded(
                child: Padding(padding: contentPadding, child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
