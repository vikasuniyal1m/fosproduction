import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

import '../utils/app_colors.dart';
import '../services/media_preview_pool.dart';

class CachedVideoPreviewWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onPreviewEnd;
  final bool autoPlay;
  final Duration previewDuration;

  const CachedVideoPreviewWidget({
    Key? key,
    required this.videoUrl,
    this.onPreviewEnd,
    this.autoPlay = true,
    this.previewDuration = const Duration(seconds: 12),
  }) : super(key: key);

  @override
  State<CachedVideoPreviewWidget> createState() => _CachedVideoPreviewWidgetState();
}

class _CachedVideoPreviewWidgetState extends State<CachedVideoPreviewWidget>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isCompleted = false;
  bool _showPayButton = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  Timer? _previewTimer;
  File? _cachedFile;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
  }

  @override
  void didUpdateWidget(covariant CachedVideoPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _swapVideo(oldWidget.videoUrl);
    }
  }

  Future<void> _swapVideo(String oldUrl) async {
    _previewTimer?.cancel();
    if (_controller != null) {
      _controller!.removeListener(_onVideoPositionChanged);
      MediaPreviewPool.instance.releaseVideo(oldUrl);
      _controller = null;
    }
    if (!mounted) return;
    setState(() {
      _isInitialized = false;
      _isPlaying = false;
      _isCompleted = false;
      _showPayButton = false;
      _hasError = false;
      _cachedFile = null;
    });
    await _initializeVideo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _previewTimer?.cancel();
    if (_controller != null) {
      _controller!.removeListener(_onVideoPositionChanged);
      MediaPreviewPool.instance.releaseVideo(widget.videoUrl);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App going to background - pause video
      if (_isPlaying && _controller != null) {
        _controller!.pause();
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  /// Generate a unique filename for the video URL
  String _generateFileName(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return 'video_${digest.toString().substring(0, 16)}.mp4';
  }

  bool _isLikelyVideoUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    const exts = ['.mp4', '.webm', '.mov', '.m4v', '.avi', '.mkv'];
    return exts.any((e) => lower.endsWith(e));
  }

  /// Reject JPG/PNG/HTML saved as .mp4 from bad cache keys.
  Future<bool> _isValidVideoFile(File file) async {
    try {
      if (!await file.exists()) return false;
      if (await file.length() < 12) return false;
      final raf = await file.open();
      try {
        final bytes = await raf.read(12);
        if (bytes.length >= 8) {
          final box = String.fromCharCodes(bytes.sublist(4, 8));
          if (box == 'ftyp') return true;
        }
        if (bytes.length >= 4 &&
            bytes[0] == 0x1A &&
            bytes[1] == 0x45 &&
            bytes[2] == 0xDF &&
            bytes[3] == 0xA3) {
          return true;
        }
        return false;
      } finally {
        await raf.close();
      }
    } catch (_) {
      return false;
    }
  }

  /// Get the cached video file path
  Future<File?> _getCachedVideoFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/cached_videos');
      
      // Create directory if it doesn't exist
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }
      
      final fileName = _generateFileName(widget.videoUrl);
      final file = File('${videoDir.path}/$fileName');
      
      if (await file.exists()) {
        if (await _isValidVideoFile(file)) {
          print('[CachedVideo] Found cached file: ${file.path}');
          return file;
        }
        print('[CachedVideo] Invalid cache (not video), deleting: ${file.path}');
        await file.delete();
      }
      
      return null;
    } catch (e) {
      print('[CachedVideo] Error getting cached file: $e');
      return null;
    }
  }

  /// Download and cache the video
  Future<File?> _downloadAndCacheVideo() async {
    try {
      final existing =
          await MediaPreviewPool.instance.cachedVideoFile(widget.videoUrl);
      if (existing != null) {
        _cachedFile = existing;
        return existing;
      }

      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/cached_videos');
      
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }
      
      final fileName = _generateFileName(widget.videoUrl);
      final file = File('${videoDir.path}/$fileName');
      if (await file.exists() && await _isValidVideoFile(file)) {
        setState(() => _isDownloading = false);
        _cachedFile = file;
        return file;
      }
      
      final dio = Dio();
      
      await dio.download(
        widget.videoUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = (received / total);
            });
          }
        },
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0',
            'Accept': 'video/mp4,video/*',
          },
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      print('[CachedVideo] Video downloaded and cached: ${file.path}');
      setState(() {
        _isDownloading = false;
        _cachedFile = file;
      });
      
      return file;
    } catch (e) {
      print('[CachedVideo] Error downloading video: $e');
      setState(() {
        _isDownloading = false;
      });
      return null;
    }
  }

  /// Initialize video player with caching
  Future<void> _initializeVideo() async {
    if (!_isLikelyVideoUrl(widget.videoUrl)) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Invalid video URL';
        });
      }
      return;
    }

    File? cachedFile;
    try {
      cachedFile = await _getCachedVideoFile();
      _controller = await MediaPreviewPool.instance.acquireVideo(widget.videoUrl);
      if (cachedFile != null) {
        print('[CachedVideo] Using pooled/cached video');
      } else {
        _downloadAndCacheVideo();
        print('[CachedVideo] Pool init + background cache');
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        if (widget.autoPlay) {
          _controller!.play();
          setState(() {
            _isPlaying = true;
          });
          
          // Start preview timer
          _previewTimer = Timer(widget.previewDuration, () {
            if (mounted) {
              print('[CachedVideo] Preview timer fired after ${widget.previewDuration.inSeconds} seconds');
              _controller!.pause();
              setState(() {
                _isPlaying = false;
                _showPayButton = true;
              });
              print('[CachedVideo] _showPayButton set to true, overlay should appear');
              // Don't auto-trigger popup, let user click Purchase Now button
            }
          });
        }

        // Listen to video position changes
        _controller!.addListener(_onVideoPositionChanged);
      }
    } catch (e) {
      print('[CachedVideo] Error initializing video: $e');
      // Bad cache → delete and retry from network once
      if (cachedFile != null) {
        try {
          await cachedFile.delete();
        } catch (_) {}
        try {
          _controller?.dispose();
          _controller =
              VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
          await _controller!.initialize();
          if (mounted) {
            setState(() => _isInitialized = true);
            if (widget.autoPlay) {
              _controller!.play();
              setState(() => _isPlaying = true);
              _previewTimer = Timer(widget.previewDuration, () {
                if (mounted) {
                  _controller!.pause();
                  setState(() {
                    _isPlaying = false;
                    _showPayButton = true;
                  });
                }
              });
            }
            _controller!.addListener(_onVideoPositionChanged);
          }
          return;
        } catch (retryError) {
          print('[CachedVideo] Network retry failed: $retryError');
        }
      }
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _hasError = true;
          _errorMessage = 'Failed to load video';
        });
      }
    }
  }

  void _onVideoPositionChanged() {
    if (_controller != null && _controller!.value.isInitialized) {
      final position = _controller!.value.position;
      
      // Check if video is completed
      if (_controller!.value.isCompleted) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isCompleted = true;
          });
        }
        return;
      }
      
      // Check if preview duration is reached
      if (position >= widget.previewDuration) {
        print('[CachedVideo] Position ${position.inSeconds}s reached preview duration ${widget.previewDuration.inSeconds}s');
        _controller!.pause();
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _showPayButton = true;
          });
          print('[CachedVideo] _showPayButton set to true from position listener');
          // Don't auto-trigger popup, let user click Purchase Now button
        }
      }
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    
    if (_isCompleted) {
      // Replay from beginning
      _controller!.seekTo(Duration.zero);
      _controller!.play();
      setState(() {
        _isCompleted = false;
        _isPlaying = true;
        _showPayButton = false;
      });
      return;
    }
    
    if (_isPlaying) {
      _controller!.pause();
    } else {
      // Don't allow playing beyond preview duration without payment
      if (_controller!.value.position < widget.previewDuration) {
        _controller!.play();
      } else {
        // Show pay button or message
        setState(() {
          _showPayButton = true;
        });
        return;
      }
    }
    
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Loading state or video player
        if (_isDownloading && !_isInitialized)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Caching video... ${(_downloadProgress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (!_isInitialized && !_hasError)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          )
        else if (!_isInitialized && _hasError)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _errorMessage = '';
                      });
                      _initializeVideo();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else
          // Video Player
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),

        
        // Download progress indicator (always show when downloading)
        if (_isDownloading)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Downloading... ${(_downloadProgress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        
        // Cached indicator and Share button
        if (_cachedFile != null && !_isDownloading)
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cached indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_done, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Downloaded',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Share button
                GestureDetector(
                  onTap: () async {
                    try {
                      await Share.shareXFiles(
                        [XFile(_cachedFile!.path)],
                        text: 'Share video file',
                        subject: 'Video Download',
                      );
                    } catch (e) {
                      Get.snackbar('Error', 'Could not share file: $e');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.share, size: 14, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'Share',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Preview Timer Indicator
        if (_isPlaying && !_showPayButton)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller!,
                builder: (context, value, child) {
                  final remaining = widget.previewDuration - value.position;
                  final seconds = remaining.inSeconds.clamp(0, widget.previewDuration.inSeconds);
                  return Text(
                    'Preview: ${seconds}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          ),
        
        // Play/Pause Button (always visible)
        Positioned.fill(
          child: GestureDetector(
            onTap: _isInitialized ? _togglePlayPause : () {
              // Try to initialize if not initialized
              if (!_isInitialized) {
                _initializeVideo();
              }
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Pay Button Overlay
        if (_showPayButton)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Preview Ended',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Purchase to watch full video',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Replay Preview Button
                        OutlinedButton.icon(
                          onPressed: () async {
                            // Reset and replay preview
                            await _controller?.seekTo(Duration.zero);
                            if (mounted) {
                              setState(() {
                                _showPayButton = false;
                                _isCompleted = false;
                              });
                              _controller!.play();
                            }
                          },
                          icon: const Icon(Icons.replay, size: 18),
                          label: const Text('Replay'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Pay with Stripe - Unlock Download Button
                        ElevatedButton(
                          onPressed: () {
                            // Trigger onPreviewEnd callback to show purchase dialog
                            widget.onPreviewEnd?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Pay with Stripe - Unlock Download',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  ],
                ),
              ]),
            ),
          ),
    )],
    );
  }
}
