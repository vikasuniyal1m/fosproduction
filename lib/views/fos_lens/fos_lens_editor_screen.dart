import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../constants/fos_lens_stickers.dart';
import '../../controllers/stripe_payment_controller.dart';
import '../../data/bible_quotes.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';
import '../../utils/cache_manager.dart';
import '../../utils/screen_size.dart';

const double _kFosLensExportPrice = 0.99;

/// Full-frame dimming when at least one quote is on the canvas (improves text contrast).
const double _kQuoteImageDimOpacity = 0.34;

/// Slightly stronger dim on PNG export (no per-quote rounded box behind text).
const double _kQuoteImageDimOpacityExport = 0.42;

class FosLensImageFilterPreset {
  const FosLensImageFilterPreset(this.label, this.matrix);

  final String label;
  /// 4×5 color matrix for [ColorFilter.matrix].
  final List<double> matrix;
}

/// Image color presets for FOS Lens (identity + common looks).
const List<FosLensImageFilterPreset> kFosLensImageFilterPresets = [
  FosLensImageFilterPreset('Original', [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  FosLensImageFilterPreset('B&W', [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  FosLensImageFilterPreset('Sepia', [
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  FosLensImageFilterPreset('Cool', [
    0.85, 0.1, 0.1, 0, 0,
    0.1, 0.9, 0.1, 0, 0,
    0.1, 0.2, 1.15, 0, 12,
    0, 0, 0, 1, 0,
  ]),
  FosLensImageFilterPreset('Warm', [
    1.15, 0.08, 0, 0, 8,
    0.05, 1.05, 0, 0, 4,
    0, 0.05, 0.9, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  FosLensImageFilterPreset('Soft', [
    1.05, 0.12, 0.12, 0, -8,
    0.12, 1.05, 0.12, 0, -8,
    0.12, 0.12, 1.05, 0, -8,
    0, 0, 0, 1, 0,
  ]),
  FosLensImageFilterPreset('Vivid', [
    1.25, -0.1, -0.1, 0, 0,
    -0.1, 1.25, -0.1, 0, 0,
    -0.1, -0.1, 1.25, 0, 0,
    0, 0, 0, 1, 0,
  ]),
];

/// Preset font families (Google Fonts + system).
const List<String> kFosLensFontLabels = [
  'System',
  'Lato',
  'Merriweather',
  'Playfair Display',
  'Oswald',
  'Roboto Mono',
];

TextStyle _applyQuoteFontPreset(int preset, TextStyle base) {
  switch (preset.clamp(0, kFosLensFontLabels.length - 1)) {
    case 1:
      return GoogleFonts.lato(textStyle: base);
    case 2:
      return GoogleFonts.merriweather(textStyle: base);
    case 3:
      return GoogleFonts.playfairDisplay(textStyle: base);
    case 4:
      return GoogleFonts.oswald(textStyle: base);
    case 5:
      return GoogleFonts.robotoMono(textStyle: base);
    default:
      return base;
  }
}

class _FosLensStickerItem {
  const _FosLensStickerItem({
    required this.id,
    required this.imageUrl,
    required this.emojiCode,
  });

  final int id;
  final String imageUrl;
  final String emojiCode;

  static _FosLensStickerItem? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final imageUrl = json['image_url'];
    final emojiCode = json['emoji_code'];
    if (id is! int || imageUrl is! String || imageUrl.isEmpty) return null;
    return _FosLensStickerItem(
      id: id,
      imageUrl: imageUrl,
      emojiCode: emojiCode is String ? emojiCode : '',
    );
  }
}

class _LensOverlay {
  _LensOverlay({
    required this.id,
    required this.isQuote,
    this.text,
    this.stickerPath,
    this.isNetworkSticker = false,
    this.x = 32,
    this.y = 100,
    this.scale = 1.0,
  });

  final String id;
  final bool isQuote;
  final String? text;
  final String? stickerPath;
  final bool isNetworkSticker;
  double x;
  double y;
  double scale;

  Color quoteColor = Colors.white;
  double quoteFontSize = 16;
  FontWeight quoteFontWeight = FontWeight.w600;
  FontStyle quoteFontStyle = FontStyle.normal;
  int quoteFontPreset = 0;

  /// Overlay scale at the start of the current pointer-count segment (Flutter's [ScaleUpdateDetails.scale] is
  /// cumulative from the whole gesture, so we must pair it with [_segmentGestureScale] from the same segment).
  double _segmentOverlayScale = 1;
  /// [ScaleUpdateDetails.scale] at the start of the current segment (rebased when pointer count changes).
  double _segmentGestureScale = 1;
  double _baseX = 0;
  double _baseY = 0;
  Offset _baseFocalPoint = Offset.zero;
  Offset _baseLocalFocalPoint = Offset.zero;
  /// -1 forces a segment rebase on the first [onScaleUpdate] after [onScaleStart].
  int _activePointerCount = -1;

  void onScaleStart(ScaleStartDetails d) {
    _baseX = x;
    _baseY = y;
    _baseFocalPoint = d.focalPoint;
    _baseLocalFocalPoint = d.focalPoint - Offset(x, y);
    _activePointerCount = -1;
  }

  void onScaleUpdate(ScaleUpdateDetails d) {
    // Rebase whenever finger count changes (or on first update): [d.scale] stays cumulative from gesture start.
    if (_activePointerCount != d.pointerCount) {
      _segmentOverlayScale = scale;
      _segmentGestureScale = d.scale;
      _baseX = x;
      _baseY = y;
      _baseFocalPoint = d.focalPoint;
      _baseLocalFocalPoint = d.focalPoint - Offset(x, y);
      _activePointerCount = d.pointerCount;
    }

    if (d.pointerCount >= 2) {
      final nextScale =
          (_segmentOverlayScale * (d.scale / _segmentGestureScale)).clamp(0.35, 4.5);
      final ratio = nextScale / _segmentOverlayScale;
      scale = nextScale;
      x = d.focalPoint.dx - (_baseLocalFocalPoint.dx * ratio);
      y = d.focalPoint.dy - (_baseLocalFocalPoint.dy * ratio);
      return;
    }

    final delta = d.focalPoint - _baseFocalPoint;
    x = _baseX + delta.dx;
    y = _baseY + delta.dy;
  }

  void onScaleEnd() {
    _activePointerCount = -1;
  }

  TextStyle baseQuoteTextStyle({required bool forExport}) {
    final base = TextStyle(
      color: quoteColor,
      fontSize: quoteFontSize,
      fontWeight: quoteFontWeight,
      fontStyle: quoteFontStyle,
      decoration: TextDecoration.none,
      letterSpacing: 0,
      height: 1.35,
      shadows: forExport
          ? [
              Shadow(
                color: Colors.black.withOpacity(0.65),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
              Shadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 2,
                offset: const Offset(0, 0),
              ),
            ]
          : null,
    );
    return _applyQuoteFontPreset(quoteFontPreset, base);
  }
}

/// Image editor: Bible quotes + stickers, paid export to gallery.
class FosLensEditorScreen extends StatefulWidget {
  const FosLensEditorScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<FosLensEditorScreen> createState() => _FosLensEditorScreenState();
}

class _FosLensEditorScreenState extends State<FosLensEditorScreen> {
  static const String _bibleLensStickersApiUrl =
      'https://admin.fosproductions.org/api/stickers/bible-lens-stickers.php';

  final GlobalKey _repaintKey = GlobalKey();
  final List<_LensOverlay> _overlays = [];
  final List<String> _quoteOptions = [];
  final List<_FosLensStickerItem> _apiStickers = [];
  int _idSeq = 0;
  double? _aspectRatio;
  Size? _canvasSize;
  bool _decoding = true;
  bool _saving = false;
  /// When true, quote stickers and handles are drawn as for final PNG (no edit chrome).
  bool _isCapturingForExport = false;
  int _imageFilterIndex = 0;
  bool _isLoadingStickers = false;
  String? _stickerLoadError;
  bool _isLoadingQuotes = false;
  String? _quoteLoadError;

  bool get _hasAnyQuoteOverlay => _overlays.any((e) => e.isQuote);

  @override
  void initState() {
    super.initState();
    _loadAspect();
    _loadApiStickers();
    _loadQuotesFromJson();
  }

  Future<void> _loadAspect() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width.toDouble();
      final h = frame.image.height.toDouble();
      frame.image.dispose();
      if (mounted) {
        setState(() {
          _aspectRatio = w / h;
          _decoding = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aspectRatio = 1;
          _decoding = false;
        });
      }
    }
  }

  String _nextId() => 'ov_${_idSeq++}';

  bool get _hasUnsavedEdits => _overlays.isNotEmpty;

  Future<bool> _confirmExitIfNeeded() async {
    if (!_hasUnsavedEdits) return true;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit FOS Lens?'),
        content: const Text('Are you sure to exit? All changes will be discarded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldExit == true;
  }

  void _clampOverlayInBounds(_LensOverlay o) {
    final size = _canvasSize;
    if (size == null) return;

    const margin = 8.0;
    final maxScale = _maxOverlayScaleForCanvas(o, size);
    final minScale = 0.35;
    o.scale = o.scale.clamp(minScale, maxScale);

    // Keep overlays fully inside image bounds.
    final paintSize = _overlayPaintSize(o, size, scaleOverride: o.scale);
    final width = paintSize.width;
    final height = paintSize.height;

    final minX = margin;
    final minY = margin;
    final maxX = math.max(margin, size.width - width - margin);
    final maxY = math.max(margin, size.height - height - margin);

    o.x = o.x.clamp(minX, maxX);
    o.y = o.y.clamp(minY, maxY);
  }

  double _maxOverlayScaleForCanvas(_LensOverlay o, Size canvasSize) {
    const hardCap = 4.5;
    const margin = 8.0;
    final safeW = math.max(1.0, canvasSize.width - (margin * 2));
    final safeH = math.max(1.0, canvasSize.height - (margin * 2));

    if (!o.isQuote) {
      final baseSize = _overlayPaintSize(o, canvasSize, scaleOverride: 1.0);
      final maxByWidth = safeW / math.max(1.0, baseSize.width);
      final maxByHeight = safeH / math.max(1.0, baseSize.height);
      return math.max(0.35, math.min(hardCap, math.min(maxByWidth, maxByHeight)));
    }

    // Quote size is nonlinear with scale (it re-wraps into new lines). Use binary search
    // against measured paint size so zoom stops exactly before clipping.
    var lo = 0.35;
    var hi = hardCap;
    for (var i = 0; i < 20; i++) {
      final mid = (lo + hi) / 2;
      final size = _overlayPaintSize(o, canvasSize, scaleOverride: mid);
      final fits = size.width <= safeW && size.height <= safeH;
      if (fits) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo.clamp(0.35, hardCap);
  }

  /// Same rule as [_maxQuoteBoxLayoutWidth] but with an explicit [scale] for measuring
  /// (must match [Transform.scale] on the overlay).
  double _maxQuoteBoxLayoutWidthAtScale(_LensOverlay o, double canvasW, double scale) {
    final s = scale.clamp(0.35, 4.5);
    // Keep quote width independent of current x; position clamping handles staying onscreen.
    final canvasBound = math.max(48.0, (canvasW - 16.0) / s);
    final capScreen = MediaQuery.sizeOf(context).width * 0.72 / s;
    final w = math.min(capScreen, canvasBound);
    return w.clamp(48.0, canvasW);
  }

  Size _overlayPaintSize(
    _LensOverlay o,
    Size canvasSize, {
    double? scaleOverride,
  }) {
    final s = (scaleOverride ?? o.scale).clamp(0.35, 4.5);
    if (!o.isQuote) {
      return Size(96 * s, 96 * s);
    }

    final isEdit = _editChromeVisible;
    final horizontalPad = isEdit ? 24.0 : 12.0;
    final verticalPad = isEdit ? 20.0 : 8.0;

    // Match on-screen layout: container max width × text max width (padding), per scale.
    final containerMaxW = _maxQuoteBoxLayoutWidthAtScale(o, canvasSize.width, s);
    final textMaxW = math.max(12.0, containerMaxW - horizontalPad);

    final textStyle = o.baseQuoteTextStyle(forExport: _isCapturingForExport);
    final painter = TextPainter(
      text: TextSpan(text: o.text ?? '', style: textStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: textMaxW);

    final baseW = painter.width + horizontalPad;
    final baseH = painter.height + verticalPad;
    return Size(baseW * s, baseH * s);
  }

  Future<void> _loadApiStickers() async {
    if (_isLoadingStickers) return;
    setState(() {
      _isLoadingStickers = true;
      _stickerLoadError = null;
    });

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
      ),
    );
    final fetched = <_FosLensStickerItem>[];
    var page = 1;
    var hasNext = true;

    try {
      while (hasNext && page <= 20) {
        final res = await dio.get<Map<String, dynamic>>(
          _bibleLensStickersApiUrl,
          queryParameters: {'page': page, 'per_page': 50},
        );
        final root = res.data ?? const <String, dynamic>{};
        final data = root['data'];
        if (data is! Map<String, dynamic>) break;

        final stickers = data['stickers'];
        if (stickers is List) {
          for (final entry in stickers) {
            if (entry is! Map<String, dynamic>) continue;
            final parsed = _FosLensStickerItem.fromJson(entry);
            if (parsed != null) fetched.add(parsed);
          }
        }

        final pagination = data['pagination'];
        if (pagination is Map<String, dynamic>) {
          hasNext = pagination['has_next'] == true;
        } else {
          hasNext = false;
        }
        page++;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stickerLoadError = 'Could not load stickers. Showing local sticker pack.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _apiStickers
          ..clear()
          ..addAll(fetched);
        _isLoadingStickers = false;
      });
    }
  }

  String _stripHtmlTags(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String _decodeHtmlEntities(String input) {
    final decoded = input
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&ndash;', '-')
        .replaceAll('&mdash;', '-')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&#8217;', "'")
        .replaceAll('&#8211;', '-')
        .replaceAll('&#8212;', '-');
    return decoded.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _loadQuotesFromJson() async {
    if (_isLoadingQuotes) return;
    setState(() {
      _isLoadingQuotes = true;
      _quoteLoadError = null;
    });

    try {
      String raw;
      try {
        raw = await rootBundle.loadString('assets/data/fos_lens_quotes.json', cache: false);
      } catch (_) {
        // Some builds expose asset keys without "assets/" prefix in manifest.
        raw = await rootBundle.loadString('data/fos_lens_quotes.json', cache: false);
      }
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) {
        if (!mounted) return;
        setState(() {
          _quoteOptions
            ..clear()
            ..addAll(kFosLensBibleQuotes);
          _isLoadingQuotes = false;
          _quoteLoadError = 'Could not parse quote JSON. Showing fallback quotes.';
        });
        return;
      }

      final quotes = <String>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final content = (item['content'] ?? '').toString();
        final verseRef = (item['verseref'] ?? '').toString().trim();
        final cleanContent = _decodeHtmlEntities(_stripHtmlTags(content));
        if (cleanContent.isEmpty) continue;
        quotes.add(
          verseRef.isEmpty ? cleanContent : '$cleanContent - $verseRef',
        );
      }

      if (!mounted) return;
      setState(() {
        _quoteOptions
          ..clear()
          ..addAll(quotes.isNotEmpty ? quotes : kFosLensBibleQuotes);
        _isLoadingQuotes = false;
        if (quotes.isEmpty) {
          _quoteLoadError = 'Quote JSON had no usable content. Showing fallback quotes.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quoteOptions
          ..clear()
          ..addAll(kFosLensBibleQuotes);
        _isLoadingQuotes = false;
        _quoteLoadError =
            'Could not load quote JSON (${e.runtimeType}). Showing fallback quotes. Do full restart.';
      });
    }
  }

  void _removeOverlay(String id) {
    setState(() => _overlays.removeWhere((e) => e.id == id));
  }

  Future<void> _showQuoteStyleSheet(_LensOverlay o) async {
    final h = MediaQuery.sizeOf(context).height;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black26,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(top: h * 0.12),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: h * 0.45,
              child: Material(
                color: Theme.of(ctx).colorScheme.surface,
                elevation: 16,
                shadowColor: Colors.black45,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                clipBehavior: Clip.antiAlias,
                child: _QuoteStyleBottomSheet(
                  overlay: o,
                  onLiveChanged: () {
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showQuotePicker() async {
    if (!_isLoadingQuotes && _quoteOptions.isEmpty) {
      _loadQuotesFromJson();
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String query = '';
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (_, scroll) {
            return StatefulBuilder(
              builder: (context, setInnerState) {
                final filteredQuotes = _quoteOptions
                    .where((q) => q.toLowerCase().contains(query.toLowerCase()))
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Choose a quote',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search quotes...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => setInnerState(() => query = v.trim()),
                      ),
                    ),
                    if (_quoteLoadError != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          _quoteLoadError!,
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Expanded(
                      child: _isLoadingQuotes
                          ? const Center(child: CircularProgressIndicator())
                          : filteredQuotes.isEmpty
                              ? const Center(
                                  child: Text('No quotes found.'),
                                )
                              : ListView.builder(
                                  controller: scroll,
                                  itemCount: filteredQuotes.length,
                                  itemBuilder: (_, i) {
                                    final q = filteredQuotes[i];
                                    return ListTile(
                                      title: Text(q, maxLines: 3, overflow: TextOverflow.ellipsis),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        setState(() {
                                          final ov = _LensOverlay(
                                            id: _nextId(),
                                            isQuote: true,
                                            text: q,
                                            x: 24,
                                            y: 80 + (_overlays.length * 22.0),
                                          );
                                          _clampOverlayInBounds(ov);
                                          _overlays.add(ov);
                                        });
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showStickerPicker() async {
    if (!_isLoadingStickers && _apiStickers.isEmpty) {
      _loadApiStickers();
    }

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose a sticker',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (_stickerLoadError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _stickerLoadError!,
                    style: TextStyle(
                      color: Theme.of(ctx).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: _isLoadingStickers && _apiStickers.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: _apiStickers.isNotEmpty
                              ? _apiStickers.length
                              : kFosLensStickerAssets.length,
                          itemBuilder: (_, i) {
                            final hasApiData = _apiStickers.isNotEmpty;
                            final stickerPath =
                                hasApiData ? _apiStickers[i].imageUrl : kFosLensStickerAssets[i];

                            return Material(
                              color: AppColors.backgroundGrey,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _overlays.add(
                                      _LensOverlay(
                                        id: _nextId(),
                                        isQuote: false,
                                        stickerPath: stickerPath,
                                        isNetworkSticker: hasApiData,
                                        x: ((_canvasSize?.width ?? 300) / 2) - 48 + ((i % 3) * 10.0),
                                        y: ((_canvasSize?.height ?? 420) / 2) - 48 + ((_overlays.length % 3) * 10.0),
                                        scale: 1.1,
                                      ),
                                    );
                                    _clampOverlayInBounds(_overlays.last);
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: hasApiData
                                      ? Image.network(
                                          stickerPath,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image_outlined),
                                        )
                                      : Image.asset(stickerPath, fit: BoxFit.contain),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool get _editChromeVisible => !_isCapturingForExport;

  Widget _buildBasePhotoLayer() {
    Widget img = Image.file(
      File(widget.imagePath),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
    final idx = _imageFilterIndex.clamp(0, kFosLensImageFilterPresets.length - 1);
    if (idx != 0) {
      img = ColorFiltered(
        colorFilter: ColorFilter.matrix(kFosLensImageFilterPresets[idx].matrix),
        child: img,
      );
    }
    return Positioned.fill(child: img);
  }

  /// Max width for quote box in **layout** pixels. [Transform.scale] paints larger without growing
  /// layout width, so we divide by [scale] so the saved image matches the editor and stays in-bounds.
  double _maxQuoteBoxLayoutWidth(_LensOverlay o, double canvasW) {
    return _maxQuoteBoxLayoutWidthAtScale(o, canvasW, o.scale);
  }

  Widget _buildOverlayWidget(_LensOverlay o, Size canvasSize) {
    final canvasW = canvasSize.width;
    final edit = _editChromeVisible;

    final Widget core = o.isQuote
        ? edit
            ? Container(
                constraints: BoxConstraints(maxWidth: _maxQuoteBoxLayoutWidth(o, canvasW)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(_hasAnyQuoteOverlay ? 0.42 : 0.55),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  o.text ?? '',
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: o.baseQuoteTextStyle(forExport: false),
                ),
              )
            : ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _maxQuoteBoxLayoutWidth(o, canvasW)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    o.text ?? '',
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: o.baseQuoteTextStyle(forExport: true),
                  ),
                ),
              )
        : (o.isNetworkSticker
              ? Image.network(
                  o.stickerPath!,
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 42),
                )
              : Image.asset(
                  o.stickerPath!,
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                ));

    return Positioned(
      left: o.x,
      top: o.y,
      child: Transform.scale(
        scale: o.scale,
        alignment: Alignment.topLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Scale/pan only on content — close/tune stay tappable after zoom (no parent scale arena steal).
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onScaleStart: o.onScaleStart,
              onScaleUpdate: (d) => setState(() {
                o.onScaleUpdate(d);
                _clampOverlayInBounds(o);
              }),
              onScaleEnd: (_) => setState(() {
                o.onScaleEnd();
                _clampOverlayInBounds(o);
              }),
              child: core,
            ),
            if (edit && o.isQuote)
              Positioned(
                left: -8,
                top: -8,
                child: Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _showQuoteStyleSheet(o),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.tune, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            if (edit)
              Positioned(
                right: -8,
                top: -8,
                child: Material(
                  color: Colors.redAccent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _removeOverlay(o.id),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.close, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _capturePngBytes() async {
    final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final ratio = MediaQuery.devicePixelRatioOf(context).clamp(2.0, 4.0);
    final image = await boundary.toImage(pixelRatio: ratio);
    final bd = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bd?.buffer.asUint8List();
  }

  /// Saves current canvas to gallery and returns the saved image path when successful.
  Future<String?> _saveToGallery() async {
    print('[FOS Lens] ========== STARTING SAVE TO GALLERY ==========');
    setState(() => _isCapturingForExport = true);
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 100));

    Uint8List? bytes;
    try {
      bytes = await _capturePngBytes();
    } finally {
      if (mounted) setState(() => _isCapturingForExport = false);
    }

    if (bytes == null || !mounted) {
      Get.snackbar('Save failed', 'Could not render the image.', snackPosition: SnackPosition.BOTTOM);
      return null;
    }

    try {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/fos_lens_${DateTime.now().millisecondsSinceEpoch}.png');
      await f.writeAsBytes(bytes);
      
      // Also save to FOS_LENS directory for gallery screen
      try {
        final documentsDir = await getApplicationDocumentsDirectory();
        final fosLensDir = Directory('${documentsDir.path}/FOS_LENS');
        if (!await fosLensDir.exists()) {
          await fosLensDir.create(recursive: true);
          print('[FOS Lens] Created FOS_LENS directory: ${fosLensDir.path}');
        }
        // Create a copy in FOS_LENS directory
        final galleryFile = File('${fosLensDir.path}/fos_lens_${DateTime.now().millisecondsSinceEpoch}.png');
        await galleryFile.writeAsBytes(bytes);
        print('[FOS Lens] Image also saved to gallery directory: ${galleryFile.path}');
      } catch (galleryError) {
        print('[FOS Lens] Failed to save to gallery directory: $galleryError');
        // Continue anyway, main gallery save worked
      }

      final allowed = await Gal.hasAccess(toAlbum: true);
      if (!allowed) {
        final ok = await Gal.requestAccess(toAlbum: true);
        if (!ok) {
          if (mounted) {
            Get.snackbar('Permission', 'Gallery access is required to save.', snackPosition: SnackPosition.BOTTOM);
          }
          return null;
        }
      }
      await Gal.putImage(f.path);
      if (!mounted) return null;
      Get.snackbar(
        'Saved',
        'Your image was saved to the gallery.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );
      return f.path;
    } catch (e) {
      if (mounted) {
        Get.snackbar('Save failed', e.toString(), snackPosition: SnackPosition.BOTTOM);
      }
      return null;
    }
  }

  Future<void> _closeLensThenShare(String savedImagePath) async {
    Get.offAllNamed(AppRoutes.home);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    try {
      await Share.shareXFiles(
        [XFile(savedImagePath)],
        text: 'Shared from FOS Lens',
      );
    } catch (_) {
      if (mounted) {
        Get.snackbar('Share failed', 'Could not share image right now.');
      }
    }
  }

  Future<void> _onSavePressed() async {
    if (_saving) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save to gallery'),
        content: Text(
          'Download this image to your gallery for \$${_kFosLensExportPrice.toStringAsFixed(2)}. '
          'After payment it will save automatically and you will return home.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    if (!CacheManager.isLoggedIn()) {
      Get.snackbar(
        'Login required',
        'Please sign in to complete payment.',
        snackPosition: SnackPosition.BOTTOM,
      );
      AppRoutes.toLogin();
      return;
    }

    setState(() => _saving = true);
    try {
      print('[FOS Lens] Starting payment flow...');
      print('[FOS Lens] Current route before payment: ${Get.currentRoute}');
      final result = await Get.toNamed(
        AppRoutes.stripePayment,
        arguments: {
          'amount': _kFosLensExportPrice,
          'currency': 'usd',
          'payment_method_id': 0,
          'coupon_code': '',
          'notes': 'FOS Lens image export',
          'is_digital_order': true,
          'purpose': 'fos_lens',
        },
      );
      print('[FOS Lens] Payment flow completed. Result: $result');
      print('[FOS Lens] Current route after payment: ${Get.currentRoute}');
      if (!mounted) {
        print('[FOS Lens] Widget not mounted, exiting');
        return;
      }
      final map = result is Map<String, dynamic> ? result : null;
      print('[FOS Lens] Result converted to map: $map');
      print('[FOS Lens] Widget mounted status: $mounted');
      
      // Save image to gallery first before any navigation
      String? savedPath;
      print('[FOS Lens] Payment result received: $map');
      print('[FOS Lens] Map success status: ${map?['success']}');
      if (map != null && map['success'] == true) {
        print('[FOS Lens] Starting image save process...');
        savedPath = await _saveToGallery();
        print('[FOS Lens] Image save completed. Path: $savedPath');
      } else {
        print('[FOS Lens] Payment was not successful or map was null');
      }
      
      // Now handle navigation based on payment result
      if (map != null && map['success'] == true) {
        // Payment successful - show success message and navigate to orders
        if (savedPath != null && mounted) {
          Get.snackbar(
            'Success!',
            'Image saved to gallery! Check your gallery to view.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: AppColors.textWhite,
            duration: const Duration(seconds: 3),
          );
          // Close FOS LENS and go to gallery after a short delay
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            // Keep previous route in stack so gallery back works as expected.
            Get.offNamed(AppRoutes.gallery);
          }
        } else {
          // Payment successful but image save failed
          Get.snackbar(
            'Payment Successful',
            'Payment completed but image save failed. You can download from your orders.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.warning,
            colorText: AppColors.textWhite,
            duration: const Duration(seconds: 5),
          );
          // Close FOS LENS and go to orders (where digital products can be downloaded)
          await Future.delayed(const Duration(milliseconds: 2500));
          if (mounted) {
            Get.offAllNamed(AppRoutes.orders);
          }
        }
      } else {
        // Payment failed or cancelled
        Get.snackbar(
          'Payment Failed',
          map?['message'] ?? 'Payment was cancelled or failed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: AppColors.textWhite,
        );
      }
    } catch (e) {
      print('[FOS Lens] Payment process error: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred during payment: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    return WillPopScope(
      onWillPop: _confirmExitIfNeeded,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldExit = await _confirmExitIfNeeded();
              if (shouldExit && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text('FOS Lens'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
        ),
        body: _decoding || _aspectRatio == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(ScreenSize.spacingMedium),
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final maxW = c.maxWidth;
                          final h = maxW / _aspectRatio!;
                          _canvasSize = Size(maxW, h);
                          return SizedBox(
                            width: maxW,
                            height: h,
                            child: RepaintBoundary(
                              key: _repaintKey,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _buildBasePhotoLayer(),
                                    if (_hasAnyQuoteOverlay)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                _isCapturingForExport
                                                    ? _kQuoteImageDimOpacityExport
                                                    : _kQuoteImageDimOpacity,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ..._overlays.map((ov) => _buildOverlayWidget(ov, _canvasSize!)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    ScreenSize.spacingMedium,
                    ScreenSize.spacingSmall,
                    ScreenSize.spacingMedium,
                    ScreenSize.spacingMedium + MediaQuery.paddingOf(context).bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Filters',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: ScreenSize.spacingSmall * 0.75),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: kFosLensImageFilterPresets.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final sel = _imageFilterIndex == i;
                            final label = kFosLensImageFilterPresets[i].label;
                            return ChoiceChip(
                              label: Text(label),
                              selected: sel,
                              showCheckmark: false,
                              onSelected: _saving
                                  ? null
                                  : (v) {
                                      if (v) setState(() => _imageFilterIndex = i);
                                    },
                              visualDensity: VisualDensity.compact,
                              selectedColor: AppColors.primary.withOpacity(0.35),
                              labelStyle: TextStyle(
                                fontSize: 13,
                                color: sel ? AppColors.primary : Theme.of(context).textTheme.bodyMedium?.color,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: ScreenSize.spacingSmall),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saving ? null : _showQuotePicker,
                              icon: const Icon(Icons.format_quote),
                              label: const Text('Add quote'),
                            ),
                          ),
                          SizedBox(width: ScreenSize.spacingSmall),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saving ? null : _showStickerPicker,
                              icon: const Icon(Icons.emoji_emotions_outlined),
                              label: const Text('Add sticker'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ScreenSize.spacingSmall),
                      FilledButton.icon(
                        onPressed: _saving ? null : _onSavePressed,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.download),
                        label: Text(
                          _saving ? 'Please wait…' : 'Save image (\$${_kFosLensExportPrice.toStringAsFixed(2)})',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

/// Half-height bottom sheet: color, font family, weight & italic, size — updates overlay live.
class _QuoteStyleBottomSheet extends StatefulWidget {
  const _QuoteStyleBottomSheet({
    required this.overlay,
    required this.onLiveChanged,
  });

  final _LensOverlay overlay;
  final VoidCallback onLiveChanged;

  @override
  State<_QuoteStyleBottomSheet> createState() => _QuoteStyleBottomSheetState();
}

class _QuoteStyleBottomSheetState extends State<_QuoteStyleBottomSheet> {
  static const _palette = <Color>[
    Colors.white,
    Colors.black,
    Color(0xFFF5E6C8),
    Color(0xFFFFD700),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
    Color(0xFFFF7043),
    Color(0xFF26A69A),
    Color(0xFF3949AB),
    Color(0xFFEC407A),
  ];

  static int _weightToSeg(FontWeight w) {
    if (w == FontWeight.w800 || w == FontWeight.bold || w == FontWeight.w700) return 2;
    if (w == FontWeight.w600 || w == FontWeight.w500) return 1;
    return 0;
  }

  static FontWeight _segToWeight(int seg) {
    if (seg == 2) return FontWeight.w800;
    if (seg == 1) return FontWeight.w600;
    return FontWeight.w400;
  }

  void _notify() {
    widget.onLiveChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.overlay;
    final weightSeg = _weightToSeg(o.quoteFontWeight);
    final italicSeg = o.quoteFontStyle == FontStyle.italic ? 1 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
          child: Row(
            children: [
              const Text(
                'Quote style',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            children: [
              Text('Text color', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _palette.map((c) {
                  final sel = o.quoteColor == c;
                  return GestureDetector(
                    onTap: () {
                      o.quoteColor = c;
                      _notify();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sel ? AppColors.primary : Colors.grey.shade400,
                          width: sel ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Text('Font family', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(kFosLensFontLabels.length, (i) {
                  final sel = o.quoteFontPreset == i;
                  return ChoiceChip(
                    label: Text(kFosLensFontLabels[i]),
                    selected: sel,
                    showCheckmark: false,
                    onSelected: (v) {
                      if (v) {
                        o.quoteFontPreset = i;
                        _notify();
                      }
                    },
                  );
                }),
              ),
              const SizedBox(height: 18),
              Text('Font style', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Regular')),
                  ButtonSegment(value: 1, label: Text('Medium')),
                  ButtonSegment(value: 2, label: Text('Bold')),
                ],
                selected: {weightSeg},
                onSelectionChanged: (s) {
                  o.quoteFontWeight = _segToWeight(s.first);
                  _notify();
                },
              ),
              const SizedBox(height: 10),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Normal')),
                  ButtonSegment(value: 1, label: Text('Italic')),
                ],
                selected: {italicSeg},
                onSelectionChanged: (s) {
                  o.quoteFontStyle = s.first == 1 ? FontStyle.italic : FontStyle.normal;
                  _notify();
                },
              ),
              const SizedBox(height: 18),
              Text('Font size (${o.quoteFontSize.round()})', style: Theme.of(context).textTheme.titleSmall),
              Slider(
                value: o.quoteFontSize.clamp(10.0, 48.0),
                min: 10,
                max: 48,
                divisions: 38,
                label: o.quoteFontSize.round().toString(),
                onChanged: (v) {
                  o.quoteFontSize = v;
                  _notify();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
