import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../utils/app_colors.dart';

/// Enhanced Video Widget with comprehensive play/pause/replay functionality
/// Designed specifically for video content with professional UI controls
class EnhancedVideoWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback? onVideoEnd;
  final bool autoPlay;
  final bool showControls;
  final bool allowFullscreen;
  final String? title;

  const EnhancedVideoWidget({
    Key? key,
    required this.videoUrl,
    this.onVideoEnd,
    this.autoPlay = false,
    this.showControls = true,
    this.allowFullscreen = true,
    this.title,
  }) : super(key: key);

  @override
  State<EnhancedVideoWidget> createState() => _EnhancedVideoWidgetState();
}

class _EnhancedVideoWidgetState extends State<EnhancedVideoWidget>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isCompleted = false;
  bool _showControlsOverlay = true;
  bool _isLoading = true;
  String? _error;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Timer? _controlsTimer;
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
    _startPositionTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlsTimer?.cancel();
    _positionTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (_isPlaying && _controller != null) {
        _controller!.pause();
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  void _startPositionTimer() {
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_controller != null && _controller!.value.isInitialized && mounted) {
        setState(() {
          _currentPosition = _controller!.value.position;
          _isPlaying = _controller!.value.isPlaying;
        });
        
        // Check for video completion
        if (_controller!.value.isCompleted && !_isCompleted) {
          setState(() {
            _isCompleted = true;
            _isPlaying = false;
          });
          widget.onVideoEnd?.call();
        }
      }
    });
  }

  void _startControlsTimer() {
    if (!widget.showControls) return;
    
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControlsOverlay = false;
        });
      }
    });
  }

  void _toggleControls() {
    if (!widget.showControls) return;
    
    setState(() {
      _showControlsOverlay = !_showControlsOverlay;
    });
    if (_showControlsOverlay) {
      _startControlsTimer();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      
      // Add error listener
      _controller!.addListener(() {
        if (_controller!.value.hasError) {
          setState(() {
            _error = _controller!.value.errorDescription ?? 'Unknown error occurred';
            _isLoading = false;
          });
        }
      });

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
          _totalDuration = _controller!.value.duration;
        });

        if (widget.autoPlay) {
          _controller!.play();
          setState(() {
            _isPlaying = true;
          });
          _startControlsTimer();
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load video: $e';
        _isLoading = false;
      });
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
      });
      _startControlsTimer();
      return;
    }
    
    if (_isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
      _startControlsTimer();
    }
    
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _replayVideo() {
    if (_controller == null || !_isInitialized) return;
    
    _controller!.seekTo(Duration.zero);
    _controller!.play();
    setState(() {
      _isCompleted = false;
      _isPlaying = true;
    });
    _startControlsTimer();
  }

  void _seekTo(Duration position) async {
    if (_controller != null) {
      await _controller!.seekTo(position);
      if (position == Duration.zero && _isCompleted) {
        setState(() {
          _isCompleted = false;
        });
      }
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
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Video Player
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          else if (_error != null)
            _buildErrorWidget()
          else if (_isInitialized)
            _buildVideoPlayer()
          else
            const Center(
              child: Icon(
                Icons.videocam_off,
                color: Colors.white54,
                size: 64,
              ),
            ),

          // Video Controls Overlay
          if (_isInitialized && widget.showControls && _showControlsOverlay)
            _buildControlsOverlay(),

          // Center Play/Pause/Replay Button
          if (_isInitialized)
            _buildCenterButton(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _initializeVideo,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                _isCompleted 
                    ? Icons.replay 
                    : (_isPlaying ? Icons.pause : Icons.play_arrow),
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
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
          // Top Bar with Title
          if (widget.title != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.allowFullscreen)
                      IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                        onPressed: () {
                          // TODO: Implement fullscreen functionality
                        },
                      ),
                  ],
                ),
              ),
            ),

          const Spacer(),

          // Bottom Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Progress Bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
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

                // Time and Control Buttons
                Row(
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    
                    // Replay Button
                    IconButton(
                      icon: const Icon(Icons.replay, color: Colors.white),
                      onPressed: _replayVideo,
                      tooltip: 'Replay',
                    ),
                    
                    // Skip Backward 10 seconds
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      onPressed: () {
                        final newPosition = _currentPosition - const Duration(seconds: 10);
                        _seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);
                      },
                      tooltip: 'Skip -10s',
                    ),
                    
                    // Skip Forward 10 seconds
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: () {
                        final newPosition = _currentPosition + const Duration(seconds: 10);
                        _seekTo(newPosition < _totalDuration ? newPosition : _totalDuration);
                      },
                      tooltip: 'Skip +10s',
                    ),
                    
                    const Spacer(),
                    Text(
                      _formatDuration(_totalDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on double {
  double max(double other) => this > other ? this : other;
}
