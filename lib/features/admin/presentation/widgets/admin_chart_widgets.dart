import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_colors.dart';

class AdminChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final String? subtitle;
  final IconData? icon;

  const AdminChartCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 16),

          // Chart content with constrained height to prevent overflow
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 300, // Prevent charts from becoming too tall
              minHeight: 200,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
class AdminUserGrowthChart extends StatelessWidget {
  final int newUsersToday;
  final int newUsersWeek;
  final int newUsersMonth;

  const AdminUserGrowthChart({
    super.key,
    required this.newUsersToday,
    required this.newUsersWeek,
    required this.newUsersMonth,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: newUsersMonth.toDouble() * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor:(group) =>  Colors.grey.shade800,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String period;
              switch (group.x.toInt()) {
                case 0:
                  period = 'Today';
                  break;
                case 1:
                  period = 'This Week';
                  break;
                case 2:
                  period = 'This Month';
                  break;
                default:
                  period = '';
              }
              return BarTooltipItem(
                '$period\n${rod.toY.round()} users',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text('Today', style: TextStyle(fontSize: 12));
                  case 1:
                    return const Text('Week', style: TextStyle(fontSize: 12));
                  case 2:
                    return const Text('Month', style: TextStyle(fontSize: 12));
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: newUsersToday.toDouble(),
                color: Colors.blue,
                width: 16,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: newUsersWeek.toDouble(),
                color: Colors.green,
                width: 16,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: newUsersMonth.toDouble(),
                color: Colors.orange,
                width: 16,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ],
        gridData: const FlGridData(show: false),
      ),
    );
  }
}

class AdminContentDistributionChart extends StatelessWidget {
  final int tips;
  final int videos;
  final int posts;

  const AdminContentDistributionChart({
    super.key,
    required this.tips,
    required this.videos,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    final total = tips + videos + posts;
    if (total == 0) {
      return const Center(child: Text('No content data available'));
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: Colors.blue,
                  value: tips.toDouble(),
                  title: '${(tips / total * 100).round()}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.green,
                  value: videos.toDouble(),
                  title: '${(videos / total * 100).round()}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: Colors.orange,
                  value: posts.toDouble(),
                  title: '${(posts / total * 100).round()}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Tips', tips, Colors.blue),
              const SizedBox(height: 8),
              _buildLegendItem('Videos', videos, Colors.green),
              const SizedBox(height: 8),
              _buildLegendItem('Posts', posts, Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class AdminActivityChart extends StatelessWidget {
  final List<Map<String, dynamic>> activityData;

  const AdminActivityChart({
    super.key,
    required this.activityData,
  });

  @override
  Widget build(BuildContext context) {
    if (activityData.isEmpty) {
      return const Center(child: Text('No activity data available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Colors.grey,
              strokeWidth: 0.5,
            );
          },
          getDrawingVerticalLine: (value) {
            return const FlLine(
              color: Colors.grey,
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() < activityData.length) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      activityData[value.toInt()]['day'] ?? '',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d)),
        ),
        minX: 0,
        maxX: (activityData.length - 1).toDouble(),
        minY: 0,
        maxY: activityData.map((e) => e['value'] as int).reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: activityData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value['value'].toDouble());
            }).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blue.withValues(alpha: 0.5)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withValues(alpha: 0.3),
                  Colors.blue.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}