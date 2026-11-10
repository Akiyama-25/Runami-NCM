import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'models/decrypt_models.dart';

class DecryptedPayload {
  final Uint8List audioBytes;
  final NcmMetadata metadata;
  final Uint8List? embeddedCover;
  final String format; // 'flac' or 'mp3'

  const DecryptedPayload({
    required this.audioBytes,
    required this.metadata,
    this.embeddedCover,
    required this.format,
  });
}

class NcmDecryptWorker {
  static final Uint8List _coreKey = Uint8List.fromList([
    0x68, 0x7A, 0x48, 0x52, 0x41, 0x6D, 0x73, 0x6F,
    0x35, 0x6B, 0x49, 0x6E, 0x62, 0x61, 0x78, 0x57,
  ]);

  static final Uint8List _metaKey = Uint8List.fromList([
    0x23, 0x31, 0x34, 0x6C, 0x6A, 0x6B, 0x5F, 0x21,
    0x5C, 0x5D, 0x26, 0x30, 0x55, 0x3C, 0x27, 0x28,
  ]);

  /// Executes zero-copy NCM stream parsing and RC4 decryption in an isolated thread
  static Future<DecryptedPayload> parseAndDecrypt({
    required String filePath,
    SendPort? progressPort,
  }) async {
    return await Isolate.run(() async {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('NCM file not found', filePath);
      }

      final raf = await file.open(mode: FileMode.read);
      try {
        progressPort?.send({
          'state': DecryptState.PARSING.name,
          'progress': 0.0,
        });

        // 1. Check Magic Header ("CTENFDAM")
        final magic = await raf.read(8);
        if (magic.length < 8 || utf8.decode(magic, allowMalformed: true) != 'CTENFDAM') {
          throw const FormatException('Invalid NCM file header: missing CTENFDAM magic');
        }
        await raf.setPosition(await raf.position() + 2); // 2 bytes gap

        // 2. Decrypt RC4 Key Box Seed
        final keyLenBytes = await raf.read(4);
        final keyLen = _readUint32LE(keyLenBytes);
        final rawKeyData = await raf.read(keyLen);
        for (var i = 0; i < rawKeyData.length; i++) {
          rawKeyData[i] ^= 0x64;
        }
        final decryptedKey = _aesEcbDecrypt(rawKeyData, _coreKey);
        // Skip 17 bytes: "neteasecloudmusic"
        final rc4Seed = decryptedKey.length > 17
            ? decryptedKey.sublist(17)
            : decryptedKey;

        // 3. Parse Metadata JSON
        final metaLenBytes = await raf.read(4);
        final metaLen = _readUint32LE(metaLenBytes);
        NcmMetadata metadata = const NcmMetadata();

        if (metaLen > 0) {
          final rawMetaData = await raf.read(metaLen);
          for (var i = 0; i < rawMetaData.length; i++) {
            rawMetaData[i] ^= 0x63;
          }
          try {
            // Skip prefix "163 key(Don't modify):" (22 bytes)
            if (rawMetaData.length > 22) {
              final b64Str = ascii.decode(rawMetaData.sublist(22));
              final b64Bytes = base64.decode(b64Str);
              final decryptedMeta = _aesEcbDecrypt(b64Bytes, _metaKey);
              // Skip prefix "music:" (6 bytes)
              if (decryptedMeta.length > 6) {
                final jsonStr = utf8.decode(decryptedMeta.sublist(6));
                final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
                metadata = NcmMetadata.fromJson(jsonMap);
              }
            }
          } catch (e) {
            // Keep fallback metadata if parsing failed
          }
        }

        // 4. Skip CRC (4 bytes) + Gap (5 bytes) = 9 bytes
        await raf.setPosition(await raf.position() + 9);

        // 5. Embedded Cover Art
        final imgLenBytes = await raf.read(4);
        final imgLen = _readUint32LE(imgLenBytes);
        Uint8List? embeddedCover;
        if (imgLen > 0) {
          embeddedCover = await raf.read(imgLen);
        }

        // 6. RC4 Stream Decryption
        final sBox = _buildRc4KeyBox(rc4Seed);
        final audioStartPos = await raf.position();
        final fileLength = await raf.length();
        final totalAudioBytes = fileLength - audioStartPos;

        if (totalAudioBytes <= 0) {
          throw const FormatException('Empty audio payload in NCM file');
        }

        const chunkSize = 32 * 1024; // 32KB chunks
        final audioBuffer = BytesBuilder(copy: false);
        var processed = 0;
        var lastReportedPercent = -1;

        progressPort?.send({
          'state': DecryptState.DECRYPTING.name,
          'progress': 0.0,
          'bytesProcessed': 0,
          'totalBytes': totalAudioBytes,
        });

        while (processed < totalAudioBytes) {
          final chunk = await raf.read(chunkSize);
          if (chunk.isEmpty) break;

          for (var i = 0; i < chunk.length; i++) {
            final j = (i + 1) & 0xFF;
            final k = (sBox[j] + sBox[(sBox[j] + j) & 0xFF]) & 0xFF;
            chunk[i] ^= sBox[k];
          }

          audioBuffer.add(chunk);
          processed += chunk.length;

          final percent = ((processed * 100) ~/ totalAudioBytes).clamp(0, 100);
          if (percent - lastReportedPercent >= 2 || processed == totalAudioBytes) {
            lastReportedPercent = percent;
            progressPort?.send({
              'state': DecryptState.DECRYPTING.name,
              'progress': percent / 100.0,
              'bytesProcessed': processed,
              'totalBytes': totalAudioBytes,
            });
          }
        }

        final audioBytes = audioBuffer.takeBytes();
        final isFlac = audioBytes.length >= 4 &&
            audioBytes[0] == 0x66 && // 'f'
            audioBytes[1] == 0x4C && // 'L'
            audioBytes[2] == 0x61 && // 'a'
            audioBytes[3] == 0x43;   // 'C'
        final format = isFlac ? 'flac' : 'mp3';

        return DecryptedPayload(
          audioBytes: audioBytes,
          metadata: metadata,
          embeddedCover: embeddedCover,
          format: format,
        );
      } finally {
        await raf.close();
      }
    });
  }

  static Uint8List _buildRc4KeyBox(Uint8List key) {
    final box = Uint8List(256);
    for (var i = 0; i < 256; i++) {
      box[i] = i;
    }
    var j = 0;
    for (var i = 0; i < 256; i++) {
      j = (j + box[i] + key[i % key.length]) & 0xFF;
      final tmp = box[i];
      box[i] = box[j];
      box[j] = tmp;
    }
    return box;
  }

  static Uint8List _aesEcbDecrypt(Uint8List encrypted, Uint8List key) {
    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      ECBBlockCipher(AESEngine()),
    )..init(false, PaddedBlockCipherParameters(KeyParameter(key), null));
    return cipher.process(encrypted);
  }

  static int _readUint32LE(Uint8List bytes) {
    if (bytes.length < 4) return 0;
    return ByteData.sublistView(bytes).getUint32(0, Endian.little);
  }
}
