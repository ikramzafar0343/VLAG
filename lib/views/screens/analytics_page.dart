import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../model/analytics_model.dart';
import '../../model/my_user.dart';
import '../../utils/analytics_service.dart';
import '../widgets/reuseable.dart';

class AnalyticsPage extends StatelessWidget {
  /// Optional profile code - if not provided, uses current user's profile code
  final String? profileCode;
  
  const AnalyticsPage({super.key, this.profileCode});

  @override
  Widget build(BuildContext context) {
    // Use provided profile code or current user's profile code
    final userProfileCode = profileCode ?? MyUser.profileCode;
    
    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        centerTitle: true,
        title: const Text('Analytics Dashboard'),
      ),
      body: StreamBuilder<DashboardAnalytics>(
        stream: AnalyticsService.getDashboardAnalyticsStreamFor(userProfileCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FaIcon(FontAwesomeIcons.circleExclamation,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading analytics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final analytics = snapshot.data ??
              DashboardAnalytics(
                summary: AnalyticsSummary(),
                linkStats: [],
              );

          return RefreshIndicator(
            onRefresh: () async {
              // Force refresh by clearing cache
              AnalyticsService.clearCache();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Stats Grid
                  _buildStatsOverview(context, analytics.summary),
                  const SizedBox(height: 24),

                  // Time-based Stats
                  _buildTimeStats(context, analytics.summary),
                  const SizedBox(height: 24),

                  // Link Performance
                  _buildLinkPerformance(context, analytics),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context, AnalyticsSummary summary) {
    final hasData = summary.totalViews > 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: FontAwesomeIcons.eye,
                iconColor: Colors.blue,
                title: 'Total Views',
                value: hasData ? _formatNumber(summary.totalViews) : '0',
                subtitle: 'All time',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: FontAwesomeIcons.calendarDay,
                iconColor: Colors.green,
                title: 'Today',
                value: hasData ? _formatNumber(summary.todayViews) : '0',
                subtitle: 'Profile views',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeStats(BuildContext context, AnalyticsSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: FontAwesomeIcons.clock,
                iconColor: Colors.orange,
                title: 'Yesterday',
                value: _formatNumber(summary.yesterdayViews),
                subtitle: 'Views',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: FontAwesomeIcons.calendarWeek,
                iconColor: Colors.purple,
                title: 'This Week',
                value: _formatNumber(summary.thisWeekViews),
                subtitle: 'Views',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: FontAwesomeIcons.calendarDays,
                iconColor: Colors.teal,
                title: 'This Month',
                value: _formatNumber(summary.thisMonthViews),
                subtitle: 'Views',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: FontAwesomeIcons.chartLine,
                iconColor: Colors.indigo,
                title: 'This Year',
                value: _formatNumber(summary.thisYearViews),
                subtitle: 'Views',
              ),
            ),
          ],
        ),
        // Show message if no data yet
        if (summary.totalViews == 0)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).hintColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Share your profile link to start tracking views!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLinkPerformance(
      BuildContext context, DashboardAnalytics analytics) {
    final topLinks = analytics.topLinks;
    const primaryGreen = Color(0xFF1DB877);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.chartColumn,
                    size: 16,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Link Performance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.handPointer,
                    size: 12,
                    color: primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatNumber(analytics.totalLinkClicks)} clicks',
                    style: const TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (topLinks.isEmpty)
          _buildEmptyLinksState(context)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topLinks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final link = topLinks[index];
              return _LinkStatCard(
                rank: index + 1,
                link: link,
                totalClicks: analytics.totalLinkClicks,
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyLinksState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        children: [
          FaIcon(
            FontAwesomeIcons.link,
            size: 48,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No link data yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Click data will appear here once visitors start clicking your links.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  icon,
                  size: 16,
                  color: iconColor,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}

class _LinkStatCard extends StatelessWidget {
  final int rank;
  final LinkAnalytics link;
  final int totalClicks;

  const _LinkStatCard({
    required this.rank,
    required this.link,
    required this.totalClicks,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = totalClicks > 0 ? (link.clickCount / totalClicks) : 0.0;
    final rankColor = _getRankColor(rank);
    final progressColor = _getProgressColor(rank);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rank badge with medal for top 3
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: rank <= 3
                      ? LinearGradient(
                          colors: [
                            rankColor.withValues(alpha: 0.2),
                            rankColor.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: rank > 3 ? rankColor.withValues(alpha: 0.1) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: rank <= 3
                      ? Border.all(color: rankColor.withValues(alpha: 0.3), width: 1.5)
                      : null,
                ),
                child: Center(
                  child: rank <= 3
                      ? FaIcon(
                          _getRankIcon(rank),
                          size: 18,
                          color: rankColor,
                        )
                      : Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: rankColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Link info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title.isNotEmpty ? link.title : 'Untitled Link',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.link_rounded,
                          size: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatUrl(link.url),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Click count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '${link.clickCount}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: progressColor,
                          ),
                    ),
                    Text(
                      'clicks',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: progressColor.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar with gradient
          Stack(
            children: [
              // Background
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Progress
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        progressColor,
                        progressColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${(percentage * 100).toStringAsFixed(1)}% of total clicks',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return FontAwesomeIcons.trophy;
      case 2:
        return FontAwesomeIcons.medal;
      case 3:
        return FontAwesomeIcons.award;
      default:
        return FontAwesomeIcons.hashtag;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFF708090); // Silver/Slate
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFF1DB877); // VLag Green
    }
  }

  Color _getProgressColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFF59E0B); // Amber
      case 2:
        return const Color(0xFF64748B); // Slate
      case 3:
        return const Color(0xFF92400E); // Brown
      default:
        return const Color(0xFF1DB877); // VLag Green
    }
  }

  String _formatUrl(String url) {
    // Remove protocol and trailing slash
    String formatted = url
        .replaceFirst('https://', '')
        .replaceFirst('http://', '');
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }
}
