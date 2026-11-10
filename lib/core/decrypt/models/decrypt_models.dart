import 'dart:io';
import 'dart:typed_data';

class NcmMetadata {
  final int musicId;
  final String musicName;
  final List<String> artists;
  final String album;
  final String albumPic;
  final String format;
  final int duration;

  const NcmMetadata({
    this.musicId = 0,
    this.musicName = 'Unknown',
    this.artists = const [],
    this.album = '',
    this.albumPic = '',
    this.format = '',
    this.duration = 0,
  });

  Map<String, dynamic> toJson() => {
    'musicId': musicId,
    'musicName': musicName,
    'artists': artists,
    'album': album,
    'albumPic': albumPic,
    'format': format,
    'duration': duration,
  };

  factory NcmMetadata.fromJson(Map<String, dynamic> json) {
    final artistsList = <String>[];
    if (json['artist'] is List) {
      for (final a in json['artist']) {
        if (a is List && a.isNotEmpty) {
          artistsList.add(a[0].toString());
        } else if (a is Map && a.containsKey('name')) {
          artistsList.add(a['name'].toString());
        } else if (a is String) {
          artistsList.add(a);
        }
      }
    } else if (json['artists'] is List) {
      for (final a in json['artists']) {
        if (a is String) artistsList.add(a);
      }
    }

    return NcmMetadata(
      musicId: (json['musicId'] is num) ? (json['musicId'] as num).toInt() : 0,
      musicName: json['musicName']?.toString() ?? 'Unknown',
      artists: artistsList,
      album: json['album']?.toString() ?? '',
      albumPic: json['albumPic']?.toString() ?? '',
      format: json['format']?.toString() ?? '',
      duration: (json['duration'] is num) ? (json['duration'] as num).toInt() : 0,
    );
  }
}

enum DecryptState {
  IDLE,
  PARSING,
  DECRYPTING,
  SEARCHING_LYRIC,
  WRITING_META,
  COMPLETED,
  COMPLETED_NO_LYRIC,
  FAILED,
}

class DecryptProgress {
  final DecryptState state;
  final double progress; // 0.0 .. 1.0
  final int bytesProcessed;
  final int totalBytes;
  final String? errorMessage;
  final String? outputPath;

  const DecryptProgress({
    this.state = DecryptState.IDLE,
    this.progress = 0.0,
    this.bytesProcessed = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.outputPath,
  });
}

class DecryptResult {
  final Uint8List? audioData;
  final File? tempAudioFile;
  final NcmMetadata metadata;
  final String mimeType;
  final String extension;
  final String? lyric;

  const DecryptResult({
    this.audioData,
    this.tempAudioFile,
    required this.metadata,
    required this.mimeType,
    required this.extension,
    this.lyric,
  });

  bool get isFileBased => tempAudioFile != null && audioData == null;
  Uint8List? getAudioBytes() => audioData;
}

class FileItem {
  final int id;
  final String path;
  final String name;
  final int size;
  final DecryptState state;
  final double progress;
  final DecryptResult? result;
  final String? error;
  final String? outputPath;

  const FileItem({
    required this.id,
    required this.path,
    required this.name,
    required this.size,
    this.state = DecryptState.IDLE,
    this.progress = 0.0,
    this.result,
    this.error,
    this.outputPath,
  });

  FileItem copyWith({
    int? id,
    String? path,
    String? name,
    int? size,
    DecryptState? state,
    double? progress,
    DecryptResult? result,
    String? error,
    String? outputPath,
  }) {
    return FileItem(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      size: size ?? this.size,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      error: error ?? this.error,
      outputPath: outputPath ?? this.outputPath,
    );
  }
}
