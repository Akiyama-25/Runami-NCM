import '../api/netease_direct_client.dart';
import '../decrypt/models/decrypt_models.dart';
import '../utils/app_prefs.dart';
import 'lrc_parser.dart';

class LyricMatcher {
  final NeteaseDirectClient _client;

  LyricMatcher({NeteaseDirectClient? client})
      : _client = client ?? NeteaseDirectClient();

  Future<String?> matchLyric(NcmMetadata metadata) async {
    if (!AppPrefs.enableLyric) return null;

    LyricData? lyricData;

    // 1. First try by musicId directly
    if (metadata.musicId > 0) {
      lyricData = await _client.getLyric(metadata.musicId);
    }

    // 2. If no lyric yet, search by song name and artist
    if ((lyricData == null || lyricData.lrc == null || lyricData.lrc!.trim().isEmpty) &&
        metadata.musicName.isNotEmpty &&
        metadata.musicName != 'Unknown') {
      final artist = metadata.artists.isNotEmpty ? metadata.artists.first : '';
      final searchId = await _client.searchSongId(name: metadata.musicName, artist: artist);
      if (searchId != null && searchId > 0) {
        lyricData = await _client.getLyric(searchId);
      }
    }

    if (lyricData == null) return null;

    final rawLrc = lyricData.lrc;
    final transLrc = lyricData.tlyric;

    final embedOrig = AppPrefs.lyricEmbedOriginal;
    final embedTrans = AppPrefs.lyricEmbedTranslated;

    if (embedOrig && embedTrans) {
      final origLines = LrcParser.parse(rawLrc);
      final transLines = LrcParser.parse(transLrc);
      return LrcParser.merge(origLines, transLines);
    } else if (embedOrig) {
      return rawLrc;
    } else if (embedTrans) {
      return transLrc;
    }

    return null;
  }
}
