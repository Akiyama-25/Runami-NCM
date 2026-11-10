import 'dart:typed_data';
import 'package:dio/dio.dart';

class CoverFetcher {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.bytes,
    ),
  );

  static Future<Uint8List?> fetch(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) return null;

    try {
      final response = await _dio.get<List<int>>(cleanUrl);
      if (response.data != null && response.data!.isNotEmpty) {
        return Uint8List.fromList(response.data!);
      }
    } catch (_) {
      // Failed to download cover
    }
    return null;
  }
}
