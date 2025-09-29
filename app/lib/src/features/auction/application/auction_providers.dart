import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';

final auctionHouseProvider = FutureProvider<AuctionHouseData?>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchCurrentAuction();
});
