import 'package:dio/dio.dart';

import '../../data/models/user_config_model.dart';

class DioClient {
  DioClient(UserConfigModel config)
    : dio = Dio(
        BaseOptions(
          baseUrl: config.baseUrl.replaceAll(RegExp(r'/$'), ''),
          headers: {
            if (config.apiKey.trim().isNotEmpty)
              'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 18),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

  final Dio dio;
}
