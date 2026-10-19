import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../../controllers/profile_controller.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../services/enhanced_media_service.dart';

/// Full-screen professional video player for purchased/downloaded video
/// Features: play/pause, seek, repeat, share, fullscreen support
class FullVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String filePath;
  final String productName;
  final String? productImageUrl;
  final int? orderItemId;

  const FullVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.filePath,
    required this.productName,
    this.productImageUrl,
    this.orderItemId,
  });

  @override
  State<FullVideoPlayerScreen> createState() => _FullVideoPlayerScreenState();
}

class _FullVideoPlayerScreenState extends State<FullVideoPlayerScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isRepeatMode = false;
  bool _isCompleted = false;
  bool _isLoading = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _error;
  bool _showControls = true;
  Timer? _controlsTimer;
  final EnhancedMediaService _mediaService = EnhancedMediaService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
    _startControlsTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlsTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Pause video when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _videoController?.pause();
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  String? _suggestedFilename;

  Future<String> _resolvePlaybackUrl() async {
    var url = widget.videoUrl.trim();
    if (url.isEmpty && widget.orderItemId != null) {
      final profile = Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : Get.put(ProfileController());
      final info = await profile.getDigitalDownloadInfo(
        widget.orderItemId!,
        silent: true,
      );
      url = info?['download_url']?.toString() ?? '';
      _suggestedFilename = info?['suggested_filename']?.toString();
    }
    if (url.isEmpty) return '';
    final profile = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    return profile.withAuthToken(_fixVideoUrl(url));
  }

  bool _needsLocalPrepare(String url) {
    if (widget.orderItemId != null) return true;
    final lower = url.toLowerCase();
    final name = (_suggestedFilename ?? '').toLowerCase();
    return lower.contains('serve-digital-file') ||
        lower.contains('.php?token=') ||
        name.endsWith('.zip');
  }

  Future<String?> _findLocalVideoFile() async {
    if (widget.filePath.isNotEmpty) {
      final f = File(widget.filePath);
      if (await f.exists()) return widget.filePath;
    }
    return _mediaService.findCachedMediaPath(
      productName: widget.productName,
      mediaType: MediaType.video,
      orderItemId: widget.orderItemId,
    );
  }

  void _attachControllerListeners() {
    _videoController!.addListener(() {
      if (_videoController!.value.hasError && mounted) {
        setState(() {
          _error =
              'Video player error: ${_videoController!.value.errorDescription ?? "Unknown error"}';
          _isLoading = false;
          _isDownloading = false;
        });
      }
      if (mounted && _videoController!.value.isInitialized) {
        setState(() {
          _currentPosition = _videoController!.value.position;
          _isPlaying = _videoController!.value.isPlaying;
        });
      }
      if (_videoController!.value.isCompleted) {
        if (_isRepeatMode) {
          _videoController!.seekTo(Duration.zero);
          _videoController!.play();
        } else if (mounted) {
          setState(() {
            _isPlaying = false;
            _isCompleted = true;
          });
        }
      }
    });
  }

  Future<void> _initializeVideo() async {
    try {
      var localPath = await _findLocalVideoFile();
      String? streamUrl;

      if (localPath == null) {
        streamUrl = await _resolvePlaybackUrl();
        if (streamUrl.isEmpty) {
          throw Exception('Video URL not available');
        }

        if (_needsLocalPrepare(streamUrl)) {
          localPath = await _mediaService.findCachedMediaPath(
            productName: widget.productName,
            mediaType: MediaType.video,
            orderItemId: widget.orderItemId,
          );
          if (localPath == null) {
            if (mounted) {
              setState(() {
                _isDownloading = true;
                _downloadProgress = 0;
              });
            }
            localPath = await _mediaService.getLocalMediaPath(
              url: streamUrl,
              productName: widget.productName,
              mediaType: MediaType.video,
              orderItemId: widget.orderItemId,
              onProgress: (progress) {
                if (mounted) {
                  setState(() {
                    _isDownloading = true;
                    _downloadProgress = progress;
                  });
                }
              },
            );
          }
        }
      }

      if (localPath != null && await File(localPath).exists()) {
        _videoController = VideoPlayerController.file(File(localPath));
      } else {
        streamUrl ??= await _resolvePlaybackUrl();
        if (streamUrl.isEmpty) {
          throw Exception('Video URL not available');
        }
        _videoController =
            VideoPlayerController.networkUrl(Uri.parse(streamUrl));
      }

      _attachControllerListeners();

      await _videoController!.initialize().timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw Exception(
          'Video loading timeout. Please check your internet connection.',
        ),
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
          _isDownloading = false;
          _totalDuration = _videoController!.value.duration;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load video: $e';
          _isLoading = false;
          _isDownloading = false;
        });
      }
      await _videoController?.dispose();
      _videoController = null;
    }
  }

  Widget _buildLoadingPlaceholder() {
    final imageUrl = widget.productImageUrl?.trim() ?? '';
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (imageUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            fadeInDuration: Duration.zero,
            placeholder: (_, __) => const ColoredBox(color: Colors.black),
            errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black),
          ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                _isDownloading
                    ? 'Caching... ${(_downloadProgress * 100).toStringAsFixed(0)}%'
                    : 'Loading video...',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                widget.productName,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Check what content the URL is returning to help debug issues
  Future<void> _checkUrlContent(String url) async {
    try {
      print('[FullVideoPlayer] Checking URL content: $url');
      
      // Make a HEAD request to check content type
      final response = await http.head(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'video/*, */*',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('[FullVideoPlayer] Response status: ${response.statusCode}');
      print('[FullVideoPlayer] Content-Type: ${response.headers['content-type']}');
      print('[FullVideoPlayer] Content-Length: ${response.headers['content-length']}');
      print('[FullVideoPlayer] Content-Disposition: ${response.headers['content-disposition']}');
      
      // If content type doesn't look like video, warn about it
      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      if (!contentType.contains('video/') && !contentType.contains('application/octet-stream')) {
        print('[FullVideoPlayer] WARNING: Content type does not indicate video: $contentType');
      }
      
    } catch (e) {
      print('[FullVideoPlayer] Error checking URL content: $e');
    }
  }
  
  bool _isValidVideoUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      
      // Check if scheme is valid
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return false;
      }
      
      // Check if it's a video file extension (if present)
      final path = uri.path.toLowerCase();
      final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m3u8', '.flv'];
      final hasVideoExtension = videoExtensions.any((ext) => path.endsWith(ext));
      
      // Check for indicators that this is a video/streaming URL
      final hasVideoIndicators = path.contains('stream') || 
                                path.contains('video') || 
                                path.contains('serve-digital-file') ||
                                path.contains('download') ||
                                uri.host.contains('video');
      
      // If no extension, but has video indicators or no extension at all, consider it valid
      return hasVideoExtension || hasVideoIndicators || !path.contains('.');
    } catch (e) {
      print('URL validation error: $e');
      return false;
    }
  }

  void _playVideo() async {
    if (_videoController == null || !_isInitialized) return;
    await _videoController!.play();
    _startControlsTimer();
  }

  void _pauseVideo() async {
    if (_videoController != null) {
      await _videoController!.pause();
    }
  }

  void _togglePlayPause() {
    if (_isCompleted) {
      // Replay from beginning
      _videoController!.seekTo(Duration.zero);
      _playVideo();
      setState(() {
        _isCompleted = false;
      });
    } else if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  void _seekTo(Duration position) async {
    if (_videoController != null) {
      await _videoController!.seekTo(position);
      // Reset completion state if seeking to beginning
      if (position == Duration.zero && _isCompleted) {
        setState(() {
          _isCompleted = false;
        });
      }
    }
  }

  void _toggleRepeat() {
    setState(() {
      _isRepeatMode = !_isRepeatMode;
    });
  }

  void _shareVideo() async {
    try {
      final file = File(widget.filePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(widget.filePath)],
          text: '🎬 ${widget.productName}',
          subject: 'Video from Fruits of Spirit',
        );
      } else {
        Get.snackbar(
          'Error',
          'Video file not found',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not share video: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading && !_isInitialized
          ? _buildLoadingPlaceholder()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: _toggleControls,
                  child: Stack(
                    children: [
                      // Video Player
                      Center(
                        child: _videoController != null && _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : Container(),
                      ),

                      // Center Play/Pause Button (always visible)
                      Center(
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Icon(
                              _isCompleted ? Icons.replay : (_isPlaying ? Icons.pause : Icons.play_arrow),
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),

                      // Controls Overlay
                      if (_showControls)
                        _buildControlsOverlay(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top Bar
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                  Expanded(
                    child: Text(
                      widget.productName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ScreenSize.textMedium,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _shareVideo,
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Bottom Controls
          Column(
            children: [
              // Progress Slider
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingLarge),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _currentPosition.inMilliseconds.toDouble().clamp(
                      0,
                      _totalDuration.inMilliseconds.toDouble().max(1),
                    ),
                    max: _totalDuration.inMilliseconds.toDouble().max(1),
                    onChanged: (value) {
                      _seekTo(Duration(milliseconds: value.round()));
                      _startControlsTimer();
                    },
                  ),
                ),
              ),

              // Time Labels and Controls
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingMedium, vertical: ScreenSize.spacingSmall),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const Spacer(),
                    // Control Buttons
                    IconButton(
                      icon: Icon(
                        _isRepeatMode ? Icons.repeat_one : Icons.repeat,
                        color: _isRepeatMode ? AppColors.primary : Colors.white.withOpacity(0.7),
                        size: 24,
                      ),
                      onPressed: () {
                        _toggleRepeat();
                        _startControlsTimer();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.skip_previous,
                        color: Colors.white.withOpacity(0.7),
                        size: 24,
                      ),
                      onPressed: () {
                        _seekTo(Duration.zero);
                        _startControlsTimer();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.skip_next,
                        color: Colors.white.withOpacity(0.7),
                        size: 24,
                      ),
                      onPressed: () {
                        _seekTo(_totalDuration);
                        _startControlsTimer();
                      },
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(_totalDuration),
                      style: TextStyle(
                        fontSize: ScreenSize.textSmall,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Downloaded indicator
              Container(
                margin: EdgeInsets.only(bottom: ScreenSize.spacingMedium),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_done, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Downloaded to device',
                      style: TextStyle(
                        fontSize: ScreenSize.textExtraSmall,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fix common URL issues for video files
  String _fixVideoUrl(String url) {
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
    
    fixedUrl = fixedUrl.replaceAllMapped(
      RegExp(r'(https?://[^/]+)//+'),
      (m) => '${m.group(1)}/',
    );
    fixedUrl = fixedUrl.replaceAll(RegExp(r'/{3,}'), '/');
    
    return fixedUrl;
  }

extension on double {
  double max(double other) => this > other ? this : other;
}
