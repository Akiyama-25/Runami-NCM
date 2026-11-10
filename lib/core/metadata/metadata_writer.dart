import 'dart:typed_data';
import '../decrypt/models/decrypt_models.dart';

abstract class MetadataWriter {
  Future<Uint8List> write(
    Uint8List audioData,
    NcmMetadata metadata, {
    String? lyric,
    Uint8List? coverBytes,
  });
}
