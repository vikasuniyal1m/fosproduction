import 'package:dio/dio.dart' hide Response;
import 'package:dio/dio.dart' as dio show Response;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:get/get.dart';
import '../utils/cache_manager.dart';
import '../routes/app_routes.dart';

/// API Service
/// Handles all HTTP requests to the backend
class ApiService {
  // static const String baseUrl = 'https://ecommercepanel.templateforwebsites.com/api/';
  static const String baseUrl = 'https://admin.fosproductions.org/api/';
  // static const String imageBaseUrl = 'https://ecommercepanel.templateforwebsites.com/uploads/';
  static const String imageBaseUrl = 'https://admin.fosproductions.org/uploads/';

  late Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30), // Increased to 30 seconds
      receiveTimeout: const Duration(seconds: 30), // Increased to 30 seconds
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      responseType: ResponseType.plain, // Use plain to handle both JSON and HTML responses
      validateStatus: (status) {
        // Accept all status codes so we can handle them manually
        return true;
      },
    ));
    
    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (object) {
        print('[API] $object');
      },
    ));
    
    // Add interceptor for token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add token to headers if available
        final token = CacheManager.getUserToken();
        print('[API Auth] Checking for token...');
        print('[API Auth] Token value: $token');
        print('[API Auth] Is token null: ${token == null}');
        print('[API Auth] Is token empty: ${token?.isEmpty ?? true}');
        print('[API Auth] User logged in: ${CacheManager.isLoggedIn()}');
        
        if (token != null && token.isNotEmpty) {
          // For ALL requests, add token as query parameter (backend expects this consistently)
          if (options.queryParameters == null) {
            options.queryParameters = {};
          }
          options.queryParameters['token'] = token;
          print('[API Auth] Token added as query parameter for ${options.method} request');
          print('[API Auth] Token value: $token');
        } else {
          print('[API Auth] WARNING: No token found in CacheManager!');
          print('[API Auth] Request will proceed without authentication');
        }
        
        // Debug logging
        print('[API Request] ${options.method} ${options.baseUrl}${options.path}');
        print('[API Headers] ${options.headers}');
        if (options.queryParameters != null) {
          print('[API Query Parameters] ${options.queryParameters}');
        }
        if (options.data != null) {
          print('[API Data] ${options.data}');
          print('[API Data Type] ${options.data.runtimeType}');
        }
        
        // For POST requests, show the full URL with query parameters
        if (options.method.toUpperCase() == 'POST' && options.queryParameters != null) {
          final queryString = options.queryParameters.entries
              .map((e) => '${e.key}=${e.value}')
              .join('&');
          print('[API POST] Full URL: ${options.baseUrl}${options.path}?$queryString');
        }
        
        return handler.next(options);
      },
      onError: (error, handler) {
        // Enhanced error logging
        print('[API Error] Type: ${error.type}');
        print('[API Error] Message: ${error.message}');
        if (error.response != null) {
          print('[API Error] Status: ${error.response?.statusCode}');
          print('[API Error] Headers: ${error.response?.headers}');
          print('[API Error] Response Type: ${error.response?.data.runtimeType}');
          print('[API Error] Response: ${error.response?.data}');
          
          // If response is not JSON, try to extract error message
          if (error.response?.data is String) {
            final responseString = error.response!.data as String;
            print('[API Error] Response String: $responseString');
            
            // Check if it's HTML (error page)
            if (responseString.contains('<html') || responseString.contains('<!DOCTYPE')) {
              // Try to extract error message from HTML
              final errorMatch = RegExp(r'<title>(.*?)</title>', caseSensitive: false).firstMatch(responseString);
              if (errorMatch != null) {
                print('[API Error] HTML Error Title: ${errorMatch.group(1)}');
              }
            }
          }
        } else {
          // Check if it's a parsing error
          if (error.error is FormatException) {
            final formatError = error.error as FormatException;
            print('[API Error] FormatException: ${formatError.message}');
            print('[API Error] FormatException Source: ${formatError.source}');
          }
        }
        return handler.next(error);
      },
    ));
  }

  String _buildSyncKey(String path, Map<String, dynamic>? queryParameters) {
    final sorted = <String, dynamic>{};
    if (queryParameters != null) {
      final keys = queryParameters.keys.toList()..sort();
      for (final key in keys) {
        if (key == 'known_sync_token') continue;
        sorted[key] = queryParameters[key];
      }
    }
    return 'sync:${path.trim()}:${jsonEncode(sorted)}';
  }

  Map<String, dynamic>? _tryParseResponseMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is String) {
      try {
        final decoded = jsonDecode(payload.trim());
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }
  
  /// Validate if current token is working
  Future<bool> validateToken() async {
    try {
      print('[API Auth] Validating current token...');
      final response = await _dio.get(
        'user/profile.php', // Use a lightweight endpoint for validation
        options: Options(
          responseType: ResponseType.plain,
        ),
      );
      
      if (response.statusCode == 200) {
        print('[API Auth] Token validation successful');
        return true;
      } else {
        print('[API Auth] Token validation failed - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[API Auth] Token validation error: $e');
      return false;
    }
  }
  
  /// GET request
  Future<dio.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final effectiveQuery = <String, dynamic>{...(queryParameters ?? {})};
      final syncKey = _buildSyncKey(path, effectiveQuery);
      final cachedSyncToken = CacheManager.getData<String>('${syncKey}:token');
      if (cachedSyncToken != null && cachedSyncToken.isNotEmpty) {
        effectiveQuery['known_sync_token'] = cachedSyncToken;
      }

      final response = await _dio.get(
        path,
        queryParameters: effectiveQuery,
        options: options,
      );

      final parsed = _tryParseResponseMap(response.data);
      if (parsed != null && parsed['success'] == true && parsed['data'] is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(parsed['data'] as Map<String, dynamic>);

        if (data['unchanged'] == true) {
          final cachedPayload = CacheManager.getData<Map<String, dynamic>>('${syncKey}:payload');
          if (cachedPayload != null) {
            return dio.Response(
              data: {
                ...parsed,
                'data': cachedPayload,
              },
              statusCode: response.statusCode,
              statusMessage: response.statusMessage,
              headers: response.headers,
              requestOptions: response.requestOptions,
              isRedirect: response.isRedirect,
              redirects: response.redirects,
              extra: response.extra,
            );
          }
          return response;
        }

        final syncToken = data['sync_token'];
        if (syncToken is String && syncToken.isNotEmpty) {
          final payloadToCache = Map<String, dynamic>.from(data)
            ..remove('sync_token')
            ..remove('unchanged');
          CacheManager.saveData('${syncKey}:token', syncToken);
          CacheManager.saveData('${syncKey}:payload', payloadToCache);
        }
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  /// POST request
  Future<dio.Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      print('[API POST] Full URL: $baseUrl$path');
      
      // Force responseType to plain
      final finalOptions = (options ?? Options()).copyWith(
        responseType: ResponseType.plain,
      );
      
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: finalOptions,
      );
      
      print('[API POST] Response status: ${response.statusCode}');
      print('[API POST] Response type: ${response.data.runtimeType}');
      
      // Convert plain response to JSON response
      if (response.data is String) {
        final responseString = response.data as String;
        print('[API POST] Response string length: ${responseString.length}');
        print('[API POST] Response string (first 500 chars): ${responseString.length > 500 ? responseString.substring(0, 500) : responseString}');
        
        // Remove BOM if present
        String cleanedString = responseString;
        if (cleanedString.startsWith('\uFEFF')) {
          cleanedString = cleanedString.substring(1);
        }
        
        // Trim whitespace
        cleanedString = cleanedString.trim();
        
        // Globally map old template domain to the active admin domain
        cleanedString = cleanedString.replaceAll(
          'ecommercepanel.templateforwebsites.com',
          'admin.fosproductions.org',
        );
        
        // Try to parse as JSON
        try {
          final jsonData = jsonDecode(cleanedString);
          // Create a new response with parsed JSON
          return dio.Response(
            data: jsonData,
            statusCode: response.statusCode,
            statusMessage: response.statusMessage,
            headers: response.headers,
            requestOptions: response.requestOptions,
            isRedirect: response.isRedirect,
            redirects: response.redirects,
            extra: response.extra,
          );
        } catch (e) {
          print('[API POST] JSON Parse Error: $e');
          print('[API POST] Failed to parse: $cleanedString');
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: 'Invalid JSON response: ${e.toString()}',
          );
        }
      }
      
      return response;
    } catch (e) {
      print('[API POST] Exception: $e');
      if (e is DioException) {
        print('[API POST] DioException type: ${e.type}');
        print('[API POST] DioException message: ${e.message}');
        print('[API POST] DioException error: ${e.error}');
        if (e.response != null) {
          print('[API POST] Response status: ${e.response?.statusCode}');
          print('[API POST] Response data type: ${e.response?.data.runtimeType}');
          print('[API POST] Response data: ${e.response?.data}');
        }
      }
      rethrow;
    }
  }
  
  /// PUT request
  Future<dio.Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  /// DELETE request
  Future<dio.Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    dynamic data,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Download a file
  Future<dio.Response> downloadFile(
    String urlPath,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    void Function(int, int)? onReceiveProgress,
    Options? options,
  }) async {
    try {
      urlPath = _fixDownloadUrl(urlPath);

      // Absolute URLs must not be combined with baseUrl or auth interceptor.
      if (urlPath.startsWith('http://') || urlPath.startsWith('https://')) {
        final bareDio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
            followRedirects: true,
            headers: const {'Accept': '*/*'},
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        return bareDio.download(
          urlPath,
          savePath,
          queryParameters: queryParameters,
          onReceiveProgress: onReceiveProgress,
          options: options,
        );
      }

      final response = await _dio.download(
        urlPath,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Handle API response
  static Map<String, dynamic> handleResponse(dio.Response response) {
    dynamic data = response.data;
    
    // If response is a string, try to parse as JSON
      if (data is String) {
        String responseString = data.trim();
        
        // Globally map old template domain to the active admin domain
        responseString = responseString.replaceAll(
          'ecommercepanel.templateforwebsites.com',
          'admin.fosproductions.org',
        );
      
        // Check if it's HTML (error page) or PHP fatal error
        if (responseString.startsWith('<') || 
            responseString.startsWith('<!DOCTYPE') ||
            responseString.contains('<b>Fatal error</b>') ||
            responseString.contains('mysqli_sql_exception') ||
            responseString.contains('Unknown column')) {
          print('[API Response] Server returned HTML/PHP error instead of JSON');
          print('[API Response] Error content (first 500 chars): ${responseString.length > 500 ? responseString.substring(0, 500) : responseString}');
          
          // Try to extract error message from PHP fatal error
          String errorMessage = 'Server error occurred. Please try again later.';
          if (responseString.contains('Unknown column')) {
            final columnMatch = RegExp(r"Unknown column '([^']+)'").firstMatch(responseString);
            if (columnMatch != null) {
              errorMessage = 'Database configuration error. Please contact support.';
            }
          } else if (responseString.contains('Fatal error')) {
            errorMessage = 'Server error occurred. Please contact support.';
          }
          
          throw Exception(errorMessage);
        }
      
      // Try to parse as JSON
      try {
        data = jsonDecode(responseString);
      } catch (e) {
        print('[API Response] JSON Parse Error: $e');
        print('[API Response] Response content: $responseString');
        throw Exception('Invalid JSON response from server: ${e.toString()}');
      }
    }
    
    if (data is Map<String, dynamic>) {
      // Check if request was successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          return data['data'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        // For 401 errors, return empty data instead of throwing exception
        // This prevents app crashes and allows smooth user experience
        if (response.statusCode == 401) {
          print('[API] 401 Error handled gracefully - returning empty data');
          return {};
        }
        
        // For other error responses, throw DioException so it can be caught properly
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: data['message'] ?? 'Request failed',
        );
      }
    }
    
    // If we get here, something went wrong
    throw Exception('Invalid response format. Status: ${response.statusCode}');
  }
  
  /// Handle API error
  static String handleError(dynamic error) {
    print('[API Error Handler] Error type: ${error.runtimeType}');
    
    if (error is DioException) {
      print('[API Error Handler] DioException type: ${error.type}');
      print('[API Error Handler] DioException message: ${error.message}');
      
      if (error.response != null) {
        final statusCode = error.response?.statusCode;
        print('[API Error Handler] Response status: $statusCode');
        print('[API Error Handler] Response data: ${error.response?.data}');
        
        // Handle 401 Unauthorized - Login required
        if (statusCode == 401) {
          return 'Please login or register to continue';
        }

        // Handle 403 Forbidden - Access denied
        if (statusCode == 403) {
          return 'Access denied. Please login to continue';
        }

        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          // Check if it's a validation error with nested errors
          if (data['data'] != null && data['data'] is Map<String, dynamic>) {
            final errorData = data['data'] as Map<String, dynamic>;
            if (errorData['errors'] != null && errorData['errors'] is Map) {
              final errors = errorData['errors'] as Map;
              // Return first error message
              if (errors.isNotEmpty) {
                return errors.values.first.toString();
              }
            }
          }
          // Return message from API if available
          final message = data['message'] ?? '';
          if (message.isNotEmpty) {
            return message;
          }
        }

        // Hide server errors (500, 502, 503, etc.) - show generic message
        if (statusCode != null && statusCode >= 500) {
          return 'Service temporarily unavailable. Please try again later.';
        }

        // For other errors, return generic message instead of showing status code
        return 'An error occurred. Please try again.';
      } else {
        // Network errors - more detailed messages
        if (error.type == DioExceptionType.connectionTimeout) {
          print('[API Error Handler] Connection timeout');
          return 'Connection timeout. Please check your internet connection and try again.';
        } else if (error.type == DioExceptionType.receiveTimeout) {
          print('[API Error Handler] Receive timeout');
          return 'Server took too long to respond. Please try again.';
        } else if (error.type == DioExceptionType.connectionError) {
          print('[API Error Handler] Connection error: ${error.message}');
          // Check if it's a specific connection error
          if (error.message?.contains('Failed host lookup') == true ||
              error.message?.contains('Network is unreachable') == true) {
            return 'No internet connection. Please check your network settings.';
          }
          return 'Unable to connect to server. Please check your internet connection.';
        } else if (error.type == DioExceptionType.badResponse) {
          print('[API Error Handler] Bad response');
          return 'Server returned an error. Please try again later.';
        } else if (error.type == DioExceptionType.cancel) {
          print('[API Error Handler] Request cancelled');
          return 'Request was cancelled.';
        } else if (error.type == DioExceptionType.sendTimeout) {
          print('[API Error Handler] Send timeout');
          return 'Request timeout. Please try again.';
        } else {
          print('[API Error Handler] Unknown error: ${error.message}');
          return error.message ?? 'Unable to connect to server. Please try again.';
        }
      }
    }
    
    print('[API Error Handler] Non-DioException error: $error');
    return error.toString();
  }

  /// Handle error with automatic login redirect for 401 errors
  /// Shows snackbar and redirects to login if 401 error
  /// Returns the error message to display
  /// showSnackbar: if false, only redirects without showing snackbar
  static String handleErrorWithLoginRedirect(dynamic error, {bool showSnackbar = true}) {
    if (error is DioException && error.response?.statusCode == 401) {
      // User is not authenticated
      if (showSnackbar) {
        Get.snackbar(
          'Login Required',
          'Please login or register to continue',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
      // Redirect to login after delay
      Future.delayed(const Duration(milliseconds: 500), () {
        AppRoutes.toLogin();
      });
      return 'Please login or register to continue';
    }
    // For other errors, use normal error handling
    return handleError(error);
  }

  /// Show error snackbar only if not a server error (500+)
  /// Automatically handles 401 redirects
  static void showErrorSnackbar(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;

      // 401 - Redirect to login (already handled in handleErrorWithLoginRedirect)
      if (statusCode == 401) {
        handleErrorWithLoginRedirect(error);
        return;
      }

      // 500+ Server errors - Don't show snackbar
      if (statusCode != null && statusCode >= 500) {
        // Silent fail for server errors
        return;
      }
    }

    // Show error for other cases
    final errorMessage = handleError(error);
    Get.snackbar('Error', errorMessage);
  }

  /// Fix malformed download URLs
  String _fixDownloadUrl(String url) {
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
    
    // Don't touch double slashes after domain as they might be intentional
    // Only fix excessive slashes (3 or more) in the path
    fixedUrl = fixedUrl.replaceAll(RegExp(r'/{3,}'), '/');
    
    return fixedUrl;
  }
}
