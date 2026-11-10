import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'netease_crypto.dart';
import 'netease_endpoints.dart';

class LyricData {
  final String? lrc;
  final String? tlyric;

  const LyricData({this.lrc, this.tlyric});
}

class NeteaseDirectClient {
  static const String uaAndroid =
      'NeteaseMusic/9.1.65 (Linux; U; Android 14; zh_CN; Pixel 8; Build/UD1A.230803.041)';
  static const String baseCookie =
      'os=android; appver=9.1.65; channel=netease; osver=14;';

  static const List<String> chinaIps = [
    '116.25.146.177',
    '183.14.132.221',
    '220.181.38.148',
    '120.232.145.185',
    '117.136.8.12',
    '223.73.1.20',
    '58.216.2.14',
  ];

  final Dio _dio;

  NeteaseDirectClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                followRedirects: true,
              ),
            );

  String _getRandomIp(String? realIp) {
    if (realIp != null && realIp.trim().isNotEmpty) return realIp.trim();
    return chinaIps[Random().nextInt(chinaIps.length)];
  }

  Future<String> postEapi({
    required String url,
    required String apiPath,
    required String jsonPayload,
    String? realIp,
  }) async {
    final encryptedParams = NeteaseCrypto.eapi(apiPath, jsonPayload);
    final ip = _getRandomIp(realIp);

    final response = await _dio.post(
      url,
      data: {'params': encryptedParams},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
        headers: {
          'User-Agent': uaAndroid,
          'Cookie': baseCookie,
          'X-Real-IP': ip,
          'X-Forwarded-For': ip,
          'Referer': NeteaseEndpoints.hostDefault,
        },
      ),
    );

    final rawBody = response.data?.toString().trim() ?? '';
    if (rawBody.length >= 32 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(rawBody)) {
      return NeteaseCrypto.decryptEapiResponse(rawBody) ?? rawBody;
    }
    return rawBody;
  }

  Future<LyricData?> getLyric(int musicId, {String? realIp}) async {
    if (musicId <= 0) return null;

    final payload = json.encode({
      'id': musicId,
      'lv': -1,
      'tv': -1,
      'kv': -1,
    });

    try {
      final resBody = await postEapi(
        url: NeteaseEndpoints.urlEapiSongLyric,
        apiPath: NeteaseEndpoints.pathEapiSongLyric,
        jsonPayload: payload,
        realIp: realIp,
      );

      final map = json.decode(resBody) as Map<String, dynamic>;
      final lrc = (map['lrc'] is Map) ? map['lrc']['lyric']?.toString() : null;
      final tlyric = (map['tlyric'] is Map) ? map['tlyric']['lyric']?.toString() : null;

      return LyricData(lrc: lrc, tlyric: tlyric);
    } catch (_) {
      return null;
    }
  }

  Future<int?> searchSongId({
    required String name,
    required String artist,
    String? realIp,
  }) async {
    final keyword = '$name $artist'.trim();
    if (keyword.isEmpty) return null;

    final header = {
      'os': 'android',
      'appver': '9.1.65',
      'requestId': '${DateTime.now().millisecondsSinceEpoch}_0001',
    };

    final payload = json.encode({
      's': keyword,
      'type': 1,
      'limit': 5,
      'offset': 0,
      'total': true,
      'header': header,
    });

    try {
      final resBody = await postEapi(
        url: NeteaseEndpoints.urlEapiCloudsearch,
        apiPath: NeteaseEndpoints.pathEapiCloudsearch,
        jsonPayload: payload,
        realIp: realIp,
      );

      final map = json.decode(resBody) as Map<String, dynamic>;
      final result = map['result'] as Map<String, dynamic>?;
      final songs = result?['songs'] as List<dynamic>?;
      if (songs != null && songs.isNotEmpty) {
        final first = songs[0] as Map<String, dynamic>;
        return (first['id'] as num?)?.toInt();
      }
    } catch (_) {
      // Ignore
    }
    return null;
  }
}
