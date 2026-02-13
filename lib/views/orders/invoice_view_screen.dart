import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../utils/screen_size.dart';
import '../../utils/app_colors.dart';

/// Invoice View Screen
/// Shows invoice using WebView
class InvoiceViewScreen extends StatefulWidget {
  final String invoiceUrl;
  
  const InvoiceViewScreen({
    super.key,
    required this.invoiceUrl,
  });
  
  @override
  State<InvoiceViewScreen> createState() => _InvoiceViewScreenState();
}

class _InvoiceViewScreenState extends State<InvoiceViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  bool _isDownloading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }
  
  void _initializeWebView() {
    try {
      // Parse and validate URL
      final uri = Uri.parse(widget.invoiceUrl);
      print('[InvoiceView] Loading URL: ${uri.toString()}');
      
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
                _error = null;
              });
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              print('[InvoiceView] WebView error: ${error.description}');
              setState(() {
                _isLoading = false;
                _error = 'Failed to load invoice: ${error.description}';
              });
            },
          ),
        )
        ..loadRequest(uri);
    } catch (e) {
      print('[InvoiceView] Error initializing WebView: $e');
      setState(() {
        _isLoading = false;
        _error = 'Invalid invoice URL: ${e.toString()}';
      });
    }
  }
  
  Future<void> _shareInvoice() async {
    try {
      await Share.share(
        widget.invoiceUrl,
        subject: 'Invoice',
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not share invoice');
    }
  }
  
  Future<void> _openInBrowser() async {
    try {
      final uri = Uri.parse(widget.invoiceUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Error', 'Could not open invoice in browser');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to open invoice: ${e.toString()}');
    }
  }

  /// Download invoice as HTML file
  /// Downloads the invoice from the URL and saves it to device storage
  /// For Android: Saves to Downloads folder if accessible, otherwise app documents
  /// For iOS: Saves to app documents directory
  Future<void> _downloadInvoice() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      // Show loading snackbar
      Get.snackbar(
        'Downloading',
        'Please wait...',
        backgroundColor: AppColors.primaryLight,
        colorText: AppColors.primary,
        duration: const Duration(seconds: 1),
        snackPosition: SnackPosition.BOTTOM,
      );

      // Get downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        // For Android, use external storage downloads directory
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to app documents directory
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        // For iOS, use documents directory
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'invoice_$timestamp.html';
      final filePath = '${directory.path}/$fileName';

      // Download file using Dio
      final dio = Dio();
      final response = await dio.get(
        widget.invoiceUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(response.data);

      setState(() {
        _isDownloading = false;
      });

      // Show success message
      Get.snackbar(
        'Success',
        'Invoice downloaded successfully',
        backgroundColor: AppColors.successLight,
        colorText: AppColors.success,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );

      print('[InvoiceDownload] File saved to: $filePath');
    } catch (e) {
      print('[InvoiceDownload] Error: $e');
      setState(() {
        _isDownloading = false;
      });

      Get.snackbar(
        'Error',
        'Failed to download invoice: ${e.toString()}',
        backgroundColor: AppColors.errorLight,
        colorText: AppColors.error,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Invoice'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                    ),
                  )
                : const Icon(Icons.download),
            tooltip: 'Download Invoice',
            onPressed: _isDownloading ? null : _downloadInvoice,
          ),
          // IconButton(
          //   icon: const Icon(Icons.open_in_browser),
          //   tooltip: 'Open in Browser',
          //   onPressed: _openInBrowser,
          // ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Invoice',
            onPressed: _shareInvoice,
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(ScreenSize.spacingLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    SizedBox(height: ScreenSize.spacingMedium),
                    Text(
                      'Error Loading Invoice',
                      style: TextStyle(
                        fontSize: ScreenSize.headingSmall,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: ScreenSize.spacingSmall),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontSize: ScreenSize.textMedium,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ScreenSize.spacingLarge),
                    ElevatedButton.icon(
                      onPressed: _openInBrowser,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open in Browser'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: ScreenSize.spacingLarge,
                          vertical: ScreenSize.spacingMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  Container(
                    color: AppColors.background,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }
}

