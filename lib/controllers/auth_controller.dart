import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../routes/app_routes.dart';
import '../utils/cache_manager.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import '../services/api_endpoints.dart';

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

      if (token.isEmpty) {
        generalError.value = 'Login failed. Please try again.';
        return;
      }
      
      // Save user data
      await CacheManager.setLoggedIn(true);
      await CacheManager.saveUserId(user['id']?.toString() ?? '');
      await CacheManager.saveUserEmail(user['email'] ?? email.value.trim());
      await CacheManager.saveUserName(user['name'] ?? '');
      await CacheManager.saveUserPhone(user['phone'] ?? '');
      await CacheManager.saveUserToken(token);
      
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
      await CacheManager.saveUserId(user['id']?.toString() ?? '');
      await CacheManager.saveUserEmail(user['email'] ?? signupEmail.value.trim());
      await CacheManager.saveUserName(user['name'] ?? signupName.value.trim());
      await CacheManager.saveUserPhone(user['phone'] ?? signupPhone.value.trim());
      await CacheManager.saveUserToken(token);
      
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
      
      final data = ApiService.handleResponse(response);
      
      if (data['success'] == true) {
        final responseData = data['data'] ?? {};
        final resetTokenValue = responseData['reset_token'];
        
        // Show success message
        Get.snackbar(
          'Success',
          data['message'] ?? 'Password reset link sent to your email',
          backgroundColor: AppColors.successLight,
          colorText: AppColors.success,
          duration: const Duration(seconds: 3),
        );
        
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
      
      if (data['success'] == true) {
        // Show success message
        Get.snackbar(
          'Success',
          data['message'] ?? 'Password reset successful',
          backgroundColor: AppColors.successLight,
          colorText: AppColors.success,
          duration: const Duration(seconds: 2),
        );
        
        // Clear form
        resetToken.value = '';
        newPassword.value = '';
        resetConfirmPassword.value = '';
        
        // Navigate to login
        await Future.delayed(const Duration(seconds: 1));
        AppRoutes.toLogin();

  }

  /// Logout user
  Future<void> logout() async {
    isLoading.value = true;
    try {
      // Clear all user data from local storage
      await CacheManager.clearUserData();

      // Navigate to the login screen and remove all previous routes
      AppRoutes.toLogin();

      // Optionally, dispose of controllers if they are not needed after logout
      // Get.delete<AuthController>(); // Only if you want to re-initialize AuthController on next login

      Get.snackbar(
        'Success',
        'You have been logged out successfully.',
        backgroundColor: AppColors.primary,
        colorText: AppColors.textWhite,
      );
    } catch (e) {
     print('Logout error: $e');
      Get.snackbar(
        'Error',
        'Failed to logout. Please try again.',
        backgroundColor: AppColors.accent,
        colorText: AppColors.textWhite,
      );
    } finally {
      isLoading.value = false;
    }
  }
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
    await CacheManager.clearUserData();
    AppRoutes.toLogin();
  }
}
