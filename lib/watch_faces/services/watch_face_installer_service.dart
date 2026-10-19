import 'dart:io' show Directory, File, Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/watch_face_model.dart';

class _DownloadOutcome {
  const _DownloadOutcome({this.path, this.error});

  final String? path;
  final String? error;
}

class InstallResult {
  const InstallResult._(this.success, this.message);

  const InstallResult.success(String message) : this._(true, message);
  const InstallResult.failure(String message) : this._(false, message);

  final bool success;
  final String message;
}

class WatchFaceInstallerService {
  WatchFaceInstallerService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('watch_face_installer');

  final MethodChannel _channel;

  bool isSupportedOnThisDevice(WatchFace face) {
    if (kIsWeb) return false;
    if (face.isApple) return Platform.isIOS;
    if (face.isAndroid) return Platform.isAndroid;
    return false;
  }

  Future<InstallResult> install(WatchFace face) {
    if (face.isApple) return _installAppleWatchFace(face);
    if (face.hasWatchFaceSource) return _installAndroidWatchFace(face);
    return _openAndroidStore(face);
  }

  Future<InstallResult> _installAppleWatchFace(WatchFace face) async {
    if (kIsWeb || !Platform.isIOS) {
      return const InstallResult.failure(
        'Apple Watch faces can only be installed from an iPhone.',
      );
    }
    final stagedPath = await _resolveAppleWatchFaceFile(face);
    if (stagedPath == null || stagedPath.isEmpty) {
      return InstallResult.failure(_downloadFailureMessage(face, 'apple'));
    }

    final fileName = stagedPath.split('/').last;

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'installAppleWatchFace',
        {'fileName': fileName, 'filePath': stagedPath},
      );
      final message = result?['message'] as String? ??
          'Watch face sent to the Apple Watch app.';
      return InstallResult.success(message);
    } on PlatformException catch (e) {
      return InstallResult.failure(_describeIosError(e));
    } on MissingPluginException {
      return InstallResult.failure(
        kDebugMode
            ? 'Install needs a real iPhone with a paired Apple Watch (not Simulator). Rebuild the app after updating iOS native code.'
            : 'Watch face install is not available on this device. Use an iPhone with a paired Apple Watch.',
      );
    }
  }

  /// Download watch face file from backend when user taps Install.
  Future<String?> _resolveAppleWatchFaceFile(WatchFace face) async {
    final remoteUrl = face.downloadUrl;
    if (remoteUrl == null || remoteUrl.isEmpty) {
      _lastDownloadError = 'empty downloadUrl for faceId=${face.id}';
      _log('apple resolve failed: $_lastDownloadError');
      return null;
    }
    final outcome = await _downloadToDocuments(remoteUrl, _watchFaceFileName(face));
    _lastDownloadError = outcome.error;
    return outcome.path;
  }

  String _watchFaceFileName(WatchFace face) {
    final localPath = face.localFilePath;
    if (localPath != null && localPath.isNotEmpty) {
      return localPath.split('/').last;
    }
    final remoteUrl = face.downloadUrl;
    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      return remoteUrl.split('/').last;
    }
    return '${face.id}.watchface';
  }

  Future<Directory> _watchFaceStorageDir() async {
    if (!kIsWeb && Platform.isAndroid) {
      return getApplicationSupportDirectory();
    }
    return getApplicationDocumentsDirectory();
  }

  Future<_DownloadOutcome> _downloadToDocuments(String url, String fileName) async {
    _log('download start url=$url fileName=$fileName');
    try {
      final dir = await _watchFaceStorageDir();
      final filePath = '${dir.path}/$fileName';
      _log('savePath=$filePath');

      final response = await Dio().download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && received == total) {
            _log('download progress 100% ($received bytes)');
          }
        },
      );

      final statusCode = response.statusCode;
      _log('http statusCode=$statusCode');

      final file = File(filePath);
      final exists = await file.exists();
      final length = exists ? await file.length() : 0;
      _log('file exists=$exists length=$length');

      if (exists && length > 0) {
        _log('download ok path=$filePath');
        return _DownloadOutcome(path: filePath);
      }

      final error = 'File missing or empty after download (status=$statusCode, length=$length)';
      _log('download failed: $error');
      return _DownloadOutcome(error: error);
    } on DioException catch (e, st) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final bodyPreview = body == null
          ? 'null'
          : body.toString().length > 200
              ? '${body.toString().substring(0, 200)}...'
              : body.toString();
      final error =
          'Dio ${e.type.name} status=$status message=${e.message} body=$bodyPreview';
      _log('download DioException: $error');
      _log('stack: $st');
      return _DownloadOutcome(error: error);
    } catch (e, st) {
      final error = '$e';
      _log('download error: $error');
      _log('stack: $st');
      return _DownloadOutcome(error: error);
    }
  }

  String _downloadFailureMessage(WatchFace face, String platform) {
    const fallback =
        'Could not download the watch face. Check your connection and try again.';
    if (!kDebugMode) return fallback;
    final detail = _lastDownloadError;
    if (detail == null || detail.isEmpty) {
      return '$fallback\n[debug] faceId=${face.id} url=${face.downloadUrl} platform=$platform';
    }
    return '$fallback\n[debug] $detail';
  }

  String? _lastDownloadError;

  void _log(String message) {
    debugPrint('[WatchFace] $message');
  }

  String _describeIosError(PlatformException e) {
    switch (e.code) {
      case 'FILE_NOT_FOUND':
        return 'The .watchface file could not be found. Try again on a real iPhone.';
      case 'SIMULATOR_NOT_SUPPORTED':
        return 'Watch face install does not work in the iPhone Simulator, even with a paired Watch simulator. Use a real iPhone with a paired Apple Watch.';
      case 'NO_PAIRED_WATCH':
        return 'No paired Apple Watch was found. Pair a real Apple Watch in the Watch app on your iPhone, then try again.';
      case 'CLOCKKIT_UNAVAILABLE':
        return 'Watch face sharing is not available on this iOS version.';
      default:
        return e.message ?? 'Could not install the watch face.';
    }
  }

  Future<InstallResult> _installAndroidWatchFace(WatchFace face) async {
    if (kIsWeb || !Platform.isAndroid) {
      return const InstallResult.failure(
        'Galaxy / Wear OS faces can only be installed from an Android phone.',
      );
    }
    _log('android install start faceId=${face.id} url=${face.downloadUrl}');
    final stagedPath = await _resolveAndroidWatchFaceFile(face);
    if (stagedPath == null || stagedPath.isEmpty) {
      _log('android install aborted: download failed');
      return InstallResult.failure(_downloadFailureMessage(face, 'android'));
    }

    final fileName = stagedPath.split('/').last;
    _log('android install file ready fileName=$fileName path=$stagedPath');

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'installAndroidWatchFace',
        {'fileName': fileName, 'filePath': stagedPath},
      );
      final message = result?['message'] as String? ??
          'Watch face sent to Galaxy Wearable.';
      return InstallResult.success(message);
    } on PlatformException catch (e) {
      _log('android install PlatformException code=${e.code} message=${e.message} details=${e.details}');
      return InstallResult.failure(_describeAndroidError(e));
    } on MissingPluginException catch (e) {
      _log('android install MissingPluginException: $e');
      return InstallResult.failure(
        kDebugMode
            ? 'Install needs a real Android phone with Galaxy Wearable. Rebuild the app after updating Android native code.'
            : 'Watch face install is not available on this device. Use Android with Galaxy Wearable paired.',
      );
    }
  }

  Future<String?> _resolveAndroidWatchFaceFile(WatchFace face) async {
    final remoteUrl = face.downloadUrl;
    if (remoteUrl == null || remoteUrl.isEmpty) {
      _lastDownloadError = 'empty downloadUrl for faceId=${face.id}';
      _log('android resolve failed: $_lastDownloadError');
      return null;
    }
    final outcome = await _downloadToDocuments(remoteUrl, _watchFaceFileName(face));
    _lastDownloadError = outcome.error;
    return outcome.path;
  }

  String _describeAndroidError(PlatformException e) {
    switch (e.code) {
      case 'FILE_NOT_FOUND':
        return 'The .wfs file could not be found. Try again on a real Android phone.';
      case 'NO_HANDLER':
        return 'Install Galaxy Wearable, pair your watch, then try again.';
      default:
        return e.message ?? 'Could not install the watch face.';
    }
  }

  Future<InstallResult> _openAndroidStore(WatchFace face) async {
    final packageName = face.packageName;
    final playWebUrl = face.androidPlayStoreUrl ??
        (packageName != null
            ? 'https://play.google.com/store/apps/details?id=$packageName'
            : null);

    if (packageName != null) {
      final marketUri = Uri.parse('market://details?id=$packageName');
      if (await _tryLaunch(marketUri)) {
        return const InstallResult.success(
          'Opening Play Store. Install via Play Store / Galaxy Wearable.',
        );
      }
    }

    if (playWebUrl != null && await _tryLaunch(Uri.parse(playWebUrl))) {
      return const InstallResult.success(
        'Opening Play Store in your browser.',
      );
    }

    final galaxyUrl = face.galaxyStoreUrl;
    if (galaxyUrl != null && await _tryLaunch(Uri.parse(galaxyUrl))) {
      return const InstallResult.success('Opening Galaxy Store.');
    }

    return const InstallResult.failure(
      'No store link is available for this watch face.',
    );
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      if (!await canLaunchUrl(uri)) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException catch (_) {
      return false;
    }
  }
}
