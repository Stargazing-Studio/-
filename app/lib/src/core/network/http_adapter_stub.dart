import 'package:dio/dio.dart';

// 默认什么都不做（非 Web 平台或无法识别的平台）。
Dio configureDioForPlatform(Dio dio) => dio;

