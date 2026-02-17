import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
// Use file only on non-web (mobile/desktop)
import 'digital_preview_file_io.dart' if (dart.library.html) 'digital_preview_file_stub.dart' as preview_io;

/// In-app digital preview: play video or audio for [durationSeconds], then show pay & download popup.
/// For video, [productImageUrl] can be set to show product photo instead of video (same 10 sec → popup).
class DigitalPreviewPlayerScreen extends StatefulWidget {
  const DigitalPreviewPlayerScreen({
    super.key,
    required this.previewUrl,
    required this.mediaType,
    this.durationSeconds = 15,
    required this.onPayPressed,
    this.productName,
    this.productImageUrl,
  });

  final String previewUrl;
  final String mediaType; // 'video' | 'audio'
  final int durationSeconds;
  final VoidCallback onPayPressed;
  final String? productName;
  final String? productImageUrl;

  @override
  State<DigitalPreviewPlayerScreen> createState() => _DigitalPreviewPlayerScreenState();
}

class _DigitalPreviewPlayerScreenState extends State<DigitalPreviewPlayerScreen> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  Timer? _limitTimer;
  Timer? _countdownTimer;
  bool _previewEnded = false;
  String? _error;
  bool _loading = true;
  /// When true, video is shown as product photo + 10 sec timer (no actual video play).
  bool _showImageInsteadOfVideo = false;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startPreview();
  }


  /// On mobile: fetch preview bytes and save to temp file. On web: returns null (play from URL).
  Future<String?> _fetchPreviewToFile() async {
    return preview_io.fetchPreviewToFile(widget.previewUrl, widget.mediaType);
  }

  Future<void> _startPreview() async {
    print('[DigitalPreview] _startPreview url=${widget.previewUrl} mediaType=${widget.mediaType} kIsWeb=$kIsWeb');
    setState(() { _loading = true; _error = null; });

    // Video with product image: show photo only, 10 sec timer, then same popup (no video load)
    if (widget.mediaType == 'video' &&
        widget.productImageUrl != null &&
        widget.productImageUrl!.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _showImageInsteadOfVideo = true;
        _elapsedSeconds = 0;
      });
      _limitTimer = Timer(Duration(seconds: widget.durationSeconds), _onPreviewTimeLimitReached);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _previewEnded) return;
        setState(() {
          if (_elapsedSeconds < widget.durationSeconds) {
            _elapsedSeconds++;
          }
        });
      });
      return;
    }

    final filePath = await _fetchPreviewToFile();
    if (!mounted) return;

    final useUrl = kIsWeb || filePath == null || filePath.isEmpty;
    print('[DigitalPreview] filePath=${filePath ?? "null"} useUrl=$useUrl');

    if (!useUrl && (filePath == null || filePath.isEmpty)) {
      print('[DigitalPreview] No file and not using URL -> show fetch error');
      setState(() {
        _loading = false;
        _error = 'Could not load preview. Check your connection and try again.';
      });
      return;
    }

    try {
      if (widget.mediaType == 'audio') {
        _audioPlayer = AudioPlayer();
        if (useUrl) {
          print('[DigitalPreview] Audio: setUrl');
          await _audioPlayer!.setUrl(widget.previewUrl);
        } else {
          print('[DigitalPreview] Audio: setFilePath $filePath');
          await _audioPlayer!.setFilePath(filePath!);
        }
        unawaited(_audioPlayer!.play());
        print('[DigitalPreview] Audio play started');
      } else {
        if (useUrl) {
          print('[DigitalPreview] Video: networkUrl');
          _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.previewUrl));
        } else {
          print('[DigitalPreview] Video: file $filePath');
          _videoController = preview_io.createVideoControllerFromFile(filePath!);
        }
        print('[DigitalPreview] Video: initializing...');
        await _videoController!.initialize();
        print('[DigitalPreview] Video: initialized, playing...');
        await _videoController!.play();
        print('[DigitalPreview] Video play started');
      }
    } catch (e, st) {
      print('[DigitalPreview] PLAY ERROR: $e');
      print('[DigitalPreview] PLAY stackTrace: $st');
      if (mounted) {
        final msg = e.toString().length > 80 ? '${e.toString().substring(0, 80)}...' : e.toString();
        setState(() {
          _loading = false;
          _error = widget.mediaType == 'video'
              ? 'Could not load video: $msg'
              : 'Could not load audio: $msg';
        });
      }
      return;
    }

    if (!mounted) return;
    _limitTimer = Timer(Duration(seconds: widget.durationSeconds), _onPreviewTimeLimitReached);
    setState(() { _loading = false; });
  }

  void _onPreviewTimeLimitReached() {
    if (_previewEnded) return;
    _previewEnded = true;
    _limitTimer?.cancel();
    _limitTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _audioPlayer?.stop();
    _videoController?.pause();
    if (mounted) _showPayPopup();
  }

  void _showPayPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: AppColors.primary, size: 28),
            SizedBox(width: 10),
            Text('Preview ended', style: TextStyle(fontSize: ScreenSize.textLarge)),
          ],
        ),
        content: Text(
          'You\'ve watched the first ${widget.durationSeconds} seconds. Pay with Stripe to unlock full access and download MP3/MP4 for lifetime.',
          style: TextStyle(fontSize: ScreenSize.textSmall, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Get.back();
            },
            child: Text('Maybe Later', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Get.back();
              widget.onPayPressed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Pay & Download'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _limitTimer?.cancel();
    _countdownTimer?.cancel();
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Widget _buildImagePreview() {
    final sec = _elapsedSeconds.clamp(0, widget.durationSeconds);
    final url = (widget.productImageUrl ?? '').trim();
    return Column(
      children: [
        Expanded(
          child: Center(
            child: url.isEmpty
                ? Icon(Icons.image_not_supported, size: 80, color: Colors.white54)
                : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              width: double.infinity,
              placeholder: (_, __) => Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              errorWidget: (_, __, ___) => Icon(
                Icons.image_not_supported,
                size: 80,
                color: Colors.white54,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: sec / widget.durationSeconds,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 8),
              Text(
                '$sec / ${widget.durationSeconds} sec',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          title: Text('Preview', style: TextStyle(color: Colors.white, fontSize: ScreenSize.textMedium)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Loading preview...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          title: Text('Preview', style: TextStyle(color: Colors.white, fontSize: ScreenSize.textMedium)),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(ScreenSize.spacingMedium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.white54),
                SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Preview (${widget.durationSeconds} sec)',
          style: TextStyle(color: Colors.white, fontSize: ScreenSize.textMedium),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _showImageInsteadOfVideo && widget.productImageUrl != null
                    ? _buildImagePreview()
                    : widget.mediaType == 'video' && _videoController != null && _videoController!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : widget.mediaType == 'audio'
                            ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.music_note, size: 80, color: AppColors.primary.withOpacity(0.8)),
                              SizedBox(height: 16),
                              Text(
                                widget.productName ?? 'Audio preview',
                                style: TextStyle(color: Colors.white70, fontSize: ScreenSize.textSmall),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 24),
                              if (_audioPlayer != null)
                                StreamBuilder<Duration>(
                                  stream: _audioPlayer!.positionStream,
                                  builder: (context, snapshot) {
                                    final pos = snapshot.data ?? Duration.zero;
                                    final limit = Duration(seconds: widget.durationSeconds);
                                    final sec = pos.inSeconds.clamp(0, widget.durationSeconds);
                                    return Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 24),
                                      child: Column(
                                        children: [
                                          LinearProgressIndicator(
                                            value: sec / widget.durationSeconds,
                                            backgroundColor: Colors.white24,
                                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '$sec / ${widget.durationSeconds} sec',
                                            style: TextStyle(color: Colors.white54, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          )
                        : Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(ScreenSize.spacingMedium),
              child: Text(
                'Preview ends in ${widget.durationSeconds} seconds • Pay to unlock full access',
                style: TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
