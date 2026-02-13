/// API Service for VLagIt Backend
/// Handles all server API communication
library;

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../utils/snackbar.dart';
import 'package:flutter/material.dart';

/// API Service Class
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;

  /// Initialize API service
  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(seconds: AppConfig.apiTimeoutSeconds),
        receiveTimeout: Duration(seconds: AppConfig.apiTimeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and error handling
    if (AppConfig.enableDebugLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }

    // Add error interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        _handleError(error);
        return handler.next(error);
      },
    ));
  }

  /// Handle API errors
  void _handleError(DioException error) {
    if (AppConfig.enableDebugLogging) {
      debugPrint('API Error: ${error.message}');
      debugPrint('Response: ${error.response?.data}');
    }
  }

  /// Health check
  Future<Map<String, dynamic>?> healthCheck() async {
    try {
      final response = await _dio.get(AppConfig.healthCheckEndpoint);
      return response.data;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Health check failed: $e');
      }
      return null;
    }
  }

  /// Check if user is verified
  Future<bool> checkVerifiedStatus(String userId) async {
    try {
      final response = await _dio.get(
        '${AppConfig.verifiedBadgeEndpoint}/$userId',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['verified'] ?? false;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to check verified status: $e');
      }
      return false;
    }
  }

  /// Submit a report
  Future<bool> submitReport({
    required String userId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        AppConfig.reportEndpoint,
        data: {
          'userId': userId,
          'reportedUserId': reportedUserId,
          'reason': reason,
          'description': description ?? '',
        },
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to submit report: $e');
      }
      return false;
    }
  }

  /// Get user analytics
  Future<Map<String, dynamic>?> getUserAnalytics(String userId) async {
    try {
      final response = await _dio.get(
        '${AppConfig.analyticsEndpoint}/$userId',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get analytics: $e');
      }
      return null;
    }
  }

  Future<String?> uploadProfileImage(XFile file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    final idToken = await user.getIdToken();
    final filename = file.name.isNotEmpty ? file.name : 'profile.jpg';

    final FormData formData;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
    } else {
      formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: filename),
      });
    }

    try {
      final response = await _dio.post(
        AppConfig.profileImageUploadEndpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Authorization': 'Bearer $idToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']?['url'] as String?;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to upload profile image: $e');
      }
    }
    return null;
  }

  /// Show error message to user
  void showApiError(BuildContext? context, String message) {
    if (context != null) {
      CustomSnack.showErrorSnack(context, message: message);
    }
  }
}

/// Global API service instance
final apiService = ApiService();
