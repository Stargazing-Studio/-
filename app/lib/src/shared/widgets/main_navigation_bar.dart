import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ling_yan_tian_ji/src/features/ascension/application/eligibility_provider.dart';

class MainNavigationBar extends ConsumerWidget {
  const MainNavigationBar({super.key});

  static const _items = <_NavItem>[
    _NavItem(path: '/', label: '叙事', icon: Icons.menu_book_outlined),
    _NavItem(path: '/map', label: '地图', icon: Icons.map_outlined),
    _NavItem(path: '/market', label: '坊市', icon: Icons.storefront_outlined),
    _NavItem(path: '/auction', label: '拍卖', icon: Icons.gavel_outlined),
    _NavItem(path: '/realms', label: '秘境', icon: Icons.forest_outlined),
    _NavItem(path: '/ascension', label: '飞升', icon: Icons.auto_awesome),
  ];

  int _indexForLocation(String location) {
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.path == '/') {
        if (location == '/' || location.isEmpty) {
          return i;
        }
      } else if (location == item.path || location.startsWith('${item.path}/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = GoRouterState.of(context);
    final location = state.uri.path.isEmpty ? '/' : state.uri.path;
    final selected = _indexForLocation(location);
    final asc = ref.watch(ascensionEligibilityProvider);

    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (index) {
        final target = _items[index].path;
        if (target == '/ascension') {
          final eligible = asc.maybeWhen(data: (d) => d.eligible, orElse: () => true);
          if (!eligible) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('尚未达到开启条件（需要：炼气一阶）')),
            );
            return;
          }
        }
        if (target != location) context.go(target);
      },
      destinations: _items
          .map(
            (item) => NavigationDestination(
              icon: Icon(
                item.icon,
                color: (item.path == '/ascension' && asc.maybeWhen(data: (d) => !d.eligible, orElse: () => false))
                    ? Colors.white38
                    : null,
              ),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}

class _NavItem {
  const _NavItem({required this.path, required this.label, required this.icon});

  final String path;
  final String label;
  final IconData icon;
}
