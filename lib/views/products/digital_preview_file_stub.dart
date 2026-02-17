import 'package:video_player/video_player.dart';

/// Web: no file access – returns null so caller plays from URL.
Future<String?> fetchPreviewToFile(String previewUrl, String mediaType) async {
  return null;
}

/// Web: should not be called (we always use URL).
VideoPlayerController createVideoControllerFromFile(String filePath) {
  throw UnsupportedError('Play from file is not supported on web');
}
