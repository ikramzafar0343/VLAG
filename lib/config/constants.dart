/// Application Constants
/// Centralized constants for the VLagIt application
library;

import 'app_config.dart';

// ============================================================================
// URLs & Links
// ============================================================================

/// Web app URL
const String kWebappUrl = 'vlagit.com';

/// Page URL (for dynamic links)
const String kPageUrl = 'vlagit.com';

/// VLag create URL
final String kVLagCreate = AppConfig.profileCreateUrl;

/// VLag view prefix
final String kVLagViewPrefix = AppConfig.profileViewPrefix;

/// Play Store URL
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.VLagit.VLag';

/// Bitly Privacy Policy
const String kBitlyPrivacyPolicyLink = 'https://bitly.com/pages/privacy';

/// Bitly Terms of Service
const String kBitlyTermsOfService = 'https://bitly.com/pages/terms-of-service';

// ============================================================================
// Mobile Ads Configuration
// ============================================================================

/// Test device IDs for AdMob
const String kTestDeviceId1 = '544FB3234D373268D3A6DB803850CDFB'; // J7
const String kTestDeviceId2 = 'DF693493239FEF390746FE861B201FC3'; // YES
const String kTestDeviceId3 = '5BF49B5666B0C509C03B9E26F4DA9DDD'; // Note 11

/// Max failed load attempts for ads
const int kMaxFailedLoadAttempts = 3;

// ============================================================================
// Hive Storage Keys
// ============================================================================

/// Main Hive box name
const String kMainBoxName = 'app';

/// Has Firebase Dynamic Link
const String kHasFdlLink = 'hasFdlLink';

/// Firebase Dynamic Link
const String kFdlLink = 'fdlLink';

/// Has Bitly Link
const String kHasBitlyLink = 'hasBitlyLink';

/// Bitly Link
const String kBitlyLink = 'bitlyLink';

/// Has agreed to consent
const String kHasAgreeConsent = 'agreeConsent';

// ============================================================================
// API Configuration
// ============================================================================

/// Bitly API authority
const String kBitlyApiAuthority = 'https://api-ssl.bitly.com/v4';

/// API timeout in milliseconds
const int kApiTimeoutMs = 30000;

// ============================================================================
// App Metadata
// ============================================================================

/// App name
const String kAppName = 'VLag';

/// App description
const String kAppDescription =
    'Let your audiences find you in one place. VLag is an app that let you create, manage, publish a colourful links page to the world!';

/// App tagline
const String kAppTagline = 'A place for all of your social links';
