import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../utils/app_colors.dart';

class VideoPreviewWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onPreviewEnd;
  final bool autoPlay;
  final Duration previewDuration;

  const VideoPreviewWidget({
    Key? key,
    required this.videoUrl,
    this.onPreviewEnd,
    this.autoPlay = true,
    this.previewDuration = const Duration(seconds: 12),
  }) : super(key: key);

  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isCompleted = false;
  bool _showPayButton = false;
  Timer? _previewTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _previewTimer?.cancel();
    _controller?.dispose();
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

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();
      
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
              _controller!.pause();
              setState(() {
                _isPlaying = false;
                _showPayButton = true;
              });
              widget.onPreviewEnd?.call();
            }
          });
        }

        // Listen to video position changes
        _controller!.addListener(_onVideoPositionChanged);
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
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
        _controller!.pause();
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _showPayButton = true;
          });
          widget.onPreviewEnd?.call();
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
    if (!_isInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Stack(
      children: [
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
        
        // Play/Pause Button (always visible on top)
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
        
        // Dedicated Replay Button (bottom right)
        if (_isCompleted || _controller!.value.position > Duration.zero)
          Positioned(
            bottom: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _controller?.seekTo(Duration.zero);
                if (mounted) {
                  setState(() {
                    _isCompleted = false;
                  });
                  _controller!.play();
                }
              },
              icon: const Icon(Icons.replay, size: 22),
              label: const Text('Replay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
                        // Purchase Now Button
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to purchase or show payment dialog
                            Get.snackbar(
                              'Purchase Required',
                              'Please purchase this product to watch the full video',
                              backgroundColor: Colors.orange,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 3),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
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
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
