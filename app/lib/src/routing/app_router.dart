import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ling_yan_tian_ji/src/features/alchemy/presentation/alchemy_workshops_page.dart';
import 'package:ling_yan_tian_ji/src/features/auction/presentation/auction_house_page.dart';
import 'package:ling_yan_tian_ji/src/features/map/presentation/map_page.dart';
import 'package:ling_yan_tian_ji/src/features/market/presentation/market_page.dart';
import 'package:ling_yan_tian_ji/src/features/ascension/presentation/ascension_dashboard_page.dart';
import 'package:ling_yan_tian_ji/src/features/companions/presentation/companion_hub_page.dart';
import 'package:ling_yan_tian_ji/src/features/home/presentation/home_page.dart';
import 'package:ling_yan_tian_ji/src/features/logs/presentation/log_center_page.dart';
import 'package:ling_yan_tian_ji/src/features/profile/presentation/profile_page.dart';
import 'package:ling_yan_tian_ji/src/features/realms/presentation/secret_realm_page.dart';
import 'package:ling_yan_tian_ji/src/features/technique/presentation/technique_library_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const MapPage(),
      ),
      GoRoute(
        path: '/market',
        name: 'market',
        builder: (context, state) => const MarketPage(),
      ),
      GoRoute(
        path: '/auction',
        name: 'auction',
        builder: (context, state) => const AuctionHousePage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/companions',
        name: 'companions',
        builder: (context, state) => const CompanionHubPage(),
      ),
      GoRoute(
        path: '/realms',
        name: 'realms',
        builder: (context, state) => const SecretRealmPage(),
      ),
      GoRoute(
        path: '/ascension',
        name: 'ascension',
        builder: (context, state) => const AscensionDashboardPage(),
      ),
      GoRoute(
        path: '/alchemy',
        name: 'alchemy',
        builder: (context, state) => const AlchemyWorkshopsPage(),
      ),
      GoRoute(
        path: '/techniques',
        name: 'techniques',
        builder: (context, state) => const TechniqueLibraryPage(),
      ),
      GoRoute(
        path: '/chronicles',
        name: 'chronicles',
        builder: (context, state) => const LogCenterPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('未找到页面：${state.uri.toString()}'))),
  );
});
