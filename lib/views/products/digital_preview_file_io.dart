import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// Fetches preview from URL and saves to temp file. Returns file path or null.
/// Only saves when response is 200/206 and body looks like media (not JSON/HTML).
Future<String?> fetchPreviewToFile(String previewUrl, String mediaType) async {
  print('[DigitalPreview] fetchPreviewToFile START url=$previewUrl mediaType=$mediaType');
  try {
    final dio = Dio();
    final response = await dio.get<List<int>>(
      previewUrl,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 15),
        validateStatus: (_) => true,
      ),
    );
    final status = response.statusCode ?? 0;
    final contentType = response.headers.value('content-type')?.toLowerCase() ?? '';
    final data = response.data;
    final dataLength = data?.length ?? 0;
    print('[DigitalPreview] Response status=$status contentType=$contentType dataLength=$dataLength');

    if (status != 200 && status != 206) {
      final bodyPreview = data != null && data.isNotEmpty
          ? String.fromCharCodes(data.take(200))
          : 'empty';
      print('[DigitalPreview] REJECT: bad status. bodyPreview=$bodyPreview');
      return null;
    }
    if (data == null || data.isEmpty) {
      print('[DigitalPreview] REJECT: no data');
      return null;
    }
    if (contentType.contains('application/json') || contentType.contains('text/html')) {
      print('[DigitalPreview] REJECT: content-type is JSON/HTML');
      return null;
    }
    if (data.length >= 4) {
      final start = data.sublist(0, 4);
      if (start[0] == 0x7b && start[1] == 0x22) {
        print('[DigitalPreview] REJECT: body starts with {" (JSON)');
        return null;
      }
    }
    final dir = await getTemporaryDirectory();
    final ext = mediaType == 'video' ? 'mp4' : 'mp3';
    final file = File('${dir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.$ext');
    await file.writeAsBytes(data);
    print('[DigitalPreview] SUCCESS saved to ${file.path} size=$dataLength');
    return file.path;
  } catch (e, st) {
    print('[DigitalPreview] fetchPreviewToFile ERROR: $e');
    print('[DigitalPreview] stackTrace: $st');
    return null;
  }
}

VideoPlayerController createVideoControllerFromFile(String filePath) {
  return VideoPlayerController.file(File(filePath));
}
