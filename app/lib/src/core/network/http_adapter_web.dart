import 'package:dio/dio.dart';
import 'package:dio/browser.dart';

// Web 平台：启用 withCredentials，保证 Cookie（player_id）随请求发送。
Dio configureDioForPlatform(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter()..withCredentials = true;
  return dio;
}

