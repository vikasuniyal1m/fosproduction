import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:archive/archive.dart';

/// Enhanced media service that handles downloading and local playback
/// for both audio and video files with proper error handling and caching
class EnhancedMediaService {
  static final EnhancedMediaService _instance = EnhancedMediaService._internal();
  factory EnhancedMediaService() => _instance;
  EnhancedMediaService._internal();

  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _downloadedFiles = {};
  final Map<String, Function(double)> _progressCallbacks = {};
  final Map<String, String> _contentTypeRegistry = {};

  String _stableBaseName(String productName, {int? orderItemId}) {
    if (orderItemId != null && orderItemId > 0) {
      return 'order_item_$orderItemId';
    }
    return productName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  String _cacheKey(String productName, MediaType mediaType, {int? orderItemId}) =>
      '${mediaType.name}_${_stableBaseName(productName, orderItemId: orderItemId)}';

  void _rememberPath(
    String filePath, {
    required String url,
    required String productName,
    required MediaType mediaType,
    int? orderItemId,
  }) {
    _downloadedFiles[url] = filePath;
    _downloadedFiles[_cacheKey(productName, mediaType, orderItemId: orderItemId)] =
        filePath;
  }

  /// Already on disk from a previous play/download — instant replay, no re-fetch.
  Future<String?> findCachedMediaPath({
    required String productName,
    required MediaType mediaType,
    int? orderItemId,
  }) async {
    final key = _cacheKey(productName, mediaType, orderItemId: orderItemId);
    final mem = _downloadedFiles[key];
    if (mem != null && await File(mem).exists() && await _isFileValid(mem, mediaType)) {
      return mem;
    }

    final directory = await _getDownloadDirectory();
    if (directory == null) return null;

    final base = _stableBaseName(productName, orderItemId: orderItemId);
    final extensions = mediaType == MediaType.video
        ? ['.mp4', '.mov', '.webm', '.mkv', '.m4v']
        : ['.mp3', '.m4a', '.wav', '.aac', '.ogg'];

    for (final ext in extensions) {
      final candidate = path.join(directory.path, '$base$ext');
      if (await _isFileValid(candidate, mediaType)) {
        _downloadedFiles[key] = candidate;
        return candidate;
      }
    }

    try {
      final clean = base.toLowerCase();
      for (final entity in directory.listSync()) {
        if (entity is! File) continue;
        final name = path.basename(entity.path).toLowerCase();
        final matchesOrder = orderItemId != null &&
            name.contains('order_item_$orderItemId');
        final matchesName = name.startsWith(clean);
        if (!matchesOrder && !matchesName) continue;
        if (await _isFileValid(entity.path, mediaType)) {
          _downloadedFiles[key] = entity.path;
          return entity.path;
        }
      }
    } catch (e) {
      debugPrint('🎵🎬 Cache scan error: $e');
    }
    return null;
  }

  /// Download and prepare media for local playback
  /// Returns local file path if successful, null otherwise
  Future<String?> downloadAndPrepareMedia({
    required String url,
    required String productName,
    required MediaType mediaType,
    int? orderItemId,
    Function(double)? onProgress,
    Function(String)? onComplete,
    Function(String)? onError,
  }) async {
    try {
      final cached = await findCachedMediaPath(
        productName: productName,
        mediaType: mediaType,
        orderItemId: orderItemId,
      );
      if (cached != null) {
        debugPrint('🎵🎬 Reusing cached media: $cached');
        _rememberPath(
          cached,
          url: url,
          productName: productName,
          mediaType: mediaType,
          orderItemId: orderItemId,
        );
        onComplete?.call(cached);
        return cached;
      }

      debugPrint('🎵🎬 EnhancedMediaService - Starting download for: $productName');
      debugPrint('🎵🎬 URL: $url');
      debugPrint('🎵🎬 MediaType: $mediaType');
      
      // Fix URL before downloading
      final fixedUrl = _fixUrl(url);
      debugPrint('🎵🎬 Fixed URL: $fixedUrl');
      
      // App-private storage — no runtime storage permission needed
      // Get download directory
      final directory = await _getDownloadDirectory();
      if (directory == null) {
        onError?.call('Could not access storage directory');
        return null;
      }

      // Stable filename — same orderItemId/product always maps to same file
      final fileName =
          _generateFileName(productName, mediaType, url, orderItemId: orderItemId);
      final savePath = path.join(directory.path, fileName);

      // Check if file already exists and is valid
      if (await _isFileValid(savePath, mediaType)) {
        debugPrint('🎵🎬 File already exists and is valid: $savePath');
        _rememberPath(
          savePath,
          url: url,
          productName: productName,
          mediaType: mediaType,
          orderItemId: orderItemId,
        );
        onComplete?.call(savePath);
        return savePath;
      }

      // Register progress callback
      if (onProgress != null) {
        _progressCallbacks[url] = onProgress;
      }

      // Start download
      debugPrint('🎵🎬 Starting download to: $savePath');
      final success = await _downloadFile(
        url: fixedUrl,
        savePath: savePath,
        originalUrl: url,
        mediaType: mediaType,
      );

      if (success) {
        // Check if downloaded file is a ZIP and extract media from it
        String finalPath = savePath;
        if (await _isZipFile(savePath)) {
          debugPrint('🎵🎬 Downloaded file is ZIP, extracting ${mediaType.name}...');
          final extractedPath = await _extractMediaFromZip(savePath, mediaType);
          if (extractedPath != null) {
            finalPath = extractedPath;
            // Delete the ZIP file after extraction
            try {
              await File(savePath).delete();
              debugPrint('🎵🎬 Deleted ZIP file after extraction');
            } catch (e) {
              debugPrint('🎵🎬 Error deleting ZIP file: $e');
            }
          } else {
            debugPrint('🎵🎬 Failed to extract ${mediaType.name} from ZIP');
            onError?.call('Failed to extract media from downloaded archive');
            return null;
          }
        }
        
        _rememberPath(
          finalPath,
          url: url,
          productName: productName,
          mediaType: mediaType,
          orderItemId: orderItemId,
        );
        onComplete?.call(finalPath);
        debugPrint('🎵🎬 Download completed successfully: $finalPath');
        return finalPath;
      } else {
        onError?.call('Download failed');
        return null;
      }
    } catch (e) {
      debugPrint('🎵🎬 Error in downloadAndPrepareMedia: $e');
      onError?.call('Download error: $e');
      return null;
    }
  }

  /// Download file with progress tracking
  Future<bool> _downloadFile({
    required String url,
    required String savePath,
    required String originalUrl,
    required MediaType mediaType,
  }) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      
      // Add headers to identify the request
      request.headers.addAll({
        'User-Agent': 'FruitsOfSpirit-App/1.0',
        'Accept': mediaType == MediaType.video 
          ? 'video/*, application/zip, application/octet-stream'
          : 'audio/*, application/zip, application/octet-stream',
      });

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        debugPrint('🎵🎬 Download failed with status: ${streamedResponse.statusCode}');
        return false;
      }

      final contentLength = streamedResponse.contentLength ?? 0;
      if (contentLength == 0) {
        debugPrint('🎵🎬 Invalid file size: 0');
        return false;
      }

      // Check content type
      final contentType = streamedResponse.headers['content-type'] ?? '';
      if (!_isValidContentType(contentType, mediaType)) {
        debugPrint('🎵🎬 Invalid content type: $contentType for $mediaType');
        return false;
      }

      // Save file with progress tracking
      final file = File(savePath);
      final sink = file.openWrite();
      int downloadedBytes = 0;

      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        
        if (contentLength > 0) {
          final progress = downloadedBytes / contentLength;
          _downloadProgress[originalUrl] = progress;
          _progressCallbacks[originalUrl]?.call(progress);
          
          if (kDebugMode) {
            // Only print progress at 5% intervals to reduce console spam
            final progressPercent = (progress * 100).round();
            if (progressPercent % 5 == 0 || progressPercent == 100) {
              print('🎵🎬 Download progress: $progressPercent%');
            }
          }
        }
      }

      await sink.close();

      // Verify the downloaded file
      if (!await _isFileValid(savePath, mediaType)) {
        debugPrint('🎵🎬 Downloaded file validation failed');
        await file.delete();
        return false;
      }

      // Clean up progress tracking
      _downloadProgress.remove(originalUrl);
      _progressCallbacks.remove(originalUrl);
      
      return true;
    } catch (e) {
      debugPrint('🎵🎬 Download error: $e');
      _downloadProgress.remove(originalUrl);
      _progressCallbacks.remove(originalUrl);
      return false;
    }
  }

  /// Check if content type is valid for the media type
  bool _isValidContentType(String contentType, MediaType mediaType) {
    if (contentType.isEmpty) return true; // Allow if not specified
    
    final lowerContentType = contentType.toLowerCase();
    
    // Allow ZIP files - they might contain the actual media file
    if (lowerContentType.contains('zip') || 
        lowerContentType.contains('application/octet-stream')) {
      return true;
    }
    
    switch (mediaType) {
      case MediaType.audio:
        return lowerContentType.contains('audio') || 
               lowerContentType.contains('mpeg');
      case MediaType.video:
        return lowerContentType.contains('video') || 
               lowerContentType.contains('mp4');
    }
  }

  /// Validate downloaded file
  Future<bool> _isFileValid(String filePath, MediaType mediaType) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      
      final fileSize = await file.length();
      if (fileSize == 0) return false;
      
      // Check if it's a ZIP file
      final extension = path.extension(filePath).toLowerCase();
      if (extension == '.zip' || await _isZipFile(filePath)) {
        // ZIP files are valid - we'll extract media from them
        return true;
      }
      
      // Additional validation based on media type
      switch (mediaType) {
        case MediaType.audio:
          return _isAudioExtension(extension);
        case MediaType.video:
          return _isVideoExtension(extension);
      }
    } catch (e) {
      debugPrint('🎵🎬 Error validating file: $e');
      return false;
    }
    return false;
  }

  /// Check if file is a ZIP archive
  Future<bool> _isZipFile(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.openRead(0, 4).first;
      // ZIP files start with PK\x03\x04 or PK\x05\x06 or PK\x07\x08
      return bytes.length >= 4 && 
             bytes[0] == 0x50 && 
             bytes[1] == 0x4B &&
             (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07) &&
             (bytes[3] == 0x04 || bytes[3] == 0x06 || bytes[3] == 0x08);
    } catch (e) {
      return false;
    }
  }

  /// Extract media file from ZIP archive
  Future<String?> _extractMediaFromZip(String zipPath, MediaType mediaType) async {
    try {
      debugPrint('🎵🎬 Extracting ${mediaType.name} from ZIP: $zipPath');
      
      final zipFile = File(zipPath);
      final bytes = await zipFile.readAsBytes();
      
      // Use archive package to extract
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Find the media file in the archive
      ArchiveFile? mediaFile;
      for (final file in archive) {
        final fileName = file.name.toLowerCase();
        if (mediaType == MediaType.video && _isVideoFileName(fileName)) {
          mediaFile = file;
          break;
        } else if (mediaType == MediaType.audio && _isAudioFileName(fileName)) {
          mediaFile = file;
          break;
        }
      }
      
      if (mediaFile == null) {
        debugPrint('🎵🎬 No ${mediaType.name} file found in ZIP');
        return null;
      }
      
      // Extract to the same directory
      final dir = path.dirname(zipPath);
      final extractedPath = path.join(dir, mediaFile.name);
      final extractedFile = File(extractedPath);
      
      await extractedFile.writeAsBytes(mediaFile.content as List<int>);
      
      debugPrint('🎵🎬 Extracted ${mediaType.name} file: $extractedPath');
      return extractedPath;
      
    } catch (e) {
      debugPrint('🎵🎬 Error extracting from ZIP: $e');
      return null;
    }
  }

  /// Check if filename indicates it's a video
  bool _isVideoFileName(String fileName) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m3u8', '.flv'];
    return videoExtensions.any((ext) => fileName.endsWith(ext));
  }

  /// Check if filename indicates it's an audio
  bool _isAudioFileName(String fileName) {
    final audioExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'];
    return audioExtensions.any((ext) => fileName.endsWith(ext));
  }

  /// Check if extension is valid for audio
  bool _isAudioExtension(String extension) {
    const audioExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'];
    return audioExtensions.contains(extension);
  }

  /// Check if extension is valid for video
  bool _isVideoExtension(String extension) {
    const videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m3u8', '.flv'];
    return videoExtensions.contains(extension);
  }

  /// Generate stable filename (no timestamp — reuse on next play)
  String _generateFileName(
    String productName,
    MediaType mediaType,
    String url, {
    int? orderItemId,
  }) {
    final base = _stableBaseName(productName, orderItemId: orderItemId);

    String extension = _getFileExtensionFromUrl(url);
    if (extension.isEmpty ||
        extension == '.php' ||
        extension == '.zip' ||
        !_isValidExtensionForMediaType(extension, mediaType)) {
      extension = mediaType == MediaType.video ? '.mp4' : '.mp3';
    }

    return '$base$extension';
  }

  /// Check if extension is valid for the media type
  bool _isValidExtensionForMediaType(String extension, MediaType mediaType) {
    final ext = extension.toLowerCase();
    switch (mediaType) {
      case MediaType.audio:
        return _isAudioExtension(ext);
      case MediaType.video:
        return _isVideoExtension(ext);
    }
  }

  /// Get file extension from URL with better detection
  String _getFileExtensionFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      String path = uri.path.toLowerCase();
      
      // Handle URLs with query parameters
      final queryIndex = path.indexOf('?');
      if (queryIndex != -1) {
        path = path.substring(0, queryIndex);
      }
      
      // Extract extension
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1 && lastDot < path.length - 1) {
        return path.substring(lastDot);
      }
      
      // Try to detect from content-type registry if available
      final registeredType = _contentTypeRegistry[url];
      if (registeredType != null) {
        switch (registeredType) {
          case 'audio':
            return '.mp3';
          case 'video':
            return '.mp4';
        }
      }
      
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Get local path for media (download if not exists)
  Future<String?> getLocalMediaPath({
    required String url,
    required String productName,
    required MediaType mediaType,
    int? orderItemId,
    Function(double)? onProgress,
    Function(String)? onError,
  }) async {
    final cached = await findCachedMediaPath(
      productName: productName,
      mediaType: mediaType,
      orderItemId: orderItemId,
    );
    if (cached != null) {
      _rememberPath(
        cached,
        url: url,
        productName: productName,
        mediaType: mediaType,
        orderItemId: orderItemId,
      );
      return cached;
    }

    final existingPath = _downloadedFiles[url];
    if (existingPath != null && await File(existingPath).exists()) {
      return existingPath;
    }

    return await downloadAndPrepareMedia(
      url: url,
      productName: productName,
      mediaType: mediaType,
      orderItemId: orderItemId,
      onProgress: onProgress,
      onError: onError,
    );
  }

  /// Get download progress
  double? getDownloadProgress(String url) {
    return _downloadProgress[url];
  }

  /// Check if media is downloaded
  Future<bool> isMediaDownloaded(String url) async {
    final localPath = _downloadedFiles[url];
    if (localPath == null) return false;
    
    return await File(localPath).exists();
  }

  /// Delete downloaded media
  Future<bool> deleteDownloadedMedia(String url) async {
    try {
      final localPath = _downloadedFiles[url];
      if (localPath == null) return false;

      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        _downloadedFiles.remove(url);
        _downloadProgress.remove(url);
        _progressCallbacks.remove(url);
        _contentTypeRegistry.remove(url);
        
        debugPrint('🎵🎬 Media deleted: $localPath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('🎵🎬 Error deleting media: $e');
      return false;
    }
  }

  /// Clear all downloaded media
  Future<void> clearAllDownloads() async {
    for (final url in List.from(_downloadedFiles.keys)) {
      await deleteDownloadedMedia(url);
    }
  }

  /// Fix common URL issues
  String _fixUrl(String url) {
    if (url.isEmpty) return url;
    
    String fixedUrl = url;
    
    // Fix missing slash after protocol
    if (fixedUrl.startsWith('https:/') && !fixedUrl.startsWith('https://')) {
      fixedUrl = fixedUrl.replaceFirst('https:/', 'https://');
    } else if (fixedUrl.startsWith('http:/') && !fixedUrl.startsWith('http://')) {
      fixedUrl = fixedUrl.replaceFirst('http:/', 'http://');
    }
    
    // Fix triple slashes in URL (like https:///example.com)
    if (fixedUrl.contains('https:///')) {
      fixedUrl = fixedUrl.replaceAll('https:///', 'https://');
    } else if (fixedUrl.contains('http:///')) {
      fixedUrl = fixedUrl.replaceAll('http:///', 'http://');
    }
    
    // Fix double slash after host (e.g. ...org//api/...)
    fixedUrl = fixedUrl.replaceAllMapped(
      RegExp(r'(https?://[^/]+)//+'),
      (m) => '${m.group(1)}/',
    );

    // Only fix excessive slashes (3 or more) in the path
    fixedUrl = fixedUrl.replaceAll(RegExp(r'/{3,}'), '/');
    
    return fixedUrl;
  }

  /// Get download directory (app-private — no storage permission)
  Future<Directory?> _getDownloadDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final directory = Directory(path.join(base.path, 'DigitalDownloads'));

    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    } catch (e) {
      debugPrint('🎵🎬 Error creating download directory: $e');
      return null;
    }
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Media type enum
enum MediaType {
  audio,
  video,
}
