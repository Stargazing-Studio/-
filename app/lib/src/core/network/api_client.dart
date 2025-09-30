import 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:ling_yan_tian_ji/src/core/network/http_adapter_stub.dart'
    if (dart.library.html)
        'package:ling_yan_tian_ji/src/core/network/http_adapter_web.dart'
    if (dart.library.io)
        'package:ling_yan_tian_ji/src/core/network/http_adapter_io.dart';

import 'package:ling_yan_tian_ji/src/core/config/app_config.dart';
import 'package:ling_yan_tian_ji/src/features/common/models/game_entities.dart';

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  var dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      // 提高默认超时，避免 AI 初始化长耗时导致失败
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 90),
    ),
  );
  dio = configureDioForPlatform(dio);
  // 轻量日志，便于确认 /profile 是否发出
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('[DIO] => ${options.method} ${options.uri}');
        handler.next(options);
      },
      onError: (e, handler) {
        debugPrint('[DIO] <= ERROR ${e.requestOptions.method} ${e.requestOptions.uri} ${e.response?.statusCode}');
        handler.next(e);
      },
      onResponse: (resp, handler) {
        debugPrint('[DIO] <= ${resp.requestOptions.method} ${resp.requestOptions.uri} ${resp.statusCode}');
        handler.next(resp);
      },
    ),
  );
  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<PlayerProfile> fetchProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/profile');
    return PlayerProfile.fromJson(response.data!);
  }

  Future<String?> whoAmI() async {
    final response = await _dio.get<Map<String, dynamic>>('/whoami');
    return (response.data ?? const {})['player_id'] as String?;
  }

  Future<List<Companion>> fetchCompanions() async {
    final response = await _dio.get<List<dynamic>>('/companions');
    return response.data!
        .map((item) => Companion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SecretRealm>> fetchSecretRealms() async {
    final response = await _dio.get<List<dynamic>>('/secret-realms');
    return response.data!
        .map((item) => SecretRealm.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AscensionChallenge>> fetchAscensionChallenges() async {
    final response = await _dio.get<List<dynamic>>('/ascension/challenges');
    return response.data!
        .map(
          (item) => AscensionChallenge.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<PillRecipe>> fetchPillRecipes() async {
    final response = await _dio.get<List<dynamic>>('/alchemy/recipes');
    return response.data!
        .map((item) => PillRecipe.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChronicleLog>> fetchChronicles() async {
    final response = await _dio.get<List<dynamic>>('/chronicles');
    return response.data!
        .map((item) => ChronicleLog.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Admin: purge all data
  Future<Map<String, dynamic>> purgeAll({bool rebuild = false}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/admin/purge',
      queryParameters: {'rebuild': rebuild},
    );
    return res.data ?? const {};
  }

  // Admin: reset current player only
  Future<Map<String, dynamic>> resetCurrentPlayer() async {
    final res = await _dio.get<Map<String, dynamic>>('/admin/reset/player');
    return res.data ?? const {};
  }

  Future<List<CommandHistoryEntry>> fetchCommandHistory() async {
    final response = await _dio.get<List<dynamic>>('/commands/history');
    return response.data!
        .map(
          (item) => CommandHistoryEntry.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<CommandResponseData> submitCommand(String content) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/commands',
      data: {'content': content},
    );
    return CommandResponseData.fromJson(response.data!);
  }

  Future<MapData> fetchMap() async {
    final response = await _dio.get<Map<String, dynamic>>('/map');
    return MapData.fromJson(response.data!);
  }

  Future<LocationNode?> fetchCurrentLocation() async {
    final response = await _dio.get<Map<String, dynamic>>('/location/current');
    if (response.data == null) {
      return null;
    }
    return LocationNode.fromJson(response.data!);
  }

  Future<TravelResponseData> travelTo(String locationId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/travel',
      data: {'location_id': locationId},
    );
    return TravelResponseData.fromJson(response.data!);
  }

  Future<List<ShopData>> fetchCurrentShops() async {
    final response = await _dio.get<List<dynamic>>('/shops/current');
    return response.data!
        .map((item) => ShopData.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ShopData> fetchShop(String shopId) async {
    final response = await _dio.get<Map<String, dynamic>>('/shops/$shopId');
    return ShopData.fromJson(response.data!);
  }

  Future<AuctionHouseData?> fetchCurrentAuction() async {
    final response = await _dio.get('/auctions/current');
    if (response.data == null) {
      return null;
    }
    return AuctionHouseData.fromJson(response.data as Map<String, dynamic>);
  }

  // New: purchase from shop
  Future<PurchaseResult> purchaseFromShop({
    required String shopId,
    required String itemId,
    required int quantity,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/shops/$shopId/purchase',
      data: {'item_id': itemId, 'quantity': quantity},
    );
    return PurchaseResult.fromJson(res.data!);
  }

  // New: buyout auction lot
  Future<PurchaseResult> buyoutAuction({
    required String auctionId,
    required String lotId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auctions/$auctionId/buy',
      data: {'lot_id': lotId},
    );
    return PurchaseResult.fromJson(res.data!);
  }

  // New: fetch inventory
  Future<List<InventoryEntryData>> fetchInventory() async {
    final res = await _dio.get<List<dynamic>>('/inventory');
    return res.data!
        .map((e) => InventoryEntryData.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // New: ascension eligibility
  Future<AscensionEligibility> fetchAscensionEligibility() async {
    final res = await _dio.get<Map<String, dynamic>>('/ascension/eligibility');
    return AscensionEligibility.fromJson(res.data!);
  }

  // New: wallet
  Future<WalletData> fetchWallet() async {
    final res = await _dio.get<Map<String, dynamic>>('/wallet');
    return WalletData.fromJson(res.data!);
  }
}

class CommandHistoryEntry {
  CommandHistoryEntry({
    required this.id,
    required this.content,
    required this.feedback,
    required this.createdAt,
  });

  final String id;
  final String content;
  final String feedback;
  final DateTime createdAt;

  factory CommandHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CommandHistoryEntry(
      id: json['id'] as String,
      content: json['content'] as String,
      feedback: json['feedback'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CommandResponseData {
  CommandResponseData({
    required this.command,
    required this.log,
  });

  final CommandHistoryEntry command;
  final ChronicleLog log;

  factory CommandResponseData.fromJson(Map<String, dynamic> json) {
    final result = CommandHistoryEntry.fromJson(
      json['result'] as Map<String, dynamic>,
    );
    final log = ChronicleLog.fromJson(json['emitted_log'] as Map<String, dynamic>);
    return CommandResponseData(command: result, log: log);
  }
}

class MapData {
  MapData({required this.style, required this.nodes, required this.edges});

  final MapStyle style;
  final List<LocationNode> nodes;
  final List<MapEdge> edges;

  factory MapData.fromJson(Map<String, dynamic> json) {
    return MapData(
      style: MapStyle.fromJson(json['style'] as Map<String, dynamic>),
      nodes: (json['nodes'] as List<dynamic>)
          .map((item) => LocationNode.fromJson(item as Map<String, dynamic>))
          .toList(),
      edges: (json['edges'] as List<dynamic>)
          .map((item) => MapEdge.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MapStyle {
  MapStyle({
    required this.backgroundColor,
    required this.edgeColor,
    this.gridColor,
    this.nodeLabelColor,
    this.edgeStyles,
    this.backgroundGradient,
    this.gridVisible,
    this.nodeLabel,
    this.areas,
    this.tileGrid,
    this.tiles,
  });

  final String backgroundColor;
  final String edgeColor;
  final String? gridColor;
  final String? nodeLabelColor;
  final Map<String, dynamic>? edgeStyles;
  final List<String>? backgroundGradient;
  final bool? gridVisible;
  final Map<String, dynamic>? nodeLabel;
  final List<dynamic>? areas; // list of polygons: {points:[{x,y}..], fill_color, border_color, opacity}
  final Map<String, dynamic>? tileGrid; // {cols, rows}
  final List<MapTileStyle>? tiles;

  factory MapStyle.fromJson(Map<String, dynamic> json) {
    return MapStyle(
      backgroundColor: json['background_color'] as String,
      edgeColor: json['edge_color'] as String,
      gridColor: json['grid_color'] as String?,
      nodeLabelColor: json['node_label_color'] as String?,
      edgeStyles: json['edge_styles'] as Map<String, dynamic>?,
      backgroundGradient: (json['background_gradient'] as List<dynamic>?)?.cast<String>(),
      gridVisible: json['grid_visible'] as bool?,
      nodeLabel: json['node_label'] as Map<String, dynamic>?,
      areas: json['areas'] as List<dynamic>?,
      tileGrid: json['tile_grid'] as Map<String, dynamic>?,
      tiles: (json['tiles'] as List<dynamic>?)
          ?.map((e) => MapTileStyle.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MapTileStyle {
  MapTileStyle({required this.id, required this.x0, required this.y0, required this.x1, required this.y1, this.backgroundGradient, this.gridVisible, this.areas});
  final String id;
  final double x0;
  final double y0;
  final double x1;
  final double y1;
  final List<String>? backgroundGradient;
  final bool? gridVisible;
  final List<dynamic>? areas;

  factory MapTileStyle.fromJson(Map<String, dynamic> json) {
    final bbox = json['bbox'] as Map<String, dynamic>;
    return MapTileStyle(
      id: json['id'] as String,
      x0: (bbox['x0'] as num).toDouble(),
      y0: (bbox['y0'] as num).toDouble(),
      x1: (bbox['x1'] as num).toDouble(),
      y1: (bbox['y1'] as num).toDouble(),
      backgroundGradient: (json['background_gradient'] as List<dynamic>?)?.cast<String>(),
      gridVisible: json['grid_visible'] as bool?,
      areas: json['areas'] as List<dynamic>?,
    );
  }
}

class MapEdge {
  MapEdge({required this.from, required this.to, this.kind, this.dash, this.width, this.color, this.opacity});

  final String from;
  final String to;
  final String? kind;
  final List<double>? dash;
  final double? width;
  final String? color;
  final double? opacity;

  factory MapEdge.fromJson(Map<String, dynamic> json) {
    return MapEdge(
      from: json['from'] as String,
      to: json['to'] as String,
      kind: json['type'] as String?,
      dash: (json['dash'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
      width: (json['width'] as num?)?.toDouble(),
      color: json['color'] as String?,
      opacity: (json['opacity'] as num?)?.toDouble(),
    );
  }
}

class LocationNode {
  LocationNode({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.x,
    required this.y,
    required this.connections,
    required this.style,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final double x;
  final double y;
  final List<String> connections;
  final Map<String, dynamic> style;

  factory LocationNode.fromJson(Map<String, dynamic> json) {
    final coords = json['coords'] as Map<String, dynamic>;
    return LocationNode(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      x: (coords['x'] as num).toDouble(),
      y: (coords['y'] as num).toDouble(),
      connections: (json['connections'] as List<dynamic>).cast<String>(),
      style: (json['style'] as Map<String, dynamic>),
    );
  }
}

class TravelResponseData {
  TravelResponseData({required this.profile, required this.currentLocation});

  final PlayerProfile profile;
  final String currentLocation;

  factory TravelResponseData.fromJson(Map<String, dynamic> json) {
    return TravelResponseData(
      profile: PlayerProfile.fromJson(json['profile'] as Map<String, dynamic>),
      currentLocation: json['current_location'] as String,
    );
  }
}

class ShopItemData {
  ShopItemData({
    required this.id,
    required this.name,
    required this.category,
    required this.rarity,
    required this.price,
    required this.stock,
    required this.description,
  });

  final String id;
  final String name;
  final String category;
  final String rarity;
  final int price;
  final int stock;
  final String description;

  factory ShopItemData.fromJson(Map<String, dynamic> json) {
    return ShopItemData(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      rarity: json['rarity'] as String,
      price: json['price'] as int,
      stock: json['stock'] as int,
      description: json['description'] as String,
    );
  }
}

class ShopData {
  ShopData({
    required this.id,
    required this.locationId,
    required this.name,
    required this.description,
    required this.inventory,
  });

  final String id;
  final String locationId;
  final String name;
  final String description;
  final List<ShopItemData> inventory;

  factory ShopData.fromJson(Map<String, dynamic> json) {
    return ShopData(
      id: json['id'] as String,
      locationId: json['location_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      inventory: (json['inventory'] as List<dynamic>)
          .map((item) => ShopItemData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AuctionLotData {
  AuctionLotData({
    required this.id,
    required this.lotName,
    required this.category,
    required this.currentBid,
    required this.buyoutPrice,
    required this.timeRemainingMinutes,
    required this.seller,
    required this.description,
  });

  final String id;
  final String lotName;
  final String category;
  final int currentBid;
  final int? buyoutPrice;
  final int timeRemainingMinutes;
  final String seller;
  final String description;

  factory AuctionLotData.fromJson(Map<String, dynamic> json) {
    return AuctionLotData(
      id: json['id'] as String,
      lotName: json['lot_name'] as String,
      category: json['category'] as String,
      currentBid: json['current_bid'] as int,
      buyoutPrice: json['buyout_price'] as int?,
      timeRemainingMinutes: json['time_remaining_minutes'] as int,
      seller: json['seller'] as String,
      description: json['description'] as String,
    );
  }
}

class AuctionHouseData {
  AuctionHouseData({
    required this.id,
    required this.locationId,
    required this.name,
    required this.description,
    required this.listings,
  });

  final String id;
  final String locationId;
  final String name;
  final String description;
  final List<AuctionLotData> listings;

  factory AuctionHouseData.fromJson(Map<String, dynamic> json) {
    return AuctionHouseData(
      id: json['id'] as String,
      locationId: json['location_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      listings: (json['listings'] as List<dynamic>)
          .map((item) => AuctionLotData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class InventoryEntryData {
  InventoryEntryData({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.description,
  });

  final String id;
  final String name;
  final String category;
  final int quantity;
  final String description;

  factory InventoryEntryData.fromJson(Map<String, dynamic> json) {
    return InventoryEntryData(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      quantity: json['quantity'] as int,
      description: json['description'] as String,
    );
  }
}

class PurchaseResult {
  PurchaseResult({
    required this.spent,
    required this.profile,
    required this.inventory,
  });

  final int spent;
  final PlayerProfile profile;
  final List<InventoryEntryData> inventory;

  factory PurchaseResult.fromJson(Map<String, dynamic> json) {
    return PurchaseResult(
      spent: json['spent'] as int,
      profile: PlayerProfile.fromJson(json['profile'] as Map<String, dynamic>),
      inventory: (json['inventory'] as List<dynamic>)
          .map((e) => InventoryEntryData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AscensionEligibility {
  AscensionEligibility({required this.eligible, required this.requiredRealm});
  final bool eligible;
  final String requiredRealm;

  factory AscensionEligibility.fromJson(Map<String, dynamic> json) {
    return AscensionEligibility(
      eligible: json['eligible'] as bool,
      requiredRealm: json['required_realm'] as String,
    );
  }
}

class WalletData {
  WalletData({required this.spiritStones});
  final int spiritStones;
  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(spiritStones: json['spirit_stones'] as int);
  }
}
