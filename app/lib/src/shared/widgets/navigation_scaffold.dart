import 'package:flutter/material.dart';

import 'main_navigation_bar.dart';

class NavigationScaffold extends StatelessWidget {
  const NavigationScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.floatingActionButton,
    this.extendBody = false,
    this.bottom,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final bool extendBody;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      extendBody: extendBody,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bottom != null) bottom!,
          const MainNavigationBar(),
        ],
      ),
    );
  }
}
