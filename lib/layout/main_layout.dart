import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'topbar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final int activeIndex;
  final List<Widget>? appBarActions;

  const MainLayout({
    super.key,
    required this.child,
    this.activeIndex = 1,
    this.appBarActions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(actions: appBarActions),
            Expanded(
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MainBottomBar(currentIndex: activeIndex),
    );
  }
}
