import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../core/api/cover_fetcher.dart';
import '../core/decrypt/models/decrypt_models.dart';
import '../core/decrypt/ncm_decrypt_worker.dart';
import '../core/lyric/lyric_matcher.dart';
import '../core/metadata/flac_metadata_writer.dart';
import '../core/metadata/mp3_metadata_writer.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/app_prefs.dart';
import '../core/utils/file_utils.dart';

class ConvertQueueState {
  final List<FileItem> items;
  final bool isProcessing;
  final String? bannerMessage;

  const ConvertQueueState({
    this.items = const [],
    this.isProcessing = false,
    this.bannerMessage,
  });

  ConvertQueueState copyWith({
    List<FileItem>? items,
    bool? isProcessing,
    String? bannerMessage,
  }) {
    return ConvertQueueState(
      items: items ?? this.items,
      isProcessing: isProcessing ?? this.isProcessing,
      bannerMessage: bannerMessage,
    );
  }
}

class ConvertQueueNotifier extends StateNotifier<ConvertQueueState> {
  static const int maxConcurrent = 2;
  int _nextId = 1;
  int _activeWorkers = 0;
  final List<int> _pendingQueue = [];

  final Mp3MetadataWriter _mp3Writer = Mp3MetadataWriter();
  final FlacMetadataWriter _flacWriter = FlacMetadataWriter();
  final LyricMatcher _lyricMatcher = LyricMatcher();

  ConvertQueueNotifier() : super(const ConvertQueueState());

  void addFiles(List<String> paths) {
    final validPaths = paths.where((p) => p.toLowerCase().endsWith('.ncm')).toList();
    if (validPaths.isEmpty) {
      state = state.copyWith(bannerMessage: '未发现有效的 .ncm 文件');
      return;
    }

    final toAdd = validPaths.take(50).toList();
    final newItems = <FileItem>[];

    for (final path in toAdd) {
      final file = File(path);
      final size = file.existsSync() ? file.lengthSync() : 0;
      final name = p.basename(path);
      newItems.add(FileItem(
        id: _nextId++,
        path: path,
        name: name,
        size: size,
        state: DecryptState.IDLE,
      ));
    }

    final updated = [...state.items, ...newItems];
    state = state.copyWith(items: updated, bannerMessage: null);
    AppLogger.i('ConvertQueue', 'Added ${newItems.length} files to queue');
  }

  void removeFile(int id) {
    _pendingQueue.remove(id);
    final updated = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(items: updated);
  }

  void clearAll() {
    _pendingQueue.clear();
    state = state.copyWith(items: const [], isProcessing: false);
    AppLogger.i('ConvertQueue', 'Cleared all items in queue');
  }

  void convertAll() {
    final pending = state.items
        .where((i) => i.state == DecryptState.IDLE || i.state == DecryptState.FAILED)
        .map((i) => i.id)
        .toList();

    for (final id in pending) {
      if (!_pendingQueue.contains(id)) {
        _pendingQueue.add(id);
      }
    }

    state = state.copyWith(isProcessing: true);
    _drainQueue();
  }

  void convertSingle(int id) {
    if (!_pendingQueue.contains(id)) {
      _pendingQueue.add(id);
    }
    state = state.copyWith(isProcessing: true);
    _drainQueue();
  }

  void _drainQueue() {
    while (_activeWorkers < maxConcurrent && _pendingQueue.isNotEmpty) {
      final id = _pendingQueue.removeAt(0);
      _activeWorkers++;
      _processTask(id).whenComplete(() {
        _activeWorkers--;
        if (_pendingQueue.isNotEmpty) {
          _drainQueue();
        } else if (_activeWorkers == 0) {
          state = state.copyWith(isProcessing: false);
        }
      });
    }
  }

  Future<void> _processTask(int id) async {
    final index = state.items.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final item = state.items[index];
    _updateItem(id, (it) => it.copyWith(state: DecryptState.PARSING, progress: 0.0));

    final receivePort = ReceivePort();
    final streamSub = receivePort.listen((message) {
      if (message is Map) {
        final stateName = message['state'] as String?;
        final progress = (message['progress'] as num?)?.toDouble() ?? 0.0;
        final stateEnum = DecryptState.values.firstWhere(
          (e) => e.name == stateName,
          orElse: () => DecryptState.DECRYPTING,
        );
        _updateItem(id, (it) => it.copyWith(state: stateEnum, progress: progress));
      }
    });

    try {
      AppLogger.i('ConvertQueue', 'Starting decrypt task: ${item.name}');
      final payload = await NcmDecryptWorker.parseAndDecrypt(
        filePath: item.path,
        progressPort: receivePort.sendPort,
      );

      // Search and match lyrics
      _updateItem(id, (it) => it.copyWith(state: DecryptState.SEARCHING_LYRIC));
      String? lyric;
      try {
        lyric = await _lyricMatcher.matchLyric(payload.metadata);
      } catch (e) {
        AppLogger.w('ConvertQueue', 'Lyric search failed: $e');
      }

      // Cover Art
      Uint8List? coverBytes = payload.embeddedCover;
      if (coverBytes == null && AppPrefs.enableCover && payload.metadata.albumPic.isNotEmpty) {
        try {
          coverBytes = await CoverFetcher.fetch(payload.metadata.albumPic);
        } catch (_) {}
      }

      // Write Tags
      _updateItem(id, (it) => it.copyWith(state: DecryptState.WRITING_META));
      Uint8List taggedAudio;
      if (payload.format == 'flac') {
        taggedAudio = await _flacWriter.write(
          payload.audioBytes,
          payload.metadata,
          lyric: lyric,
          coverBytes: coverBytes,
        );
      } else {
        taggedAudio = await _mp3Writer.write(
          payload.audioBytes,
          payload.metadata,
          lyric: lyric,
          coverBytes: coverBytes,
        );
      }

      final result = DecryptResult(
        audioData: taggedAudio,
        metadata: payload.metadata,
        mimeType: payload.format == 'flac' ? 'audio/flac' : 'audio/mpeg',
        extension: payload.format,
        lyric: lyric,
      );

      String? outPath;
      if (AppPrefs.autoSave) {
        outPath = await _saveAudioToFile(item.name, payload.format, taggedAudio);
      }

      _updateItem(
        id,
        (it) => it.copyWith(
          state: (lyric != null && lyric.isNotEmpty)
              ? DecryptState.COMPLETED
              : DecryptState.COMPLETED_NO_LYRIC,
          progress: 1.0,
          result: result,
          outputPath: outPath,
        ),
      );
      AppLogger.i('ConvertQueue', 'Conversion completed: ${item.name} -> $outPath');
    } catch (e, stack) {
      AppLogger.e('ConvertQueue', 'Conversion failed for ${item.name}: $e\n$stack');
      _updateItem(
        id,
        (it) => it.copyWith(
          state: DecryptState.FAILED,
          error: e.toString(),
        ),
      );
    } finally {
      streamSub.cancel();
      receivePort.close();
    }
  }

  Future<String> saveSingle(int id) async {
    final item = state.items.firstWhere((i) => i.id == id);
    if (item.result?.audioData == null) {
      throw const FormatException('Audio data not ready to save');
    }

    final outPath = await _saveAudioToFile(
      item.name,
      item.result!.extension,
      item.result!.audioData!,
    );
    _updateItem(id, (it) => it.copyWith(outputPath: outPath));
    return outPath;
  }

  Future<String> _saveAudioToFile(String originalName, String ext, Uint8List data) async {
    final targetDir = await FileUtils.getDefaultOutputDirectory();
    final baseName = originalName.replaceAll(RegExp(r'\.ncm$', caseSensitive: false), '');
    final safeName = FileUtils.sanitizeFileName(baseName);
    final filePath = p.join(targetDir.path, '$safeName.$ext');

    final file = File(filePath);
    await file.writeAsBytes(data, flush: true);
    return filePath;
  }

  void _updateItem(int id, FileItem Function(FileItem) transform) {
    final updated = state.items.map((it) => it.id == id ? transform(it) : it).toList();
    state = state.copyWith(items: updated);
  }
}
