import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.wsChroniclesUrl});

  final String apiBaseUrl;
  final String wsChroniclesUrl;

  factory AppConfig.fromEnvironment() {
    const envBase = String.fromEnvironment('API_BASE_URL');
    final apiBase = envBase.isNotEmpty ? envBase : _defaultApiBase();
    const wsOverride = String.fromEnvironment('WS_CHRONICLES_URL');
    return AppConfig(
      apiBaseUrl: apiBase,
      wsChroniclesUrl:
          wsOverride.isNotEmpty ? wsOverride : _deriveChronicleWs(apiBase),
    );
  }

  static String _defaultApiBase() {
    if (kIsWeb) {
      final current = Uri.base;
      final host = current.host.isNotEmpty ? current.host : '101.237.129.72';
      final scheme = current.scheme == 'https' ? 'https' : 'http';
      // Web 环境默认复用当前主机，便于在局域网或多终端调试时直连本地后端
      return Uri(scheme: scheme, host: host, port: 8000).toString();
    }
    return 'http://101.237.129.72:8000';
  }


  static String _deriveChronicleWs(String apiBaseUrl) {
    final apiUri = Uri.parse(apiBaseUrl);
    final scheme = apiUri.scheme == 'https' ? 'wss' : 'ws';
    final wsUri = apiUri.replace(scheme: scheme, path: '/ws/chronicles');
    return wsUri.toString();
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});
