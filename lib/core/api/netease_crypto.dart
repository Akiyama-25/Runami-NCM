import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class WeapiForm {
  final String params;
  final String encSecKey;

  const WeapiForm({required this.params, required this.encSecKey});
}

class NeteaseCrypto {
  static const String presetKey = '0CoJUm6Qyw8W8jud';
  static const String iv = '0102030405060708';
  static const String rsaPublicExponent = '010001';
  static const String rsaModulus =
      'e0b509f6259df8642dbc35662901477df22677ec152b5ff68ace615bb7b725152b3ab17a876aea8a5aa76d2e417629ec4ee341f56135fccf695280104e0312ecbda92557c93870114af6c9d05c4f7f0c3685b7a46bee255932575cce10b424d813cfe4875d3e82047b97ddef52741d546b8e289dc6935b3ece0462db0a22b8e7';
  static const String eapiKey = 'e82ckenh8dichen8';
  static const String secretChars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  static final Random _random = Random();

  /// NetEase WeAPI signature generator
  static WeapiForm weapi(String jsonStr, {String? customSecret}) {
    final secret = customSecret ??
        List.generate(16, (_) => secretChars[_random.nextInt(secretChars.length)]).join();

    final first = _aesCbcBase64(jsonStr, presetKey);
    final params = _aesCbcBase64(first, secret);

    final reversedSecret = utf8.encode(secret.split('').reversed.join());
    final secretBigInt = _bytesToBigInt(Uint8List.fromList(reversedSecret));
    final expBigInt = BigInt.parse(rsaPublicExponent, radix: 16);
    final modBigInt = BigInt.parse(rsaModulus, radix: 16);

    final encSecKeyBigInt = secretBigInt.modPow(expBigInt, modBigInt);
    final encSecKey = encSecKeyBigInt.toRadixString(16).padLeft(256, '0');

    return WeapiForm(params: params, encSecKey: encSecKey);
  }

  /// NetEase EAPI request encryption
  static String eapi(String apiPath, String jsonStr) {
    final digest = _md5('nobody${apiPath}use${jsonStr}md5forencrypt');
    final plaintext = '$apiPath-36cd479b6b5-$jsonStr-36cd479b6b5-$digest';
    return _aesEcbHex(plaintext, eapiKey).toUpperCase();
  }

  /// Decrypt EAPI hex ciphertext response
  static String? decryptEapiResponse(String ciphertext) {
    try {
      final clean = ciphertext.trim();
      if (clean.length % 2 != 0) return null;

      final bytes = Uint8List(clean.length ~/ 2);
      for (var i = 0; i < bytes.length; i++) {
        bytes[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
      }

      final keyBytes = Uint8List.fromList(utf8.encode(eapiKey));
      final cipher = PaddedBlockCipherImpl(
        PKCS7Padding(),
        ECBBlockCipher(AESEngine()),
      )..init(false, PaddedBlockCipherParameters(KeyParameter(keyBytes), null));

      final decrypted = cipher.process(bytes);
      return utf8.decode(decrypted);
    } catch (_) {
      return null;
    }
  }

  static String _aesCbcBase64(String value, String key) {
    final keyBytes = Uint8List.fromList(utf8.encode(key));
    final ivBytes = Uint8List.fromList(utf8.encode(iv));
    final dataBytes = Uint8List.fromList(utf8.encode(value));

    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    )..init(true, PaddedBlockCipherParameters(ParametersWithIV(KeyParameter(keyBytes), ivBytes), null));

    final encrypted = cipher.process(dataBytes);
    return base64.encode(encrypted);
  }

  static String _aesEcbHex(String value, String key) {
    final keyBytes = Uint8List.fromList(utf8.encode(key));
    final dataBytes = Uint8List.fromList(utf8.encode(value));

    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      ECBBlockCipher(AESEngine()),
    )..init(true, PaddedBlockCipherParameters(KeyParameter(keyBytes), null));

    final encrypted = cipher.process(dataBytes);
    return encrypted.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _md5(String value) {
    final digest = MD5Digest();
    final bytes = Uint8List.fromList(utf8.encode(value));
    final out = digest.process(bytes);
    return out.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (var i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }
}
