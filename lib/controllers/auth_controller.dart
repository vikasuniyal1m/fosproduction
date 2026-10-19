import 'package:ecommerceapp/controllers/profile_controller.dart';
import 'package:ecommerceapp/controllers/wishlist_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;
import 'package:hive_flutter/hive_flutter.dart';
import '../config/google_auth_config.dart';
import '../routes/app_routes.dart';
import '../utils/cache_manager.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';
import '../services/notification_service.dart';
import 'cart_controller.dart';
import 'home_controller.dart';

/// Auth Controller
/// Handles authentication logic (Login, Signup, etc.)
class AuthController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final ApiService _apiService = ApiService();
  
  // Login form
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  
  // Login Error messages (one at a time)
  final RxString emailError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString generalError = ''.obs;
  
  // Signup form
  final RxString signupName = ''.obs;
  final RxString signupEmail = ''.obs;
  final RxString signupPhone = ''.obs;
  final RxString signupPassword = ''.obs;
  final RxString signupConfirmPassword = ''.obs;
  
  // Signup Error messages (one at a time)
  final RxString signupNameError = ''.obs;
  final RxString signupEmailError = ''.obs;
  final RxString signupPhoneError = ''.obs;
  final RxString signupPasswordError = ''.obs;
  final RxString signupConfirmPasswordError = ''.obs;
  final RxString signupGeneralError = ''.obs;
  
  /// Continue as Guest Mode
  void continueAsGuest() {
    print('[Auth] Continuing as Guest');
    CacheManager.setGuestMode(true);
    CacheManager.setLoggedIn(false);
    AppRoutes.toHome();
  }
  
  /// Clear all login errors
  void _clearLoginErrors() {
    emailError.value = '';
    passwordError.value = '';
    generalError.value = '';
  }
  
  /// Clear all signup errors
  void _clearSignupErrors() {
    signupNameError.value = '';
    signupEmailError.value = '';
    signupPhoneError.value = '';
    signupPasswordError.value = '';
    signupConfirmPasswordError.value = '';
    signupGeneralError.value = '';
  }
  
  /// Clear email error when user types
  void clearEmailError() {
    if (emailError.value.isNotEmpty) {
      emailError.value = '';
    }
    if (generalError.value.isNotEmpty) {
      generalError.value = '';
    }
  }

  String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[<>\"\"%;()&+]'), '');
    }

  /// Clear password error when user types
  void clearPasswordError() {
    if (passwordError.value.isNotEmpty) {
      passwordError.value = '';
    }
    if (generalError.value.isNotEmpty) {
      generalError.value = '';
    }
  }
  
  /// Clear signup field errors when user types
  void clearSignupNameError() {
    signupNameError.value = '';
    signupGeneralError.value = '';
  }
  
  void clearSignupEmailError() {
    signupEmailError.value = '';
    signupGeneralError.value = '';
  }
  
  void clearSignupPhoneError() {
    signupPhoneError.value = '';
    signupGeneralError.value = '';
  }
  
  void clearSignupPasswordError() {
    signupPasswordError.value = '';
    signupConfirmPasswordError.value = '';
    signupGeneralError.value = '';
  }
  
  void clearSignupConfirmPasswordError() {
    signupConfirmPasswordError.value = '';
    signupGeneralError.value = '';
  }
  
  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
  
  /// Validate email format
  bool _isValidEmail(String email) {
    return GetUtils.isEmail(email);
  }
  
  /// Validate phone format (basic)
  bool _isValidPhone(String phone) {
    // Remove spaces and special characters
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length >= 10;
  }
  
  /// Validate login form (client-side)
  String? _validateLoginForm() {
    _clearLoginErrors();
    
    // Email validation
    if (email.value.trim().isEmpty) {
      emailError.value = 'Email is required';
      return 'email';
    }
    
    if (!_isValidEmail(email.value.trim())) {
      emailError.value = 'Please enter a valid email address';
      return 'email';
    }
    
    // Password validation
    if (password.value.isEmpty) {
      passwordError.value = 'Password is required';
      return 'password';
    }
    
    if (password.value.length < 6) {
      passwordError.value = 'Password must be at least 6 characters';
      return 'password';
    }
    
    return null; // No validation errors
  }
  
  /// Login user
  Future<void> login() async {
    // Client-side validation
    final validationError = _validateLoginForm();
    if (validationError != null) {
      return; // Error already set in the field
    }
    
    isLoading.value = true;
    _clearLoginErrors();
    
    try {
      final response = await _apiService.post(
        ApiEndpoints.login,
        data: {
          'email': sanitizeInput(email.value),
          'password': password.value,
        },
      );

    final data = ApiService.handleResponse(response);
      final user = data['user'] ?? {};
      final token = data['token'] ?? '';
      
      // Debug token details
      print('[Auth] Login API Response - User: ${user['email']}, Token: $token');
      print('[Auth] Token length: ${token.length}');
      print('[Auth] Token format check: ${token.contains(':')}');
      print('[Auth] Token is hex only: ${RegExp(r'^[a-fA-F0-9]+$').hasMatch(token)}');
      
      // Test token immediately with profile API to verify server is working
      print('[Auth] Testing token with profile API...');
      try {
        final testResponse = await _apiService.get('/user/profile.php');
        final testData = ApiService.handleResponse(testResponse);
        print('[Auth] Profile API test response: ${testData['success'] ? 'SUCCESS' : 'FAILED'}');
        if (!testData['success']) {
          print('[Auth] Profile API error: ${testData['message']}');
        }
      } catch (e) {
        print('[Auth] Profile API test exception: $e');
      }
      
      // Decode token to see actual content
      try {
        final decodedBytes = base64.decode(token);
        final decodedString = utf8.decode(decodedBytes);
        print('[Auth] Decoded token: "$decodedString"');
        print('[Auth] Decoded token contains ":": ${decodedString.contains(':')}');
        if (decodedString.contains(':')) {
          final parts = decodedString.split(':');
          print('[Auth] User ID: ${parts[0]}, Hash: ${parts[1]}');
        }
      } catch (e) {
        print('[Auth] Token decode error: $e');
        print('[Auth] This appears to be a hex token, not Base64');
      }
      
      if (token.isEmpty) {
        generalError.value = 'Login failed. Please try again.';
        return;
      }
      
      // Save user data
      await CacheManager.setLoggedIn(true);
      await CacheManager.setGuestMode(false);
      await CacheManager.saveUserId(user['id']?.toString() ?? '');
      await CacheManager.saveUserEmail(user['email'] ?? email.value.trim());
      await CacheManager.saveUserName(user['name'] ?? '');
      await CacheManager.saveUserPhone(user['phone'] ?? '');
      await CacheManager.saveUserToken(token);
      
      print('[Auth] Login successful - Refreshing all controllers');
      
      // Refresh all controllers to detect login state
      _refreshAllControllers();
      
      // Clear form
      email.value = '';
      password.value = '';
      
      // Navigate to home
      AppRoutes.toHome();
    } on DioException catch (e) {
      _handleLoginError(e);
    } catch (e) {
      // Use the actual error message from the exception if available
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      } else if (errorMessage.isEmpty || errorMessage == 'null') {
        errorMessage = 'An unexpected error occurred. Please try again.';
      }
      
      generalError.value = errorMessage;
      print('Login error: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Handle login errors professionally
  void _handleLoginError(DioException error) {
    _clearLoginErrors();
    
    if (error.response != null) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      
      // Handle validation errors (422)
      if (statusCode == 422 && responseData is Map<String, dynamic>) {
        final data = responseData['data'];
        if (data is Map<String, dynamic> && data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          
          // Show first error only (one at a time)
          if (errors.containsKey('email')) {
            emailError.value = errors['email'].toString();
          } else if (errors.containsKey('password')) {
            passwordError.value = errors['password'].toString();
          } else {
            // Get first error
            final firstError = errors.values.first;
            generalError.value = firstError.toString();
          }
          return;
        }
      }
      
      // Handle other API errors
      String errorMessage = 'An error occurred';
      
      if (responseData is Map<String, dynamic>) {
        errorMessage = responseData['message'] ?? errorMessage;
      }
      
      // Map common error messages to field-specific errors
      final lowerMessage = errorMessage.toLowerCase();
      
      if (lowerMessage.contains('user not found') ||
          lowerMessage.contains('email not found') ||
          lowerMessage.contains('account not found') ||
          lowerMessage.contains('no account found')) {
        emailError.value = 'No account found with this email address. Please check your email or sign up to create an account.';
      } else if (lowerMessage.contains('incorrect password') ||
                 lowerMessage.contains('wrong password') ||
                 lowerMessage.contains('invalid password')) {
        passwordError.value = 'Incorrect password. Please try again.';
      } else if (lowerMessage.contains('invalid credentials')) {
        // Fallback for generic invalid credentials - show on password field
        passwordError.value = 'Incorrect password. Please try again.';
      } else if (lowerMessage.contains('inactive') ||
                 lowerMessage.contains('suspended') ||
                 lowerMessage.contains('disabled')) {
        generalError.value = 'Your account is inactive. Please contact support.';
      } else if (lowerMessage.contains('email') && 
                 lowerMessage.contains('required')) {
        emailError.value = errorMessage;
      } else if (lowerMessage.contains('password') && 
                 lowerMessage.contains('required')) {
        passwordError.value = errorMessage;
      } else {
        generalError.value = errorMessage;
      }
    } else {
      // Network errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        generalError.value = 'Connection timeout. Please check your internet connection.';
      } else if (error.type == DioExceptionType.connectionError) {
        generalError.value = 'No internet connection. Please check your network.';
      } else {
        generalError.value = 'Unable to connect to server. Please try again.';
      }
    }
  }
  
  /// Validate signup form (client-side)
  String? _validateSignupForm() {
    _clearSignupErrors();
    
    // Name validation
    if (signupName.value.trim().isEmpty) {
      signupNameError.value = 'Name is required';
      return 'name';
    }
    
    // Email validation
    if (signupEmail.value.trim().isEmpty && signupPhone.value.trim().isEmpty) {
      signupEmailError.value = 'Email or phone is required';
      return 'email';
    }
    
    if (signupEmail.value.trim().isNotEmpty && !_isValidEmail(signupEmail.value.trim())) {
      signupEmailError.value = 'Please enter a valid email address';
      return 'email';
    }
    
    // Phone validation
    if (signupPhone.value.trim().isNotEmpty && !_isValidPhone(signupPhone.value.trim())) {
      signupPhoneError.value = 'Please enter a valid phone number';
      return 'phone';
    }
    
    // Password validation
    if (signupPassword.value.isEmpty) {
      signupPasswordError.value = 'Password is required';
      return 'password';
    }
    
    if (signupPassword.value.length < 6) {
      signupPasswordError.value = 'Password must be at least 6 characters';
      return 'password';
    }
    
    // Confirm password validation
    if (signupConfirmPassword.value.isEmpty) {
      signupConfirmPasswordError.value = 'Please confirm your password';
      return 'confirm_password';
    }
    
    if (signupPassword.value != signupConfirmPassword.value) {
      signupConfirmPasswordError.value = 'Passwords do not match';
      return 'confirm_password';
    }
    
    return null; // No validation errors
  }
  
  /// Signup user
  Future<void> signup() async {
    // Client-side validation
    final validationError = _validateSignupForm();
    if (validationError != null) {
      return; // Error already set in the field
    }
    
    isLoading.value = true;
    _clearSignupErrors();
    
    try {
      final response = await _apiService.post(
        ApiEndpoints.register,
        data: {
          'name': signupName.value.trim(),
          'email': signupEmail.value.trim(),
          'phone': signupPhone.value.trim(),
          'password': signupPassword.value,
          'confirm_password': signupConfirmPassword.value,
        },
      );
      
      final data = ApiService.handleResponse(response);
      final user = data['user'] ?? {};
      final token = data['token'] ?? '';
      
      if (token.isEmpty) {
        signupGeneralError.value = 'Registration failed. Please try again.';
        return;
      }
      
      // Save user data
      await CacheManager.setLoggedIn(true);
      await CacheManager.setGuestMode(false);
      await CacheManager.saveUserId(user['id']?.toString() ?? '');
      await CacheManager.saveUserEmail(user['email'] ?? signupEmail.value.trim());
      await CacheManager.saveUserName(user['name'] ?? signupName.value.trim());
      await CacheManager.saveUserPhone(user['phone'] ?? signupPhone.value.trim());
      await CacheManager.saveUserToken(token);
      
      print('[Auth] Signup successful - Refreshing all controllers');
      
      // Refresh all controllers to detect login state
      _refreshAllControllers();
      
      // Clear form
      signupName.value = '';
      signupEmail.value = '';
      signupPhone.value = '';
      signupPassword.value = '';
      signupConfirmPassword.value = '';
      
      // Navigate to home
      AppRoutes.toHome();
    } on DioException catch (e) {
      _handleSignupError(e);
    } on Exception catch (e) {
      // Handle exceptions thrown by handleResponse
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Remove status code part if present (e.g., "Email already registered (Status: 400)")
      if (errorMessage.contains('(Status:')) {
        errorMessage = errorMessage.substring(0, errorMessage.indexOf('(Status:')).trim();
      }
      
      // Map to field-specific errors
      final lowerMessage = errorMessage.toLowerCase();
      if (lowerMessage.contains('email already registered') ||
          lowerMessage.contains('email already exists') ||
          lowerMessage.contains('email is already registered') ||
          lowerMessage.contains('email is already in use')) {
        signupEmailError.value = 'This email is already registered. Please use a different email or try logging in.';
      } else if (lowerMessage.contains('phone already registered') ||
                 lowerMessage.contains('phone already exists') ||
                 lowerMessage.contains('phone number is already registered') ||
                 lowerMessage.contains('phone is already in use')) {
        signupPhoneError.value = 'This phone number is already registered. Please use a different number or try logging in.';
      } else {
        signupGeneralError.value = errorMessage;
      }
      print('Signup error: $e');
    } catch (e) {
      signupGeneralError.value = 'An unexpected error occurred. Please try again.';
      print('Signup error: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Handle signup errors professionally
  void _handleSignupError(DioException error) {
    _clearSignupErrors();
    
    if (error.response != null) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      
      // Handle validation errors (422)
      if (statusCode == 422 && responseData is Map<String, dynamic>) {
        final data = responseData['data'];
        if (data is Map<String, dynamic> && data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          
          // Show first error only (one at a time)
          if (errors.containsKey('name')) {
            signupNameError.value = errors['name'].toString();
          } else if (errors.containsKey('email')) {
            signupEmailError.value = errors['email'].toString();
          } else if (errors.containsKey('phone')) {
            signupPhoneError.value = errors['phone'].toString();
          } else if (errors.containsKey('password')) {
            signupPasswordError.value = errors['password'].toString();
          } else if (errors.containsKey('confirm_password')) {
            signupConfirmPasswordError.value = errors['confirm_password'].toString();
          } else {
            // Get first error
            final firstError = errors.values.first;
            signupGeneralError.value = firstError.toString();
          }
          return;
        }
      }
      
      // Handle other API errors
      String errorMessage = 'An error occurred';
      
      // Extract error message from response
      if (responseData is Map<String, dynamic>) {
        errorMessage = responseData['message'] ?? errorMessage;
      } else if (responseData is String) {
        // Try to parse as JSON if it's a string
        try {
          final parsed = jsonDecode(responseData);
          if (parsed is Map<String, dynamic>) {
            errorMessage = parsed['message'] ?? errorMessage;
          }
        } catch (e) {
          errorMessage = responseData;
        }
      }
      
      // Handle specific status codes
      if (statusCode == 405) {
        signupGeneralError.value = 'Method not allowed. Please contact support if this issue persists.';
        return;
      }
      
      // Map common error messages to field-specific errors
      final lowerMessage = errorMessage.toLowerCase();
      
      if (lowerMessage.contains('email already registered') ||
          lowerMessage.contains('email already exists') ||
          lowerMessage.contains('email is already registered') ||
          lowerMessage.contains('email is already in use')) {
        signupEmailError.value = 'This email is already registered. Please use a different email or try logging in.';
      } else if (lowerMessage.contains('phone already registered') ||
                 lowerMessage.contains('phone already exists') ||
                 lowerMessage.contains('phone number is already registered') ||
                 lowerMessage.contains('phone is already in use')) {
        signupPhoneError.value = 'This phone number is already registered. Please use a different number or try logging in.';
      } else if (lowerMessage.contains('method not allowed')) {
        signupGeneralError.value = 'Server configuration error. Please contact support.';
      } else if (lowerMessage.contains('name') && lowerMessage.contains('required')) {
        signupNameError.value = errorMessage;
      } else if (lowerMessage.contains('email') && lowerMessage.contains('required')) {
        signupEmailError.value = errorMessage;
      } else if (lowerMessage.contains('phone') && lowerMessage.contains('required')) {
        signupPhoneError.value = errorMessage;
      } else if (lowerMessage.contains('password') && lowerMessage.contains('required')) {
        signupPasswordError.value = errorMessage;
      } else if (lowerMessage.contains('password') && lowerMessage.contains('match')) {
        signupConfirmPasswordError.value = errorMessage;
      } else {
        signupGeneralError.value = errorMessage;
      }
    } else {
      // Network errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        signupGeneralError.value = 'Connection timeout. Please check your internet connection.';
      } else if (error.type == DioExceptionType.connectionError) {
        signupGeneralError.value = 'No internet connection. Please check your network.';
      } else {
        signupGeneralError.value = 'Unable to connect to server. Please try again.';
      }
    }
  }
  
  // Forgot Password form
  final RxString forgotPasswordEmail = ''.obs;
  final RxString forgotPasswordError = ''.obs;
  final RxBool isForgotPasswordLoading = false.obs;
  
  // Reset Password form
  final RxString resetToken = ''.obs;
  final RxString newPassword = ''.obs;
  final RxString resetConfirmPassword = ''.obs;
  final RxString resetTokenError = ''.obs;
  final RxString resetPasswordError = ''.obs;
  final RxString resetConfirmPasswordError = ''.obs;
  final RxString resetGeneralError = ''.obs;
  final RxBool isResetPasswordLoading = false.obs;
  
  /// Clear forgot password errors
  void clearForgotPasswordError() {
    forgotPasswordError.value = '';
  }
  
  /// Clear reset password errors
  void _clearResetPasswordErrors() {
    resetTokenError.value = '';
    resetPasswordError.value = '';
    resetConfirmPasswordError.value = '';
    resetGeneralError.value = '';
  }
  
  /// Clear reset password field errors
  void clearResetPasswordError() {
    resetPasswordError.value = '';
    resetGeneralError.value = '';
  }
  
  void clearResetConfirmPasswordError() {
    resetConfirmPasswordError.value = '';
    resetGeneralError.value = '';
  }
  
  /// Forgot Password - Send reset link
  Future<void> forgotPassword() async {
    _clearResetPasswordErrors();
    forgotPasswordError.value = '';
    
    // Client-side validation
    if (forgotPasswordEmail.value.isEmpty) {
      forgotPasswordError.value = 'Email is required';
      return;
    }
    
    if (!GetUtils.isEmail(forgotPasswordEmail.value)) {
      forgotPasswordError.value = 'Please enter a valid email address';
      return;
    }
    
    isForgotPasswordLoading.value = true;
    
    try {
      final response = await _apiService.post(
        ApiEndpoints.forgotPassword,
        data: {
          'email': forgotPasswordEmail.value.trim(),
        },
      );
      
      final responseData = ApiService.handleResponse(response);
      
      // Show success message
      // Get.snackbar(
      //   'Success',
      //   responseData['message'] ?? 'Password reset link sent to your email',
      //   backgroundColor: AppColors.successLight,
      //   colorText: AppColors.success,
      //   duration: const Duration(seconds: 3),
      // );

      // Get reset token from response
      final resetTokenValue = responseData['reset_token'];

      // If token is returned (for testing), navigate to reset password screen
      if (resetTokenValue != null && resetTokenValue.toString().isNotEmpty) {
        // Store token temporarily
        resetToken.value = resetTokenValue.toString();
        // Navigate to new password screen
        await Future.delayed(const Duration(seconds: 1));
        AppRoutes.toNewPassword(resetTokenValue.toString());
      } else {
        // In production, user should check email
        // For now, go back to login
        await Future.delayed(const Duration(seconds: 2));
        AppRoutes.toLogin();
      }
    } on DioException catch (e) {
      _handleForgotPasswordError(e);
    } catch (e) {
      forgotPasswordError.value = 'An unexpected error occurred. Please try again.';
      print('Forgot password error: $e');
    } finally {
      isForgotPasswordLoading.value = false;
    }
  }
  
  /// Handle forgot password errors
  void _handleForgotPasswordError(DioException error) {
    forgotPasswordError.value = '';
    
    if (error.response != null) {
      final responseData = error.response?.data;
      String errorMessage = 'Failed to send reset link';
      
      if (responseData is Map<String, dynamic>) {
        errorMessage = responseData['message'] ?? errorMessage;
      } else if (responseData is String) {
        try {
          final parsed = jsonDecode(responseData);
          if (parsed is Map<String, dynamic>) {
            errorMessage = parsed['message'] ?? errorMessage;
          }
        } catch (e) {
          errorMessage = responseData;
        }
      }
      
      forgotPasswordError.value = errorMessage;
    } else {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        forgotPasswordError.value = 'Connection timeout. Please check your internet connection.';
      } else if (error.type == DioExceptionType.connectionError) {
        forgotPasswordError.value = 'No internet connection. Please check your network.';
      } else {
        forgotPasswordError.value = 'Unable to connect to server. Please try again.';
      }
    }
  }
  
  /// Reset Password - Set new password with token
  Future<void> resetPassword() async {
    _clearResetPasswordErrors();
    
    // Client-side validation
    if (resetToken.value.isEmpty) {
      resetTokenError.value = 'Reset token is required';
      return;
    }
    
    if (newPassword.value.isEmpty) {
      resetPasswordError.value = 'Password is required';
      return;
    }
    
    if (newPassword.value.length < 6) {
      resetPasswordError.value = 'Password must be at least 6 characters';
      return;
    }
    
    if (resetConfirmPassword.value.isEmpty) {
      resetConfirmPasswordError.value = 'Please confirm your password';
      return;
    }
    
    if (newPassword.value != resetConfirmPassword.value) {
      resetConfirmPasswordError.value = 'Passwords do not match';
      return;
    }
    
    isResetPasswordLoading.value = true;
    
    try {
      final response = await _apiService.post(
        ApiEndpoints.resetPassword,
        data: {
          'token': resetToken.value.trim(),
          'password': newPassword.value,
          'confirm_password': resetConfirmPassword.value,
        },
      );
      
      final data = ApiService.handleResponse(response);
      
      // Show success message
      // Get.snackbar(
      //   'Success',
      //   responseData['message'] ?? 'Password reset successful',
      //   backgroundColor: AppColors.successLight,
      //   colorText: AppColors.success,
      //   duration: const Duration(seconds: 2),
      // );

      // Clear form
      resetToken.value = '';
      newPassword.value = '';
      resetConfirmPassword.value = '';

      // Navigate to login
      await Future.delayed(const Duration(seconds: 1));
      AppRoutes.toLogin();
    } on DioException catch (e) {
      _handleResetPasswordError(e);
    } catch (e) {
      resetGeneralError.value = 'An unexpected error occurred. Please try again.';
      print('Reset password error: $e');
    } finally {
      isResetPasswordLoading.value = false;
    }
  }
  
  /// Handle reset password errors
  void _handleResetPasswordError(DioException error) {
    _clearResetPasswordErrors();
    
    if (error.response != null) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      
      // Handle validation errors (422)
      if (statusCode == 422 && responseData is Map<String, dynamic>) {
        final data = responseData['data'];
        if (data is Map<String, dynamic> && data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          
          if (errors.containsKey('token')) {
            resetTokenError.value = errors['token'].toString();
          } else if (errors.containsKey('password')) {
            resetPasswordError.value = errors['password'].toString();
          } else if (errors.containsKey('confirm_password')) {
            resetConfirmPasswordError.value = errors['confirm_password'].toString();
          } else {
            final firstError = errors.values.first;
            resetGeneralError.value = firstError.toString();
          }
          return;
        }
      }
      
      // Handle other API errors
      String errorMessage = 'Password reset failed';
      
      if (responseData is Map<String, dynamic>) {
        errorMessage = responseData['message'] ?? errorMessage;
      } else if (responseData is String) {
        try {
          final parsed = jsonDecode(responseData);
          if (parsed is Map<String, dynamic>) {
            errorMessage = parsed['message'] ?? errorMessage;
          }
        } catch (e) {
          errorMessage = responseData;
        }
      }
      
      // Map error messages
      final lowerMessage = errorMessage.toLowerCase();
      
      if (lowerMessage.contains('token') && 
          (lowerMessage.contains('invalid') || lowerMessage.contains('expired'))) {
        resetTokenError.value = errorMessage;
      } else if (lowerMessage.contains('password') && lowerMessage.contains('required')) {
        resetPasswordError.value = errorMessage;
      } else if (lowerMessage.contains('password') && lowerMessage.contains('match')) {
        resetConfirmPasswordError.value = errorMessage;
      } else {
        resetGeneralError.value = errorMessage;
      }
    } else {
      // Network errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        resetGeneralError.value = 'Connection timeout. Please check your internet connection.';
      } else if (error.type == DioExceptionType.connectionError) {
        resetGeneralError.value = 'No internet connection. Please check your network.';
      } else {
        resetGeneralError.value = 'Unable to connect to server. Please try again.';
      }
    }
  }
  
  /// Logout user
  Future<void> logout() async {
    isLoading.value = true;
    try {
      // Stop notification service first
      if (Get.isRegistered<NotificationService>()) {
        final notificationService = Get.find<NotificationService>();
        notificationService.stopRealTimeUpdates();
      }
      
      await CacheManager.clearUserSessionData();
      await _resetUserControllers();
      await _clearAppState();

      // Navigate to the login screen and remove all previous routes
      AppRoutes.toLogin();

      // Get.snackbar(
      //   'Success',
      //   'You have been logged out successfully.',
      //   backgroundColor: AppColors.primary,
      //   colorText: AppColors.textWhite,
      // );
    } catch (e) {
      print('Logout error: $e');
      // Get.snackbar(
      //   'Error',
      //   'Failed to logout. Please try again.',
      //   backgroundColor: AppColors.accent,
      //   colorText: AppColors.textWhite,
      // );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _resetUserControllers() async {
    try {
      if (Get.isRegistered<CartController>()) {
        final cart = Get.find<CartController>();
        cart.cartItems.clear();
        cart.totalItems.value = 0;
        cart.subtotal.value = 0.0;
      }
      if (Get.isRegistered<WishlistController>()) {
        Get.find<WishlistController>().wishlistItems.clear();
      }
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().clearOnLogout();
      }
      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        home.activeOrdersCount.value = 0;
      }
    } catch (e) {
      print('[AuthController] reset controllers on logout: $e');
    }
  }

  /// Clear app state on logout
  Future<void> _clearAppState() async {
    try {
      // Clear Hive app state box
      if (Hive.isBoxOpen('appState')) {
        final box = Hive.box('appState');
        await box.clear();
        print('[AuthController] Cleared app state on logout');
      }
    } catch (e) {
      print('[AuthController] Error clearing app state: $e');
    }
  }

  // ================== SOCIAL LOGIN ==================

  /// Google Sign-In
  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    generalError.value = '';
    
    try {
      print('[GMAIL DEBUG] ========== STARTING GOOGLE SIGN-IN ==========');
      print('[GMAIL DEBUG] Current timestamp: ${DateTime.now()}');
      
      // Check Google Play Services availability
      print('[GMAIL DEBUG] Checking Google Play Services...');
      try {
        final GoogleSignIn googleSignInTest = GoogleSignIn();
        print('[GMAIL DEBUG] GoogleSignIn instance created successfully');
      } catch (e) {
        print('[GMAIL DEBUG] ERROR creating GoogleSignIn: $e');
        print('[GMAIL DEBUG] This indicates Google Play Services issue');
      }
      
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: Platform.isIOS ? GoogleAuthConfig.iosClientId : null,
        serverClientId: GoogleAuthConfig.webClientId,
      );
      print('[GMAIL DEBUG] GCP project 312606208197');
      print('[GMAIL DEBUG] Android release client: ${GoogleAuthConfig.androidReleaseClientId}');
      print('[GMAIL DEBUG] Android debug client: ${GoogleAuthConfig.androidDebugClientId}');
      print('[GMAIL DEBUG] serverClientId (web): ${GoogleAuthConfig.webClientId}');
      print('[GMAIL DEBUG] iOS clientId: ${GoogleAuthConfig.iosClientId}');
      print('[GMAIL DEBUG] Android SHA-1 (release): ${GoogleAuthConfig.androidReleaseSha1}');
      print('[GMAIL DEBUG] GoogleSignIn initialized with scopes: email, profile');
      
      // Check current user
      final GoogleSignInAccount? currentUser = googleSignIn.currentUser;
      print('[GMAIL DEBUG] Current user: ${currentUser?.email ?? "None"}');
      print('[GMAIL DEBUG] Current user ID: ${currentUser?.id ?? "None"}');
      
      // Sign out first to ensure clean state
      print('[GMAIL DEBUG] Signing out to ensure clean state...');
      await googleSignIn.signOut();
      print('[GMAIL DEBUG] Signed out successfully');
       
      // Trigger Google Sign-In
      print('[GMAIL DEBUG] Triggering sign-in flow...');
      print('[GMAIL DEBUG] This will open Google account picker dialog');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        print('[GMAIL DEBUG] USER CANCELLED - No account selected');
        print('[GMAIL DEBUG] This is normal user behavior, not an error');
        isLoading.value = false;
        return;
      }

      print('[GMAIL DEBUG] ========== SIGN-IN SUCCESSFUL ==========');
      print('[GMAIL DEBUG] Email: ${googleUser.email}');
      print('[GMAIL DEBUG] User ID: ${googleUser.id}');
      print('[GMAIL DEBUG] Display Name: ${googleUser.displayName}');
      print('[GMAIL DEBUG] Photo URL: ${googleUser.photoUrl}');
      print('[GMAIL DEBUG] Server Auth Code: ${googleUser.serverAuthCode ?? "None"}');

      // Get authentication details
      print('[GMAIL DEBUG] Getting authentication details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('[GMAIL DEBUG] ========== AUTHENTICATION DETAILS ==========');
      print('[GMAIL DEBUG] ID Token Present: ${googleAuth.idToken != null}');
      print('[GMAIL DEBUG] ID Token Length: ${googleAuth.idToken?.length ?? 0}');
      print('[GMAIL DEBUG] ID Token (first 50 chars): ${googleAuth.idToken?.substring(0, 50) ?? "Null"}...');
      print('[GMAIL DEBUG] Access Token Present: ${googleAuth.accessToken != null}');
      print('[GMAIL DEBUG] Access Token Length: ${googleAuth.accessToken?.length ?? 0}');
      print('[GMAIL DEBUG] Access Token (first 50 chars): ${googleAuth.accessToken?.substring(0, 50) ?? "Null"}...');
      
      // Validate critical data
      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        print('[GMAIL DEBUG] ERROR: ID Token is null or empty');
        throw Exception('Google ID Token is missing. Please try again.');
      }
      
      if (googleUser.email == null || googleUser.email!.isEmpty) {
        print('[GMAIL DEBUG] ERROR: User email is null or empty');
        throw Exception('Google email is missing. Please try again.');
      }
      
      // Prepare data for backend
      final data = {
        'provider_id': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName ?? 'Google User',
        'photo_url': googleUser.photoUrl,
        'id_token': googleAuth.idToken,
        'access_token': googleAuth.accessToken,
      };
      
      print('[GMAIL DEBUG] ========== BACKEND DATA PREPARED ==========');
      print('[GMAIL DEBUG] Data keys: ${data.keys.toList()}');
      print('[GMAIL DEBUG] Provider ID: ${data['provider_id']}');
      print('[GMAIL DEBUG] Email: ${data['email']}');
      print('[GMAIL DEBUG] Name: ${data['name']}');
      print('[GMAIL DEBUG] Photo URL: ${data['photo_url']}');
      print('[GMAIL DEBUG] ID Token Length: ${(data['id_token'] as String?)?.length ?? 0}');
      print('[GMAIL DEBUG] Access Token Length: ${(data['access_token'] as String?)?.length ?? 0}');
      
      // Send to backend
      print('[GMAIL DEBUG] ========== SENDING TO BACKEND ==========');
      print('[GMAIL DEBUG] Endpoint: ${ApiEndpoints.googleLogin}');
      print('[GMAIL DEBUG] This will validate the Google token on server');
      await _handleSocialLogin(ApiEndpoints.googleLogin, data, 'google');
      
    } catch (e, stackTrace) {
      print('[ERROR] Google Sign-In Error: $e');
      print('[ERROR] Stack trace: $stackTrace');
      
      // Detailed error analysis
      if (e.toString().contains('ApiException: 10')) {
        print('[ERROR] DEVELOPER_ERROR (10) — register SHA-1 in GCP project 312606208197');
        print('[ERROR] Package: ${GoogleAuthConfig.androidPackageName}');
        print('[ERROR] Release SHA-1 / client: ${GoogleAuthConfig.androidReleaseSha1}');
        print('[ERROR] Debug SHA-1 / client: ${GoogleAuthConfig.androidDebugSha1}');
        generalError.value = 'Google Sign-In config error. Check SHA-1 in Google Cloud Console.';
      } else if (e.toString().contains('ApiException: 12501')) {
        print('[ERROR] User cancelled or account selection failed');
      } else if (e.toString().contains('ApiException: 12500')) {
        print('[ERROR] Google Play Services not available or outdated');
        print('[ERROR] Possible fixes:');
        print('[ERROR] 1. Update Google Play Services');
        print('[ERROR] 2. Check device Google account settings');
      } else if (e.toString().contains('network')) {
        print('[ERROR] Network connectivity issue');
      } else {
        print('[ERROR] Unknown Google Sign-In error: $e');
        print('[ERROR] Full error details: ${e.runtimeType}');
      }
      
      generalError.value = 'Google Sign-In failed. Please try again.';
      // Get.snackbar(
      //   'Error',
      //   'Google Sign-In failed. Please try again.',
      //   backgroundColor: AppColors.error,
      //   colorText: AppColors.textWhite,
      // );
    } finally {
      isLoading.value = false;
      print('[DEBUG] Google Sign-In process completed');
    }
  }
  
  /// Apple Sign-In
  Future<void> signInWithApple() async {
    // Only available on iOS
    if (!Platform.isIOS) {
      // Get.snackbar(
      //   'Not Available',
      //   'Apple Sign-In is only available on iOS devices.',
      //   backgroundColor: AppColors.error,
      //   colorText: AppColors.textWhite,
      // );
      return;
    }
    
    isLoading.value = true;
    generalError.value = '';
    
    try {
      // Request credentials from Apple
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      // Prepare data for backend
      final data = {
        'provider_id': credential.userIdentifier ?? '',
        'email': credential.email,
        'name': credential.givenName != null || credential.familyName != null
            ? '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim()
            : null,
        'authorization_code': credential.authorizationCode,
        'identity_token': credential.identityToken,
      };
      
      // Validate we have the required provider_id
      if (data['provider_id'] == null || (data['provider_id'] as String).isEmpty) {
        generalError.value = 'Unable to get Apple ID. Please try again.';
        isLoading.value = false;
        return;
      }
      
      // Send to backend
      await _handleSocialLogin(ApiEndpoints.appleLogin, data, 'apple');
      
    } on SignInWithAppleAuthorizationException catch (e) {
      print('Apple Sign-In Authorization Error: ${e.code} - ${e.message}');
      if (e.code != AuthorizationErrorCode.canceled) {
        generalError.value = 'Apple Sign-In was cancelled or failed.';
        Get.snackbar(
          'Error',
          'Apple Sign-In failed. Please try again.',
          backgroundColor: AppColors.error,
          colorText: AppColors.textWhite,
        );
      }
    } catch (e) {
      print('Apple Sign-In Error: $e');
      generalError.value = 'Apple Sign-In failed. Please try again.';
      Get.snackbar(
        'Error',
        'Apple Sign-In failed. Please try again.',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Handle social login response and save user data
  Future<void> _handleSocialLogin(String endpoint, Map<String, dynamic> data, String provider) async {
    try {
      print('[GMAIL DEBUG] ========== BACKEND REQUEST STARTED ==========');
      print('[GMAIL DEBUG] Provider: $provider');
      print('[GMAIL DEBUG] Endpoint: $endpoint');
      print('[GMAIL DEBUG] Request data keys: ${data.keys.toList()}');
      
      // Make API request
      print('[GMAIL DEBUG] Making POST request to backend...');
      final response = await _apiService.post(
        endpoint,
        data: data,
      );
      
      print('[GMAIL DEBUG] ========== BACKEND RESPONSE RECEIVED ==========');
      print('[GMAIL DEBUG] Response status code: ${response.statusCode}');
      print('[GMAIL DEBUG] Response data type: ${response.data.runtimeType}');
      print('[GMAIL DEBUG] Response data: ${response.data}');
      
      final responseData = ApiService.handleResponse(response);
      print('[GMAIL DEBUG] Processed response data: $responseData');
      
      final user = responseData['user'] ?? {};
      final token = responseData['token'] ?? '';
      
      print('[GMAIL DEBUG] ========== RESPONSE DATA VALIDATION ==========');
      print('[GMAIL DEBUG] User data: $user');
      print('[GMAIL DEBUG] Token present: ${token.isNotEmpty}');
      print('[GMAIL DEBUG] Token length: ${token.length}');
      print('[GMAIL DEBUG] User ID: ${user['id']}');
      print('[GMAIL DEBUG] User email: ${user['email']}');
      print('[GMAIL DEBUG] User name: ${user['name']}');
      
      if (token.isEmpty) {
        print('[GMAIL DEBUG] ERROR: Token is empty from backend');
        generalError.value = 'Login failed. Please try again.';
        signupGeneralError.value = 'Login failed. Please try again.';
        return;
      }
      
      // Save user data
      print('[GMAIL DEBUG] ========== SAVING USER DATA ==========');
      await CacheManager.setLoggedIn(true);
      await CacheManager.setGuestMode(false);
      await CacheManager.saveUserId(user['id']?.toString() ?? '');
      await CacheManager.saveUserEmail(user['email'] ?? '');
      await CacheManager.saveUserName(user['name'] ?? '');
      await CacheManager.saveUserPhone(user['phone'] ?? '');
      await CacheManager.saveUserToken(token);
      
      print('[GMAIL DEBUG] User data saved successfully');
      print('[GMAIL DEBUG] Social login successful - Refreshing all controllers');
      
      // Refresh all controllers to detect login state
      _refreshAllControllers();
      
      // Clear form
      email.value = '';
      password.value = '';
      
      print('[GMAIL DEBUG] ========== LOGIN SUCCESSFUL ==========');
      // Show success message
      Get.snackbar(
        'Success',
        'Login successful with ${provider == 'google' ? 'Google' : 'Apple'}!',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
        duration: const Duration(seconds: 2),
      );
      
      // Navigate to home
      print('[GMAIL DEBUG] Navigating to home screen...');
      AppRoutes.toHome();
      
    } on DioException catch (e) {
      print('[GMAIL DEBUG] ========== DIO EXCEPTION ==========');
      print('[GMAIL DEBUG] Exception type: ${e.type}');
      print('[GMAIL DEBUG] Exception message: ${e.message}');
      print('[GMAIL DEBUG] Response status: ${e.response?.statusCode}');
      print('[GMAIL DEBUG] Response data: ${e.response?.data}');
      print('[GMAIL DEBUG] Request options: ${e.requestOptions}');
      _handleSocialLoginError(e, provider);
    } catch (e, stackTrace) {
      print('[GMAIL DEBUG] ========== UNEXPECTED ERROR ==========');
      print('[GMAIL DEBUG] Error: $e');
      print('[GMAIL DEBUG] Error type: ${e.runtimeType}');
      print('[GMAIL DEBUG] Stack trace: $stackTrace');
      generalError.value = 'An unexpected error occurred. Please try again.';
      signupGeneralError.value = 'An unexpected error occurred. Please try again.';
    }
  }
  
  /// Handle social login errors
  void _handleSocialLoginError(DioException error, String provider) {
    generalError.value = '';
    signupGeneralError.value = '';
    
    if (error.response != null) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      
      debugPrint('[$provider] Login error status: $statusCode');
      
      String errorMessage = 'An error occurred';
      
      if (responseData is Map<String, dynamic>) {
        errorMessage = responseData['message'] ?? errorMessage;
      }
      
      final lowerMessage = errorMessage.toLowerCase();
      
      if (lowerMessage.contains('inactive') ||
          lowerMessage.contains('suspended') ||
          lowerMessage.contains('disabled')) {
        generalError.value = 'Your account is inactive. Please contact support.';
        signupGeneralError.value = 'Your account is inactive. Please contact support.';
      } else {
        generalError.value = errorMessage;
        signupGeneralError.value = errorMessage;
      }
    } else {
      // Network errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        generalError.value = 'Connection timeout. Please check your internet connection.';
        signupGeneralError.value = 'Connection timeout. Please check your internet connection.';
      } else if (error.type == DioExceptionType.connectionError) {
        generalError.value = 'No internet connection. Please check your network.';
        signupGeneralError.value = 'No internet connection. Please check your network.';
      } else {
        generalError.value = 'Unable to connect to server. Please try again.';
        signupGeneralError.value = 'Unable to connect to server. Please try again.';
      }
    }
    
    Get.snackbar(
      'Error',
      generalError.value.isNotEmpty ? generalError.value : 'Login failed. Please try again.',
      backgroundColor: AppColors.error,
      colorText: AppColors.textWhite,
    );
  }
  
  /// Refresh all controllers after login/signup to detect new auth state
  void _refreshAllControllers() {
    print('[Auth] Refreshing all controllers for new auth state');
    
    try {
      // Refresh Cart Controller if exists
      if (Get.isRegistered<CartController>()) {
        Get.find<CartController>().loadCart();
        print('[Auth] Cart Controller refreshed');
      }
      
      // Refresh Wishlist Controller if exists
      if (Get.isRegistered<WishlistController>()) {
        Get.find<WishlistController>().loadWishlist();
        print('[Auth] Wishlist Controller refreshed');
      }
      
      // Refresh Profile Controller if exists
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().loadUserProfile();
        print('[Auth] Profile Controller refreshed');
      }
      
      // Refresh Home Controller if exists
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadHomeData();
        print('[Auth] Home Controller refreshed');
      }

      if (Get.isRegistered<NotificationService>()) {
        Get.find<NotificationService>()
          ..startRealTimeUpdates()
          ..pollNow();
        print('[Auth] Notification polling started');
      }
      
      print('[Auth] All controllers refreshed successfully');
    } catch (e) {
      print('[Auth] Error refreshing controllers: $e');
    }
  }
}
