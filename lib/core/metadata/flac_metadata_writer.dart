import 'dart:convert';
import 'dart:typed_data';
import '../decrypt/models/decrypt_models.dart';
import 'metadata_writer.dart';

class FlacMetadataWriter implements MetadataWriter {
  @override
  Future<Uint8List> write(
    Uint8List audioData,
    NcmMetadata metadata, {
    String? lyric,
    Uint8List? coverBytes,
  }) async {
    if (audioData.length < 42) return audioData; // Too small for valid FLAC

    // 1. Locate end of mandatory STREAMINFO block
    final streaminfoHeader = audioData[4];
    final isLastBlock = (streaminfoHeader & 0x80) != 0;
    final blockSize = ((audioData[5] & 0xFF) << 16) |
        ((audioData[6] & 0xFF) << 8) |
        (audioData[7] & 0xFF);
    final streaminfoEnd = 4 + 4 + blockSize;

    if (streaminfoEnd > audioData.length) return audioData;

    // 2. Build Vorbis Comment block
    final vorbisComment = _buildVorbisComment(metadata, lyric);

    // 3. Build Picture block (if cover available)
    final hasPicture = coverBytes != null && coverBytes.isNotEmpty;
    Uint8List pictureBlock = Uint8List(0);
    if (hasPicture) {
      final picturePayload = _buildPictureBlock(coverBytes!);
      final pictureHeader = _buildBlockHeader(6, true, picturePayload.length);
      final picBuilder = BytesBuilder(copy: false);
      picBuilder.add(pictureHeader);
      picBuilder.add(picturePayload);
      pictureBlock = picBuilder.takeBytes();
    }

    // Vorbis Comment block header (type 4)
    final vorbisHeader = _buildBlockHeader(4, !hasPicture, vorbisComment.length);

    // 4. Adjust STREAMINFO header if it was previously marked as last
    var adjustedStreaminfoHeader = streaminfoHeader;
    if (isLastBlock && (vorbisComment.isNotEmpty || pictureBlock.isNotEmpty)) {
      adjustedStreaminfoHeader = streaminfoHeader & 0x7F; // clear isLast bit
    }

    // 5. Reconstruct FLAC: "fLaC" + adjusted STREAMINFO + Vorbis + Picture + rest of stream
    final out = BytesBuilder(copy: false);
    out.add(Uint8List.sublistView(audioData, 0, 4)); // "fLaC"
    out.addByte(adjustedStreaminfoHeader);
    out.add(Uint8List.sublistView(audioData, 5, streaminfoEnd));
    if (vorbisComment.isNotEmpty) {
      out.add(vorbisHeader);
      out.add(vorbisComment);
    }
    if (pictureBlock.isNotEmpty) {
      out.add(pictureBlock);
    }
    out.add(Uint8List.sublistView(audioData, streaminfoEnd));
    return out.takeBytes();
  }

  Uint8List _buildBlockHeader(int type, bool isLast, int size) {
    final headerByte = (type & 0x7F) | (isLast ? 0x80 : 0x00);
    final header = Uint8List(4);
    header[0] = headerByte;
    header[1] = (size >> 16) & 0xFF;
    header[2] = (size >> 8) & 0xFF;
    header[3] = size & 0xFF;
    return header;
  }

  Uint8List _buildVorbisComment(NcmMetadata meta, String? lyric) {
    const vendor = 'NCM Converter';
    final vendorBytes = utf8.encode(vendor);

    final comments = <String>[];
    if (meta.musicName.isNotEmpty && meta.musicName != 'Unknown') {
      comments.add('TITLE=${meta.musicName}');
    }
    if (meta.artists.isNotEmpty) {
      comments.add('ARTIST=${meta.artists.join('/')}');
    }
    if (meta.album.isNotEmpty) {
      comments.add('ALBUM=${meta.album}');
    }
    if (lyric != null && lyric.trim().isNotEmpty) {
      comments.add('LYRICS=${lyric.trim()}');
    }

    final out = BytesBuilder(copy: false);
    // Vendor length (uint32 LE) + vendor bytes
    _writeInt32LE(out, vendorBytes.length);
    out.add(vendorBytes);

    // Comment count (uint32 LE)
    _writeInt32LE(out, comments.length);
    for (final comment in comments) {
      final commentBytes = utf8.encode(comment);
      _writeInt32LE(out, commentBytes.length);
      out.add(commentBytes);
    }

    return out.takeBytes();
  }

  Uint8List _buildPictureBlock(Uint8List cover) {
    final isPng = cover.length > 8 &&
        cover[0] == 0x89 &&
        cover[1] == 0x50 &&
        cover[2] == 0x4E &&
        cover[3] == 0x47;
    final mime = isPng ? ascii.encode('image/png') : ascii.encode('image/jpeg');

    final out = BytesBuilder(copy: false);
    // Picture type (uint32 BE): 3 = front cover
    _writeInt32BE(out, 3);
    // MIME type length + MIME string
    _writeInt32BE(out, mime.length);
    out.add(mime);
    // Description length (0)
    _writeInt32BE(out, 0);
    // Width (0 = unknown)
    _writeInt32BE(out, 0);
    // Height (0 = unknown)
    _writeInt32BE(out, 0);
    // Color depth (24 bits)
    _writeInt32BE(out, 24);
    // Colors used (0)
    _writeInt32BE(out, 0);
    // Picture data length + data
    _writeInt32BE(out, cover.length);
    out.add(cover);

    return out.takeBytes();
  }

  void _writeInt32BE(BytesBuilder out, int value) {
    final b = Uint8List(4);
    ByteData.sublistView(b).setUint32(0, value, Endian.big);
    out.add(b);
  }

  void _writeInt32LE(BytesBuilder out, int value) {
    final b = Uint8List(4);
    ByteData.sublistView(b).setUint32(0, value, Endian.little);
    out.add(b);
  }
}
