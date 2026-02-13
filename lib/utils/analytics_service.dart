import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/analytics_model.dart';
import '../model/my_user.dart';

/// Firestore collection paths for analytics
class AnalyticsPaths {
  static const String users = 'users';
  static const String analytics = 'analytics';
  static const String summary = 'summary';
  static const String links = 'links';
  static const String analyticsEvents = 'analytics_events';

  /// Get path to user's analytics summary document
  static String summaryDoc(String profileCode) =>
      '$users/$profileCode/$analytics/$summary';

  /// Get path to user's link analytics collection
  static String linksCollection(String profileCode) =>
      '$users/$profileCode/$analytics/$summary/$links';

  /// Get path to specific link analytics document
  static String linkDoc(String profileCode, String linkId) =>
      '$users/$profileCode/$analytics/$summary/$links/$linkId';
}

/// Service for tracking and retrieving analytics data
class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache to prevent duplicate tracking within short time window
  static final Map<String, DateTime> _viewCache = {};
  static const Duration _cacheExpiry = Duration(seconds: 60);

  /// Get current user's profile code - uses MyUser for consistency
  static String? get _currentProfileCode {
    final user = _auth.currentUser;
    if (user == null) return null;
    // Use the same profile code that MyUser uses
    try {
      return MyUser.profileCode;
    } catch (e) {
      // Fallback if MyUser is not initialized yet
      return user.uid.substring(0, 5);
    }
  }

  /// Track a profile view
  /// [profileOwnerCode] - The profile code of the profile being viewed
  static Future<void> trackProfileView(String profileOwnerCode) async {
    // Check cache to prevent duplicate views
    final cacheKey = 'view_$profileOwnerCode';
    if (_isRecentlyTracked(cacheKey)) {
      return;
    }

    try {
      final now = DateTime.now();
      final dateKey = _getDateKey(now);
      final yearKey = now.year.toString();

      final summaryRef = _firestore
          .collection('users')
          .doc(profileOwnerCode)
          .collection('analytics')
          .doc('summary');

      // Use transaction to safely increment counters
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(summaryRef);

        if (snapshot.exists) {
          final data = snapshot.data() ?? {};
          final currentTotal = (data['totalViews'] as int?) ?? 0;

          // Get current daily views map
          final dailyViews =
              Map<String, dynamic>.from(data['dailyViews'] as Map? ?? {});
          final currentDailyCount = (dailyViews[dateKey] as int?) ?? 0;

          // Get current yearly views map
          final yearlyViews =
              Map<String, dynamic>.from(data['yearlyViews'] as Map? ?? {});
          final currentYearlyCount = (yearlyViews[yearKey] as int?) ?? 0;

          transaction.update(summaryRef, {
            'totalViews': currentTotal + 1,
            'dailyViews.$dateKey': currentDailyCount + 1,
            'yearlyViews.$yearKey': currentYearlyCount + 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new summary document
          transaction.set(summaryRef, {
            'totalViews': 1,
            'dailyViews': {dateKey: 1},
            'yearlyViews': {yearKey: 1},
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      // Log the event
      await _logEvent(
        uid: profileOwnerCode,
        type: AnalyticsEventType.profileView,
      );

      // Update cache
      _viewCache[cacheKey] = now;
    } catch (e) {
      print('Error tracking profile view: $e');
    }
  }

  /// Track a link click
  /// [profileOwnerCode] - The profile code of the profile owner
  /// [linkId] - Unique identifier for the link (can be URL hash or custom ID)
  /// [title] - Display title of the link
  /// [url] - The URL that was clicked
  static Future<void> trackLinkClick({
    required String profileOwnerCode,
    required String linkId,
    required String title,
    required String url,
  }) async {
    // Check cache to prevent duplicate clicks
    final cacheKey = 'click_${profileOwnerCode}_$linkId';
    if (_isRecentlyTracked(cacheKey)) {
      return;
    }

    try {
      final now = DateTime.now();

      final linkRef = _firestore
          .collection('users')
          .doc(profileOwnerCode)
          .collection('analytics')
          .doc('summary')
          .collection('links')
          .doc(linkId);

      // Use transaction to safely increment click counter
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(linkRef);

        if (snapshot.exists) {
          final data = snapshot.data() ?? {};
          final currentClicks = (data['clickCount'] as int?) ?? 0;

          transaction.update(linkRef, {
            'clickCount': currentClicks + 1,
            'lastClickedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new link analytics document
          transaction.set(linkRef, {
            'title': title,
            'url': url,
            'clickCount': 1,
            'lastClickedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Log the event
      await _logEvent(
        uid: profileOwnerCode,
        type: AnalyticsEventType.linkClick,
        linkId: linkId,
      );

      // Update cache
      _viewCache[cacheKey] = now;
    } catch (e) {
      print('Error tracking link click: $e');
    }
  }

  /// Log an analytics event for audit/history purposes
  static Future<void> _logEvent({
    required String uid,
    required AnalyticsEventType type,
    String? linkId,
  }) async {
    try {
      final event = AnalyticsEvent(
        uid: uid,
        type: type,
        linkId: linkId,
      );

      await _firestore
          .collection(AnalyticsPaths.analyticsEvents)
          .add(event.toMap());
    } catch (e) {
      print('Error logging analytics event: $e');
    }
  }

  /// Check if a tracking event was recently recorded (within cache expiry)
  static bool _isRecentlyTracked(String cacheKey) {
    final lastTracked = _viewCache[cacheKey];
    if (lastTracked == null) return false;

    final now = DateTime.now();
    return now.difference(lastTracked) < _cacheExpiry;
  }

  /// Get date key in yyyy-MM-dd format
  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get analytics summary for current user
  static Stream<AnalyticsSummary> getAnalyticsSummaryStream() {
    final profileCode = _currentProfileCode;
    if (profileCode == null) {
      return Stream.value(AnalyticsSummary());
    }

    return _firestore
        .collection('users')
        .doc(profileCode)
        .collection('analytics')
        .doc('summary')
        .snapshots()
        .map((snapshot) => AnalyticsSummary.fromMap(snapshot.data()));
  }

  /// Get analytics summary for a specific profile code
  static Stream<AnalyticsSummary> getAnalyticsSummaryStreamFor(
      String profileCode) {
    return _firestore
        .collection('users')
        .doc(profileCode)
        .collection('analytics')
        .doc('summary')
        .snapshots()
        .map((snapshot) => AnalyticsSummary.fromMap(snapshot.data()));
  }

  /// Get link analytics for current user
  static Stream<List<LinkAnalytics>> getLinkAnalyticsStream() {
    final profileCode = _currentProfileCode;
    if (profileCode == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(profileCode)
        .collection('analytics')
        .doc('summary')
        .collection('links')
        .orderBy('clickCount', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LinkAnalytics.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get combined dashboard analytics for current user
  static Stream<DashboardAnalytics> getDashboardAnalyticsStream() {
    final profileCode = _currentProfileCode;
    if (profileCode == null) {
      return Stream.value(DashboardAnalytics(
        summary: AnalyticsSummary(),
        linkStats: [],
      ));
    }
    return getDashboardAnalyticsStreamFor(profileCode);
  }

  /// Get combined dashboard analytics for a specific profile code
  static Stream<DashboardAnalytics> getDashboardAnalyticsStreamFor(String profileCode) {
    // Combine both streams
    return getAnalyticsSummaryStreamFor(profileCode).asyncMap((summary) async {
      final linksSnapshot = await _firestore
          .collection('users')
          .doc(profileCode)
          .collection('analytics')
          .doc('summary')
          .collection('links')
          .orderBy('clickCount', descending: true)
          .get();

      final linkStats = linksSnapshot.docs
          .map((doc) => LinkAnalytics.fromMap(doc.id, doc.data()))
          .toList();

      return DashboardAnalytics(
        summary: summary,
        linkStats: linkStats,
      );
    });
  }

  /// Get one-time dashboard analytics (non-stream)
  static Future<DashboardAnalytics> getDashboardAnalytics() async {
    final profileCode = _currentProfileCode;
    if (profileCode == null) {
      return DashboardAnalytics(
        summary: AnalyticsSummary(),
        linkStats: [],
      );
    }

    // Get summary
    final summarySnapshot = await _firestore
        .collection('users')
        .doc(profileCode)
        .collection('analytics')
        .doc('summary')
        .get();

    final summary = AnalyticsSummary.fromMap(summarySnapshot.data());

    // Get links
    final linksSnapshot = await _firestore
        .collection('users')
        .doc(profileCode)
        .collection('analytics')
        .doc('summary')
        .collection('links')
        .orderBy('clickCount', descending: true)
        .get();

    final linkStats = linksSnapshot.docs
        .map((doc) => LinkAnalytics.fromMap(doc.id, doc.data()))
        .toList();

    return DashboardAnalytics(
      summary: summary,
      linkStats: linkStats,
    );
  }

  /// Clear tracking cache (useful for testing)
  static void clearCache() {
    _viewCache.clear();
  }

  /// Generate a unique link ID from URL
  static String generateLinkId(String url) {
    // Use a hash of the URL as the link ID
    return url.hashCode.abs().toString();
  }
}
