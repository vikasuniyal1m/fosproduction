import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../../controllers/profile_controller.dart';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';
import '../../services/enhanced_media_service.dart';

/// Full-screen professional audio player for purchased/downloaded audio
/// Features: play/pause, seek, repeat, share, background audio support
class FullAudioPlayerScreen extends StatefulWidget {
  final String audioUrl;
  final String filePath;
  final String productName;
  final String? productImageUrl;
  final int? orderItemId;

  const FullAudioPlayerScreen({
    super.key,
    required this.audioUrl,
    required this.filePath,
    required this.productName,
    this.productImageUrl,
    this.orderItemId,
  });

  @override
  State<FullAudioPlayerScreen> createState() => _FullAudioPlayerScreenState();
}

class _FullAudioPlayerScreenState extends State<FullAudioPlayerScreen>
    with WidgetsBindingObserver {
  AudioPlayer? _audioPlayer;
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
  final EnhancedMediaService _mediaService = EnhancedMediaService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAudio();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Continue playing in background - don't stop audio
    // Only pause if app is detached (killed)
    if (state == AppLifecycleState.detached) {
      _audioPlayer?.pause();
    }
  }

  Future<String> _resolvePlaybackUrl() async {
    var url = widget.audioUrl.trim();
    if (url.isEmpty && widget.orderItemId != null) {
      final profile = Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : Get.put(ProfileController());
      final info = await profile.getDigitalDownloadInfo(
        widget.orderItemId!,
        silent: true,
      );
      url = info?['download_url']?.toString() ?? '';
    }
    if (url.isEmpty) return '';
    final profile = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    return profile.withAuthToken(_fixAudioUrl(url));
  }

  Future<void> _initializeAudio() async {
    try {
      print('🎵 Starting audio initialization for: ${widget.productName}');

      final playbackUrl = await _resolvePlaybackUrl();
      if (playbackUrl.isEmpty) {
        throw Exception('Audio URL not available');
      }

      var localPath = await _mediaService.findCachedMediaPath(
        productName: widget.productName,
        mediaType: MediaType.audio,
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
          url: playbackUrl,
          productName: widget.productName,
          mediaType: MediaType.audio,
          orderItemId: widget.orderItemId,
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _isDownloading = true;
                _downloadProgress = progress;
              });
            }
          },
          onError: (error) {
            print('🎵 Audio download error: $error');
            if (mounted) {
              setState(() {
                _error = 'Download failed: $error';
                _isLoading = false;
                _isDownloading = false;
              });
            }
          },
        );
      }

      // Configure audio session for background playback
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);

      _audioPlayer = AudioPlayer();

      if (localPath != null) {
        // Successfully downloaded or found local file
        final file = File(localPath);
        if (await file.exists()) {
          print('🎵 Loading from local file: $localPath');
          await _audioPlayer!.setFilePath(localPath);
        } else {
          throw Exception('Local audio file not found after download');
        }
      } else {
        print('🎵 Fallback to network streaming: $playbackUrl');
        await _audioPlayer!.setUrl(playbackUrl);
      }

      // Add timeout for audio loading
      await _audioPlayer!.load().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Audio loading timeout. Please check your internet connection and try again.');
        },
      );

      // Listen to position changes
      _audioPlayer!.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      });

      // Listen to duration changes
      _audioPlayer!.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _totalDuration = duration;
          });
        }
      });

      // Listen to player state changes
      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });

      // Listen for completion to handle repeat
      _audioPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (_isRepeatMode) {
            _audioPlayer!.seek(Duration.zero);
            _audioPlayer!.play();
          } else {
            setState(() {
              _isPlaying = false;
              _isCompleted = true;
            });
          }
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
          _isDownloading = false;
        });
        
        // Auto-play after initialization
        print('🎵 Auto-playing audio after initialization');
        await _audioPlayer!.play();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Check for specific server content mismatch indicators
        if (errorMessage.contains('None of the available extractors') ||
            errorMessage.contains('could read the stream') ||
            errorMessage.contains('Source error') ||
            errorMessage.contains('file not supported for audio')) {
          
          // Check if product name suggests this should be audio
          if (widget.productName.toLowerCase().contains('audio') ||
              widget.productName.toLowerCase().contains('jingle') ||
              widget.productName.toLowerCase().contains('music')) {
            
            // Try to fix the server content mismatch by attempting direct download
            await _attemptServerContentFix();
            return; // Don't set error state if we're trying to fix it
          } else {
            errorMessage = 'File format not supported. This might not be an audio file.';
          }
        }
        
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
      print('[FullAudioPlayer] Error initializing: $e');
    }
  }

  void _playAudio() async {
    if (_audioPlayer == null || !_isInitialized) return;
    await _audioPlayer!.play();
  }

  void _pauseAudio() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.pause();
    }
  }

  void _togglePlayPause() {
    if (_isCompleted) {
      // Replay from beginning
      _audioPlayer!.seek(Duration.zero);
      _playAudio();
      setState(() {
        _isCompleted = false;
      });
    } else if (_isPlaying) {
      _pauseAudio();
    } else {
      _playAudio();
    }
  }

  void _seekTo(Duration position) async {
    if (_audioPlayer != null) {
      await _audioPlayer!.seek(position);
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

  void _shareAudio() async {
    try {
      final file = File(widget.filePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(widget.filePath)],
          text: '🎵 ${widget.productName}',
          subject: 'Audio from Fruits of Spirit',
        );
      } else {
        Get.snackbar(
          'Error',
          'Audio file not found',
          backgroundColor: AppColors.error,
          colorText: AppColors.textWhite,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not share audio: $e',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
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
  
  /// Attempt to fix server content mismatch by trying alternative approaches
  Future<void> _attemptServerContentFix() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = 'Detecting actual file content...';
      });
    }
    
    try {
      print('🔧 Attempting to fix server content mismatch for: ${widget.productName}');
      
      // Detect actual file type from URL
      String detectedFileType = await _detectActualFileType(widget.audioUrl);
      print('🔧 Detected file type: $detectedFileType');
      
      // Show user-friendly message about the issue with multiple options
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Server Content Issue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expected: Audio file',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              SizedBox(height: 8),
              Text(
                'Received: $detectedFileType',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
              ),
              SizedBox(height: 16),
              Text(
                'The server returned the wrong file type for your order. The file may have been misconfigured.',
                style: TextStyle(color: Colors.black54),
              ),
              SizedBox(height: 16),
              Text(
                'Product: ${widget.productName}',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Go Back'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                // Navigate to order details to check for correct file
                Get.toNamed('/orders');
              },
              child: Text('Check Order Details'),
            ),
          ],
        ),
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Server returned $detectedFileType instead of audio file. Please check your order details.';
        });
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to detect file type: $e\n\nPlease contact support with Product Name for assistance.';
          _isLoading = false;
        });
      }
    }
  }
  
  /// Detect actual file type by checking headers or extension
  Future<String> _detectActualFileType(String url) async {
    try {
      // First check from URL extension
      final uri = Uri.parse(url);
      String path = uri.path.toLowerCase();
      final queryIndex = path.indexOf('?');
      if (queryIndex != -1) {
        path = path.substring(0, queryIndex);
      }
      
      // Check for known file types in URL
      if (path.endsWith('.mp3') || url.toLowerCase().contains('audio')) {
        return 'Audio file (.mp3)';
      } else if (path.endsWith('.mp4') || url.toLowerCase().contains('video')) {
        return 'Video file (.mp4)';
      } else if (path.endsWith('.zip') || url.toLowerCase().contains('sticker')) {
        return 'Sticker/ZIP file (.zip)';
      }
      
      // Try to fetch headers to determine content type
      final headResponse = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );
      
      final contentType = headResponse.headers['content-type']?.toLowerCase() ?? '';
      final contentDisposition = headResponse.headers['content-disposition']?.toLowerCase() ?? '';
      
      // Check content disposition for filename
      if (contentDisposition.contains('.mp3') || contentDisposition.contains('audio')) {
        return 'Audio file (from headers)';
      } else if (contentDisposition.contains('.mp4') || contentDisposition.contains('video')) {
        return 'Video file (from headers)';
      } else if (contentDisposition.contains('.zip') || contentDisposition.contains('sticker')) {
        return 'Sticker/ZIP file (from headers)';
      }
      
      // Check content-type
      if (contentType.contains('audio') || contentType.contains('mpeg')) {
        return 'Audio file (Content-Type: $contentType)';
      } else if (contentType.contains('video') || contentType.contains('mp4')) {
        return 'Video file (Content-Type: $contentType)';
      } else if (contentType.contains('zip') || contentType.contains('application/octet-stream')) {
        return 'ZIP/Binary file (Content-Type: $contentType)';
      }
      
      // Check suggested filename from URL parameters
      if (url.toLowerCase().contains('digital_stickers.zip')) {
        return 'Sticker pack (digital_stickers.zip)';
      } else if (url.toLowerCase().contains('digital_audio_pack.zip')) {
        return 'Audio pack (digital_audio_pack.zip)';
      } else if (url.toLowerCase().contains('digital_video_pack.zip')) {
        return 'Video pack (digital_video_pack.zip)';
      }
      
      return 'Unknown file type';
    } catch (e) {
      print('Error detecting file type: $e');
      // Fallback to URL analysis
      final lowerUrl = url.toLowerCase();
      if (lowerUrl.contains('digital_stickers.zip')) return 'Sticker pack (.zip)';
      if (lowerUrl.contains('digital_audio')) return 'Audio pack';
      if (lowerUrl.contains('digital_video')) return 'Video pack';
      return 'Unknown (detection failed)';
    }
  }
  
  /// Validate if URL points to an audio file
  bool _isValidAudioFile(String url) {
    if (url.isEmpty) return false;
    
    try {
      final extension = _getFileExtension(url).toLowerCase();
      final audioExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.flac', '.ogg', '.wma', '.opus'];
      
      // Also check if URL contains audio-related keywords
      final hasAudioKeywords = url.toLowerCase().contains('audio') || 
                             url.toLowerCase().contains('music') ||
                             url.toLowerCase().contains('sound');
      
      // Allow PHP serving URLs (server-side file serving)
      final isPhpServingUrl = url.toLowerCase().contains('.php') && 
                              url.toLowerCase().contains('serve-digital-file');
      
      // Allow if it's a valid audio extension OR has audio keywords OR is a PHP serving URL
      return audioExtensions.contains(extension) || 
             hasAudioKeywords || 
             isPhpServingUrl;
    } catch (e) {
      print('Error validating audio file: $e');
      return false;
    }
  }
  
  /// Get file extension from URL
  String _getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      String path = uri.path.toLowerCase();
      
      // Handle URLs with query parameters
      final queryIndex = path.indexOf('?');
      if (queryIndex != -1) {
        path = path.substring(0, queryIndex);
      }
      
      // Extract extension
      final lastDotIndex = path.lastIndexOf('.');
      if (lastDotIndex != -1) {
        return path.substring(lastDotIndex);
      }
      
      return '.unknown';
    } catch (e) {
      return '.unknown';
    }
  }
  
  /// Fix common URL issues for audio files
  String _fixAudioUrl(String url) {
    if (url.isEmpty) return url;
    
    String fixedUrl = url;
    
    // Fix double slashes after protocol
    if (fixedUrl.contains('://')) {
      final protocolIndex = fixedUrl.indexOf('://');
      if (protocolIndex != -1) {
        final protocolEnd = protocolIndex + 3;
        final remaining = fixedUrl.substring(protocolEnd);
        // Replace multiple consecutive slashes with single slash
        final fixedRemaining = remaining.replaceAll(RegExp(r'/+'), '/');
        fixedUrl = fixedUrl.substring(0, protocolEnd) + fixedRemaining;
      }
    }
    
    // Fix missing slash after protocol
    if (fixedUrl.startsWith('http:/') && !fixedUrl.startsWith('http://')) {
      fixedUrl = fixedUrl.replaceFirst('http:/', 'http://');
    } else if (fixedUrl.startsWith('https:/') && !fixedUrl.startsWith('https://')) {
      fixedUrl = fixedUrl.replaceFirst('https:/', 'https://');
    }
    
    return fixedUrl;
  }
  
  /// Get user-friendly error message
  String _getErrorMessage(String error) {
    if (error.contains('Invalid audio file type')) {
      return 'Invalid File Type';
    } else if (error.contains('Source error')) {
      return 'Audio File Not Supported';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Network Connection Error';
    } else if (error.contains('timeout')) {
      return 'Loading Timeout';
    } else if (error.contains('Could not load audio')) {
      return 'Audio Loading Failed';
    } else if (error.contains('digital_stickers.zip')) {
      return 'Server returned sticker file instead of audio';
    } else if (error.contains('Server returned') && error.contains('instead of audio')) {
      return error; // Return the dynamic error message as-is
    }
    return 'Error Loading Audio';
  }
  
  /// Check if error is related to file type
  bool _isFileTypeError(String error) {
    return error.contains('Invalid audio file type') || 
           error.contains('digital_stickers.zip') ||
           error.contains('.zip') ||
           error.contains('None of the available extractors') ||
           error.contains('Server returned') ||
           error.contains('instead of audio');
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textWhite),
            onPressed: _shareAudio,
          ),
        ],
      ),
      body: _isLoading || _isDownloading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isDownloading) ...[
                    const CircularProgressIndicator(color: AppColors.textWhite),
                    const SizedBox(height: 16),
                    Text(
                      'Downloading audio... ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: AppColors.textWhite, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.productName,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    const CircularProgressIndicator(color: AppColors.textWhite),
                    const SizedBox(height: 16),
                    Text(
                      'Loading audio...',
                      style: const TextStyle(color: AppColors.textWhite, fontSize: 16),
                    ),
                  ],
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: AppColors.textWhite),
                        const SizedBox(height: 16),
                        Text(
                          _getErrorMessage(_error!),
                          style: const TextStyle(color: AppColors.textWhite, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (_isFileTypeError(_error!))
                          Column(
                            children: [
                              const Text(
                                'This appears to be a sticker pack or other file type.',
                                style: TextStyle(color: AppColors.textWhite, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              if (_error!.contains('digital_stickers.zip')) ...[
                                const Text(
                                  'Server returned sticker file instead of audio.',
                                  style: TextStyle(color: Colors.orange, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Please contact support or check your order details.',
                                  style: TextStyle(color: AppColors.textWhite, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ] else ...[
                                const Text(
                                  'Please check your order for the correct audio file.',
                                  style: TextStyle(color: AppColors.textWhite, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Go Back'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildPlayerUI(),
    );
  }

  Widget _buildPlayerUI() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Album Art / Product Image
          Container(
            width: ScreenSize.widthPercent(70),
            height: ScreenSize.widthPercent(70),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textBlack.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: widget.productImageUrl != null && widget.productImageUrl!.isNotEmpty
                  ? Image.network(
                      widget.productImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultAlbumArt(),
                    )
                  : _buildDefaultAlbumArt(),
            ),
          ),

          SizedBox(height: ScreenSize.spacingExtraLarge * 1.5),

          // Product Name
          Text(
            widget.productName,
            style: TextStyle(
              fontSize: ScreenSize.textLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: ScreenSize.spacingSmall),

          // Subtitle
          Text(
            'Fruits of Spirit',
            style: TextStyle(
              fontSize: ScreenSize.textMedium,
              color: Colors.white.withOpacity(0.6),
            ),
          ),

          SizedBox(height: ScreenSize.spacingExtraLarge * 1.5),

          // Progress Slider
          SliderTheme(
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
              },
            ),
          ),

          // Time Labels
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ScreenSize.spacingSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    color: AppColors.textWhite.withOpacity(0.7),
                  ),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: TextStyle(
                    fontSize: ScreenSize.textSmall,
                    color: AppColors.textWhite.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: ScreenSize.spacingExtraLarge),

          // Controls Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Repeat Button
                IconButton(
                  icon: Icon(
                    _isRepeatMode ? Icons.repeat_one : Icons.repeat,
                    color: _isRepeatMode ? AppColors.primary : Colors.white.withOpacity(0.7),
                    size: 24, // Reduced size
                  ),
                  onPressed: _toggleRepeat,
                ),

                SizedBox(width: ScreenSize.spacingSmall),

                // Previous / Skip Back
                IconButton(
                  icon: Icon(
                    Icons.skip_previous,
                    color: AppColors.textWhite.withOpacity(0.7),
                    size: 32, // Reduced size
                  ),
                  onPressed: () => _seekTo(Duration.zero),
                ),

                SizedBox(width: ScreenSize.spacingSmall),

                // Play/Pause Button
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 64, // Reduced size
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isCompleted ? Icons.replay : (_isPlaying ? Icons.pause : Icons.play_arrow),
                      color: AppColors.textWhite,
                      size: 32, // Reduced size
                    ),
                  ),
                ),

                SizedBox(width: ScreenSize.spacingSmall),

                // Next / Skip Forward
                IconButton(
                  icon: Icon(
                    Icons.skip_next,
                    color: AppColors.textWhite.withOpacity(0.7),
                    size: 32, // Reduced size
                  ),
                  onPressed: () => _seekTo(_totalDuration),
                ),

                SizedBox(width: ScreenSize.spacingSmall),

              // Share Button
              IconButton(
                icon: Icon(
                  Icons.share,
                  color: AppColors.textWhite.withOpacity(0.7),
                  size: 28,
                ),
                onPressed: _shareAudio,
              ),
            ],
            ),
          ),

          const Spacer(),

          // Downloaded indicator
          Container(
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
                    fontSize: ScreenSize.textSmall,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: ScreenSize.spacingLarge),
        ],
      ),
    );
  }

  Widget _buildDefaultAlbumArt() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.8),
            Colors.purple.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 80,
          color: AppColors.textWhite.withOpacity(0.8),
        ),
      ),
    );
  }
}

extension on double {
  double max(double other) => this > other ? this : other;
}
