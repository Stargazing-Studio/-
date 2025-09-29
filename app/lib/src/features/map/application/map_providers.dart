import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';
import 'package:ling_yan_tian_ji/src/features/auction/application/auction_providers.dart';
import 'package:ling_yan_tian_ji/src/features/market/application/market_providers.dart';

final mapDataProvider = FutureProvider<MapData>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchMap();
});

final currentLocationProvider = FutureProvider<LocationNode?>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchCurrentLocation();
});

final travelControllerProvider = Provider<TravelController>((ref) {
  final api = ref.watch(apiClientProvider);
  return TravelController(ref: ref, api: api);
});

class TravelController {
  TravelController({required this.ref, required this.api});

  final Ref ref;
  final ApiClient api;

  Future<TravelResponseData> travelTo(String locationId) async {
    final result = await api.travelTo(locationId);
    ref.invalidate(mapDataProvider);
    ref.invalidate(currentLocationProvider);
    // 位置变更后刷新坊市与拍卖数据
    ref.invalidate(marketShopsProvider);
    ref.invalidate(auctionHouseProvider);
    return result;
  }
}
