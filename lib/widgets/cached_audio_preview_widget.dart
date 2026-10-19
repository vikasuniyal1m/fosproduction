import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:ecommerceapp/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/media_preview_pool.dart';

class CachedAudioPreviewWidget extends StatefulWidget {
  final String audioUrl;
  final VoidCallback? onPreviewEnd;
  final bool autoPlay;
  final Duration previewDuration;
  final bool isPurchased;
  final String? productImageUrl;

  const CachedAudioPreviewWidget({
    Key? key,
    required this.audioUrl,
    this.onPreviewEnd,
    this.autoPlay = true,
    this.previewDuration = const Duration(seconds: 12),
    this.isPurchased = false,
    this.productImageUrl,
  }) : super(key: key);

  @override
  State<CachedAudioPreviewWidget> createState() => _CachedAudioPreviewWidgetState();
}

class _CachedAudioPreviewWidgetState extends State<CachedAudioPreviewWidget>
    with WidgetsBindingObserver {
  AudioPlayer? _audioPlayer;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showPayButton = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  Timer? _previewTimer;
  File? _cachedFile;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preloadImage();
    _initializeAudio();
  }

  /// Preload the product image before showing the UI
  Future<void> _preloadImage() async {
    if (widget.productImageUrl != null && widget.productImageUrl!.isNotEmpty) {
      try {
        final imageProvider = CachedNetworkImageProvider(widget.productImageUrl!);
        await precacheImage(imageProvider, context);
        if (mounted) {
          setState(() {
            _isImageLoaded = true;
          });
        }
      } catch (e) {
        print('[CachedAudio] Error preloading image: $e');
        if (mounted) {
          setState(() {
            _isImageLoaded = true; // Show UI anyway even if preload fails
          });
        }
      }
    } else {
      // No image to preload, mark as loaded
      if (mounted) {
        setState(() {
          _isImageLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _previewTimer?.cancel();
    if (_audioPlayer != null) {
      MediaPreviewPool.instance.releaseAudio(widget.audioUrl);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App going to background - pause audio
      if (_isPlaying && _audioPlayer != null) {
        _pauseAudio();
      }
    }
  }

  /// Generate a unique filename for the audio URL
  String _generateFileName(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return 'audio_${digest.toString().substring(0, 16)}.mp3';
  }

  /// Get the cached audio file path
  Future<File?> _getCachedAudioFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/cached_audio');
      
      // Create directory if it doesn't exist
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      final fileName = _generateFileName(widget.audioUrl);
      final file = File('${audioDir.path}/$fileName');
      
      if (await file.exists()) {
        print('[CachedAudio] Found cached file: ${file.path}');
        return file;
      }
      
      return null;
    } catch (e) {
      print('[CachedAudio] Error getting cached file: $e');
      return null;
    }
  }

  /// Download and cache the audio
  Future<File?> _downloadAndCacheAudio() async {
    try {
      final existing =
          await MediaPreviewPool.instance.cachedAudioFile(widget.audioUrl);
      if (existing != null) {
        _cachedFile = existing;
        return existing;
      }

      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/cached_audio');
      
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      final fileName = _generateFileName(widget.audioUrl);
      final file = File('${audioDir.path}/$fileName');
      
      final dio = Dio();
      
      await dio.download(
        widget.audioUrl,
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
            'Accept': 'audio/mp3,audio/*',
          },
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      print('[CachedAudio] Audio downloaded and cached: ${file.path}');
      setState(() {
        _isDownloading = false;
        _cachedFile = file;
      });
      
      return file;
    } catch (e) {
      print('[CachedAudio] Error downloading audio: $e');
      setState(() {
        _isDownloading = false;
      });
      return null;
    }
  }

  /// Initialize audio player with caching
  Future<void> _initializeAudio() async {
    try {
      print('[CachedAudio] Initializing audio player...');
      print('[CachedAudio] Audio URL: ${widget.audioUrl}');
      print('[CachedAudio] Is purchased: ${widget.isPurchased}');
      print('[CachedAudio] Auto play: ${widget.autoPlay}');

      final cachedFile = await _getCachedAudioFile();
      _audioPlayer =
          await MediaPreviewPool.instance.acquireAudio(widget.audioUrl);
      if (cachedFile != null) {
        print('[CachedAudio] Using pooled/cached audio: ${cachedFile.path}');
      } else {
        _downloadAndCacheAudio();
        print('[CachedAudio] Pool init + background cache');
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        print('[CachedAudio] Audio player initialized successfully');

        // Listen to position changes
        _audioPlayer!.positionStream.listen((position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
            });

            // Check if preview duration is reached (only if not purchased)
            if (!widget.isPurchased && position >= widget.previewDuration) {
              _pauseAudio();
              if (mounted) {
                setState(() {
                  _showPayButton = true;
                });
                // Don't auto-trigger popup, let user click Purchase Now button
              }
            }
          }
        });

        // Listen to duration changes
        _audioPlayer!.durationStream.listen((duration) {
          if (mounted && duration != null) {
            setState(() {
              _totalDuration = duration;
            });
            print('[CachedAudio] Duration: $duration');
          }
        });

        // Listen to player state changes
        _audioPlayer!.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state.playing;
            });
            print('[CachedAudio] Player state: ${state.playing}');
          }
        });

        if (widget.autoPlay) {
          print('[CachedAudio] Auto-playing audio');
          _playAudio();
        }
      }
    } catch (e) {
      print('[CachedAudio] Error initializing audio: $e');
      print('[CachedAudio] Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  void _playAudio() async {
    if (_audioPlayer == null || !_isInitialized) return;
    
    // If purchased, allow full playback without restrictions
    if (widget.isPurchased) {
      await _audioPlayer!.play();
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
      return;
    }
    
    // For non-purchased: Don't allow playing beyond preview duration
    if (_currentPosition < widget.previewDuration) {
      await _audioPlayer!.play();
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
      
      // Start preview timer
      _previewTimer?.cancel();
      _previewTimer = Timer(widget.previewDuration - _currentPosition, () {
        if (mounted) {
          _pauseAudio();
          setState(() {
            _showPayButton = true;
          });
          // Don't auto-trigger popup, let user click Purchase Now button
        }
      });
    } else {
      // Show pay button
      setState(() {
        _showPayButton = true;
      });
    }
  }

  void _pauseAudio() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.pause();
      _previewTimer?.cancel();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseAudio();
    } else {
      _playAudio();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isDownloading && !_isInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFFFFF).withOpacity(0.8),
              const Color(0xFFFFFFFF).withOpacity(0.6),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'Caching audio... ${(_downloadProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFFFFF).withOpacity(0.8),
              const Color(0xFFFFFFFF).withOpacity(0.6),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Background: Product image if available, otherwise gradient
        if (widget.productImageUrl != null && widget.productImageUrl!.isNotEmpty)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.productImageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFFFFFF).withOpacity(0.8),
                      const Color(0xFFFFFFFF).withOpacity(0.6),
                    ],
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.withOpacity(0.8),
                      Colors.blue.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          // Background gradient for no image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFFFFF).withOpacity(0.8),
                  const Color(0xFFFFFFFF).withOpacity(0.6),
                ],
              ),
            ),
          ),

        // Dark overlay to make controls visible (always show when there's background image)
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.5),
        ),
        
        // Download progress indicator (when downloading after initial load)
        if (_isDownloading && _isInitialized)
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
              child: LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          ),
        
        // Share button (only show when cached and purchased)
        if (_cachedFile != null && !_isDownloading && widget.isPurchased)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () async {
                try {
                  await Share.shareXFiles(
                    [XFile(_cachedFile!.path)],
                    text: 'Share audio file',
                    subject: 'Audio Download',
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
          ),
        
        // Audio visualization and controls
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Audio icon with animation
              Flexible(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _isPlaying ? Icons.graphic_eq : Icons.audiotrack,
                    size: _isPlaying ? 72 : 60,
                    color: Colors.white.withOpacity(_isPlaying ? 1.0 : 0.8),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Progress bar
              if (_totalDuration > Duration.zero)
                Flexible(
                  child: Container(
                    width: 180,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withOpacity(0.3),
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withOpacity(0.2),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: _currentPosition.inMilliseconds.toDouble(),
                            max: _totalDuration.inMilliseconds.toDouble(),
                            onChanged: (value) {
                              // Allow seeking anywhere if purchased, otherwise only within preview duration
                              final newPosition = Duration(milliseconds: value.round());
                              if (widget.isPurchased || newPosition <= widget.previewDuration) {
                                _audioPlayer!.seek(newPosition);
                              }
                            },
                          ),
                        ),
                        SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDuration(_totalDuration),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              
              SizedBox(height: 12),

              // Play/Pause button
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 28,
                    color: const Color(0xFF1976D2),
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Preview timer
              if (_isPlaying && !_showPayButton)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Preview: ${widget.previewDuration.inSeconds - _currentPosition.inSeconds}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Pay Button Overlay (only show if not purchased)
        if (_showPayButton && !widget.isPurchased)
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
                      'Purchase to listen to full audio',
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
                            await _audioPlayer?.seek(Duration.zero);
                            if (mounted) {
                              setState(() {
                                _showPayButton = false;
                                _currentPosition = Duration.zero;
                              });
                              _playAudio();
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
                        // Purchase Now Button
                        ElevatedButton(
                          onPressed: () {
                            // Trigger onPreviewEnd callback to show purchase dialog
                            widget.onPreviewEnd?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Purchase Now',
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
