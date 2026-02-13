import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for analytics summary data
class AnalyticsSummary {
  final int totalViews;
  final Map<String, int> yearlyViews; // key: yyyy, value: count
  final Map<String, int> dailyViews; // key: yyyy-MM-dd, value: count
  final DateTime? lastUpdated;

  AnalyticsSummary({
    this.totalViews = 0,
    Map<String, int>? yearlyViews,
    Map<String, int>? dailyViews,
    this.lastUpdated,
  })  : yearlyViews = yearlyViews ?? {},
        dailyViews = dailyViews ?? {};

  factory AnalyticsSummary.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return AnalyticsSummary();
    }

    return AnalyticsSummary(
      totalViews: data['totalViews'] as int? ?? 0,
      yearlyViews: _convertToIntMap(data['yearlyViews']),
      dailyViews: _convertToIntMap(data['dailyViews']),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, int> _convertToIntMap(dynamic data) {
    if (data == null) return {};
    if (data is Map) {
      return Map<String, int>.from(
        data.map((key, value) => MapEntry(key.toString(), (value as num).toInt())),
      );
    }
    return {};
  }

  Map<String, dynamic> toMap() {
    return {
      'totalViews': totalViews,
      'yearlyViews': yearlyViews,
      'dailyViews': dailyViews,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// Get views for today
  int get todayViews {
    final todayKey = _getDateKey(DateTime.now());
    return dailyViews[todayKey] ?? 0;
  }

  /// Get views for yesterday
  int get yesterdayViews {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayKey = _getDateKey(yesterday);
    return dailyViews[yesterdayKey] ?? 0;
  }

  /// Get views for this year
  int get thisYearViews {
    final yearKey = DateTime.now().year.toString();
    return yearlyViews[yearKey] ?? 0;
  }

  /// Get views for this week (last 7 days)
  int get thisWeekViews {
    int total = 0;
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _getDateKey(date);
      total += dailyViews[dateKey] ?? 0;
    }
    return total;
  }

  /// Get views for this month
  int get thisMonthViews {
    int total = 0;
    final now = DateTime.now();
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    dailyViews.forEach((key, value) {
      if (key.startsWith(monthPrefix)) {
        total += value;
      }
    });
    return total;
  }

  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Model for individual link analytics
class LinkAnalytics {
  final String linkId;
  final String title;
  final String url;
  final int clickCount;
  final DateTime? lastClickedAt;

  LinkAnalytics({
    required this.linkId,
    required this.title,
    required this.url,
    this.clickCount = 0,
    this.lastClickedAt,
  });

  factory LinkAnalytics.fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) {
      return LinkAnalytics(linkId: id, title: '', url: '');
    }

    return LinkAnalytics(
      linkId: id,
      title: data['title'] as String? ?? '',
      url: data['url'] as String? ?? '',
      clickCount: data['clickCount'] as int? ?? 0,
      lastClickedAt: (data['lastClickedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
      'clickCount': clickCount,
      'lastClickedAt': lastClickedAt != null
          ? Timestamp.fromDate(lastClickedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  LinkAnalytics copyWith({
    String? linkId,
    String? title,
    String? url,
    int? clickCount,
    DateTime? lastClickedAt,
  }) {
    return LinkAnalytics(
      linkId: linkId ?? this.linkId,
      title: title ?? this.title,
      url: url ?? this.url,
      clickCount: clickCount ?? this.clickCount,
      lastClickedAt: lastClickedAt ?? this.lastClickedAt,
    );
  }
}

/// Model for analytics events (for event logging)
class AnalyticsEvent {
  final String? eventId;
  final String uid;
  final AnalyticsEventType type;
  final String? linkId;
  final DateTime timestamp;
  final String dateKey; // yyyy-MM-dd
  final String yearKey; // yyyy

  AnalyticsEvent({
    this.eventId,
    required this.uid,
    required this.type,
    this.linkId,
    DateTime? timestamp,
  })  : timestamp = timestamp ?? DateTime.now(),
        dateKey = _getDateKey(timestamp ?? DateTime.now()),
        yearKey = (timestamp ?? DateTime.now()).year.toString();

  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  factory AnalyticsEvent.fromMap(String id, Map<String, dynamic> data) {
    return AnalyticsEvent(
      eventId: id,
      uid: data['uid'] as String? ?? '',
      type: AnalyticsEventType.fromString(data['type'] as String? ?? ''),
      linkId: data['linkId'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'type': type.value,
      'linkId': linkId,
      'timestamp': FieldValue.serverTimestamp(),
      'dateKey': dateKey,
      'yearKey': yearKey,
    };
  }
}

/// Event types for analytics
enum AnalyticsEventType {
  profileView('profile_view'),
  linkClick('link_click');

  final String value;
  const AnalyticsEventType(this.value);

  static AnalyticsEventType fromString(String value) {
    return AnalyticsEventType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AnalyticsEventType.profileView,
    );
  }
}

/// Aggregate analytics data for dashboard
class DashboardAnalytics {
  final AnalyticsSummary summary;
  final List<LinkAnalytics> linkStats;

  DashboardAnalytics({
    required this.summary,
    required this.linkStats,
  });

  /// Get top performing links sorted by click count
  List<LinkAnalytics> get topLinks {
    final sorted = List<LinkAnalytics>.from(linkStats);
    sorted.sort((a, b) => b.clickCount.compareTo(a.clickCount));
    return sorted;
  }

  /// Get total link clicks
  int get totalLinkClicks {
    return linkStats.fold(0, (total, link) => total + link.clickCount);
  }
}
