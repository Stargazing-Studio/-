import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ling_yan_tian_ji/src/routing/app_router.dart';
import 'package:ling_yan_tian_ji/src/theme/app_theme.dart';

class DaoYanApp extends ConsumerWidget {
  const DaoYanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: '灵衍天纪',
      theme: DaoYanTheme.buildTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return _GlobalOverlay(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class _GlobalOverlay extends StatelessWidget {
  const _GlobalOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0x330F172A), Color(0x99060A17)],
              radius: 1.2,
              center: Alignment.topCenter,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
