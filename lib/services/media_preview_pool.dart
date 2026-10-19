import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// Reuses initialized video/audio players + disk cache so media is not re-fetched.
class MediaPreviewPool {
  MediaPreviewPool._();
  static final MediaPreviewPool instance = MediaPreviewPool._();

  static const _maxEntries = 5;
  final Map<String, _VideoEntry> _videos = {};
  final Map<String, _AudioEntry> _audios = {};

  String _key(String url) =>
      sha256.convert(utf8.encode(url)).toString().substring(0, 16);

  String _videoFileName(String url) => 'video_${_key(url)}.mp4';
  String _audioFileName(String url) => 'audio_${_key(url)}.mp3';

  Future<File?> cachedVideoFile(String url) async {
    final dir = await _videoDir();
    final file = File('${dir.path}/${_videoFileName(url)}');
    if (!await file.exists()) return null;
    if (!await _isValidVideoFile(file)) {
      await file.delete();
      return null;
    }
    return file;
  }

  Future<File?> cachedAudioFile(String url) async {
    final dir = await _audioDir();
    final file = File('${dir.path}/${_audioFileName(url)}');
    if (!await file.exists() || await file.length() < 1024) return null;
    return file;
  }

  /// Returns a ready (initialized) controller — from pool or disk/network.
  Future<VideoPlayerController> acquireVideo(String url) async {
    final key = _key(url);
    final pooled = _videos[key];
    if (pooled != null && pooled.controller.value.isInitialized) {
      pooled.refCount++;
      pooled.lastUsed = DateTime.now();
      await pooled.controller.pause();
      await pooled.controller.seekTo(Duration.zero);
      return pooled.controller;
    }

    final cached = await cachedVideoFile(url);
    final controller = cached != null
        ? VideoPlayerController.file(cached)
        : VideoPlayerController.networkUrl(Uri.parse(url));

    await controller.initialize();
    _videos[key] = _VideoEntry(
      url: url,
      controller: controller,
      refCount: 1,
      lastUsed: DateTime.now(),
    );
    _evictIfNeeded(_videos);
    return controller;
  }

  void releaseVideo(String url) {
    final key = _key(url);
    final entry = _videos[key];
    if (entry == null) return;
    entry.refCount--;
    entry.controller.pause();
    entry.lastUsed = DateTime.now();
  }

  Future<AudioPlayer> acquireAudio(String url) async {
    final key = _key(url);
    final pooled = _audios[key];
    if (pooled != null && pooled.ready) {
      pooled.refCount++;
      pooled.lastUsed = DateTime.now();
      await pooled.player.pause();
      await pooled.player.seek(Duration.zero);
      return pooled.player;
    }

    final player = AudioPlayer();
    final cached = await cachedAudioFile(url);
    if (cached != null) {
      await player.setFilePath(cached.path);
    } else {
      await player.setUrl(url);
    }

    _audios[key] = _AudioEntry(
      url: url,
      player: player,
      refCount: 1,
      ready: true,
      lastUsed: DateTime.now(),
    );
    _evictIfNeeded(_audios);
    return player;
  }

  void releaseAudio(String url) {
    final key = _key(url);
    final entry = _audios[key];
    if (entry == null) return;
    entry.refCount--;
    entry.player.pause();
    entry.lastUsed = DateTime.now();
  }

  Future<void> ensureVideoCached(String url) async {
    if (await cachedVideoFile(url) != null) return;
    final dir = await _videoDir();
    final file = File('${dir.path}/${_videoFileName(url)}');
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) return;
      final sink = file.openWrite();
      await response.pipe(sink);
      await sink.close();
      if (!await _isValidVideoFile(file)) {
        await file.delete();
      }
    } finally {
      client.close();
    }
  }

  Future<void> ensureAudioCached(String url) async {
    if (await cachedAudioFile(url) != null) return;
    final dir = await _audioDir();
    final file = File('${dir.path}/${_audioFileName(url)}');
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) return;
      final sink = file.openWrite();
      await response.pipe(sink);
      await sink.close();
    } finally {
      client.close();
    }
  }

  Future<Directory> _videoDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/cached_videos');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _audioDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/cached_audio');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<bool> _isValidVideoFile(File file) async {
    try {
      if (await file.length() < 12) return false;
      final raf = await file.open();
      try {
        final bytes = await raf.read(12);
        if (bytes.length >= 8 &&
            String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
          return true;
        }
        return bytes.length >= 4 &&
            bytes[0] == 0x1A &&
            bytes[1] == 0x45 &&
            bytes[2] == 0xDF &&
            bytes[3] == 0xA3;
      } finally {
        await raf.close();
      }
    } catch (_) {
      return false;
    }
  }

  void _evictIfNeeded<T>(Map<String, T> map) {
    if (map.length <= _maxEntries) return;
    String? oldestKey;
    DateTime? oldest;
    map.forEach((key, entry) {
      final used = entry is _VideoEntry
          ? entry.lastUsed
          : (entry as _AudioEntry).lastUsed;
      if (oldest == null || used.isBefore(oldest!)) {
        oldest = used;
        oldestKey = key;
      }
    });
    if (oldestKey == null) return;
    final removed = map.remove(oldestKey);
    if (removed is _VideoEntry && removed.refCount <= 0) {
      removed.controller.dispose();
    } else if (removed is _AudioEntry && removed.refCount <= 0) {
      removed.player.dispose();
    }
  }
}

class _VideoEntry {
  final String url;
  final VideoPlayerController controller;
  int refCount;
  DateTime lastUsed;

  _VideoEntry({
    required this.url,
    required this.controller,
    required this.refCount,
    required this.lastUsed,
  });
}

class _AudioEntry {
  final String url;
  final AudioPlayer player;
  int refCount;
  bool ready;
  DateTime lastUsed;

  _AudioEntry({
    required this.url,
    required this.player,
    required this.refCount,
    required this.ready,
    required this.lastUsed,
  });
}
