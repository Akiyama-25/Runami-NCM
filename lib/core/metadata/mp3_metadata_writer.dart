import 'dart:convert';
import 'dart:typed_data';
import '../decrypt/models/decrypt_models.dart';
import 'metadata_writer.dart';

class Mp3MetadataWriter implements MetadataWriter {
  @override
  Future<Uint8List> write(
    Uint8List audioData,
    NcmMetadata metadata, {
    String? lyric,
    Uint8List? coverBytes,
  }) async {
    // 1. Strip existing ID3v2 tag if present
    Uint8List rawAudio = audioData;
    if (audioData.length > 10 &&
        audioData[0] == 0x49 && // 'I'
        audioData[1] == 0x44 && // 'D'
        audioData[2] == 0x33) { // '3'
      final tagSize = _readSynchSafeInt(audioData, 6);
      if (10 + tagSize < audioData.length) {
        rawAudio = Uint8List.sublistView(audioData, 10 + tagSize);
      }
    }

    // 2. Build ID3v2.3 tag
    final tag = _buildId3v2Tag(metadata, coverBytes, lyric);

    // 3. Concatenate tag + rawAudio
    final builder = BytesBuilder(copy: false);
    builder.add(tag);
    builder.add(rawAudio);
    return builder.takeBytes();
  }

  Uint8List _buildId3v2Tag(NcmMetadata meta, Uint8List? cover, String? lyric) {
    final frameBuilder = BytesBuilder(copy: false);

    // TIT2 — Title
    if (meta.musicName.isNotEmpty) {
      _writeTextFrame(frameBuilder, 'TIT2', meta.musicName);
    }

    // TPE1 — Artist
    if (meta.artists.isNotEmpty) {
      final artist = meta.artists.join('/');
      if (artist.isNotEmpty) {
        _writeTextFrame(frameBuilder, 'TPE1', artist);
      }
    }

    // TALB — Album
    if (meta.album.isNotEmpty) {
      _writeTextFrame(frameBuilder, 'TALB', meta.album);
    }

    // APIC — Attached Picture
    if (cover != null && cover.isNotEmpty) {
      _writeApicFrame(frameBuilder, cover);
    }

    // USLT — Unsynchronized Lyrics
    if (lyric != null && lyric.trim().isNotEmpty) {
      _writeUsltFrame(frameBuilder, lyric.trim());
    }

    final frameBytes = frameBuilder.takeBytes();

    final header = Uint8List(10);
    header[0] = 0x49; // 'I'
    header[1] = 0x44; // 'D'
    header[2] = 0x33; // '3'
    header[3] = 0x03; // version 2.3
    header[4] = 0x00; // revision
    header[5] = 0x00; // flags
    _writeSynchSafeInt(header, 6, frameBytes.length);

    final out = BytesBuilder(copy: false);
    out.add(header);
    out.add(frameBytes);
    return out.takeBytes();
  }

  void _writeTextFrame(BytesBuilder out, String id, String text) {
    const encoding = 0x03; // UTF-8
    final bom = Uint8List.fromList([0xEF, 0xBB, 0xBF]);
    final textBytes = utf8.encode(text);

    final payload = BytesBuilder(copy: false);
    payload.addByte(encoding);
    payload.add(bom);
    payload.add(textBytes);
    final payloadBytes = payload.takeBytes();

    out.add(ascii.encode(id));
    _writeInt32BE(out, payloadBytes.length);
    out.add(Uint8List(2)); // flags 0x0000
    out.add(payloadBytes);
  }

  void _writeApicFrame(BytesBuilder out, Uint8List cover) {
    const encoding = 0x00; // ISO-8859-1 for MIME
    final isPng = cover.length > 8 &&
        cover[0] == 0x89 &&
        cover[1] == 0x50 &&
        cover[2] == 0x4E &&
        cover[3] == 0x47;
    final mime = isPng ? ascii.encode('image/png') : ascii.encode('image/jpeg');

    final payload = BytesBuilder(copy: false);
    payload.addByte(encoding);
    payload.add(mime);
    payload.addByte(0); // null terminator for MIME
    payload.addByte(0x03); // Picture type: front cover
    payload.addByte(encoding);
    payload.addByte(0); // null terminator for empty description
    payload.add(cover);
    final payloadBytes = payload.takeBytes();

    out.add(ascii.encode('APIC'));
    _writeInt32BE(out, payloadBytes.length);
    out.add(Uint8List(2)); // flags
    out.add(payloadBytes);
  }

  void _writeUsltFrame(BytesBuilder out, String lyric) {
    const encoding = 0x03; // UTF-8
    final lang = ascii.encode('chi');
    final desc = Uint8List(1); // empty string null terminator
    final lyricBytes = utf8.encode(lyric);

    final payload = BytesBuilder(copy: false);
    payload.addByte(encoding);
    payload.add(lang);
    payload.add(desc);
    payload.add(lyricBytes);
    final payloadBytes = payload.takeBytes();

    out.add(ascii.encode('USLT'));
    _writeInt32BE(out, payloadBytes.length);
    out.add(Uint8List(2)); // flags
    out.add(payloadBytes);
  }

  void _writeInt32BE(BytesBuilder out, int value) {
    final b = Uint8List(4);
    ByteData.sublistView(b).setUint32(0, value, Endian.big);
    out.add(b);
  }

  void _writeSynchSafeInt(Uint8List buf, int offset, int value) {
    buf[offset] = (value >> 21) & 0x7F;
    buf[offset + 1] = (value >> 14) & 0x7F;
    buf[offset + 2] = (value >> 7) & 0x7F;
    buf[offset + 3] = value & 0x7F;
  }

  int _readSynchSafeInt(Uint8List buf, int offset) {
    return ((buf[offset] & 0x7F) << 21) |
        ((buf[offset + 1] & 0x7F) << 14) |
        ((buf[offset + 2] & 0x7F) << 7) |
        (buf[offset + 3] & 0x7F);
  }
}
