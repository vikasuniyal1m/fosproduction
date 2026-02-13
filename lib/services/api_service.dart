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
  static const String baseUrl = 'https://ecommercepanel.templateforwebsites.com/api/';
  static const String imageBaseUrl = 'https://ecommercepanel.templateforwebsites.com/uploads/';
  
  late Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10), // Reduced from 30 to 10 seconds
      receiveTimeout: const Duration(seconds: 10), // Reduced from 30 to 10 seconds
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
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('[API Auth] Token found and added to Authorization header');
        } else {
          print('[API Auth] WARNING: No token found in CacheManager!');
        }
        
        // Debug logging
        print('[API Request] ${options.method} ${options.baseUrl}${options.path}');
        print('[API Headers] ${options.headers}');
        if (options.data != null) {
          print('[API Data] ${options.data}');
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
  
  /// GET request
  Future<dio.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
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
  
  /// Handle API response
  static Map<String, dynamic> handleResponse(dio.Response response) {
    dynamic data = response.data;
    
    // If response is a string, try to parse as JSON
      if (data is String) {
        final responseString = data.trim();
      
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
        // For error responses, throw DioException so it can be caught properly
        // This allows the error handler to extract the message
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
}
