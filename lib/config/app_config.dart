/// App Configuration
/// Handles environment-based configuration (dev/production)
/// 
/// Usage:
/// - Development: Uses default values or .env file
/// - Production: Uses production server URLs
library;

import 'package:flutter/foundation.dart' show kDebugMode;

/// Environment type
enum Environment {
  development,
  production,
}

/// Current environment - automatically detects based on build mode
final Environment currentEnvironment = kDebugMode
    ? Environment.development
    : Environment.production;

/// App Configuration Class
class AppConfig {
  // Private constructor
  AppConfig._();

  /// Base API URL for backend server
  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'https://api.vlagit.com';
      case Environment.production:
        return 'https://api.vlagit.com';
    }
  }

  /// Web app base URL
  static String get webBaseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'https://vlagit.com';
      case Environment.production:
        return 'https://vlagit.com';
    }
  }

  /// Profile view URL prefix
  static String get profileViewPrefix {
    return '$webBaseUrl/';
  }

  /// Profile create URL
  static String get profileCreateUrl {
    return webBaseUrl;
  }

  /// API endpoints
  static String get verifiedBadgeEndpoint => '$apiBaseUrl/verified';
  static String get reportEndpoint => '$apiBaseUrl/report';
  static String get analyticsEndpoint => '$apiBaseUrl/analytics';
  static String get healthCheckEndpoint => '$apiBaseUrl/health';
  static String get profileImageUploadEndpoint => '$apiBaseUrl/upload/profile-image';

  static bool get useCpanelProfileImages => true;

  /// Firebase configuration
  /// Note: Firebase config is in firebase_options.dart
  /// This is just for reference
  static bool get useFirebase => true;

  /// Enable debug logging
  static bool get enableDebugLogging => currentEnvironment == Environment.development;

  /// API timeout in seconds
  static const int apiTimeoutSeconds = 30;

  /// Max retry attempts for API calls
  static const int maxRetryAttempts = 3;
}
