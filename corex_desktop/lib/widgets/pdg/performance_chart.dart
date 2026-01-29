import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum ChartType { pie, bar, horizontalBar }

class PerformanceChart extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final ChartType type;
  final String? valueKey;
  final String? labelKey;

  const PerformanceChart({
    Key? key,
    required this.title,
    required this.data,
    required this.type,
    this.valueKey,
    this.labelKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1F2E).withOpacity(0.8),
            const Color(0xFF2D3748).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getChartColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getChartIcon(),
                  color: _getChartColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Graphique
          SizedBox(
            height: 200,
            child: data.isEmpty ? _buildEmptyState() : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getChartIcon(),
            color: Colors.white.withOpacity(0.3),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune donnée disponible',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    switch (type) {
      case ChartType.pie:
        return _buildPieChart();
      case ChartType.bar:
        return _buildBarChart();
      case ChartType.horizontalBar:
        return _buildHorizontalBarChart();
    }
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _generatePieSections(),
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Gestion des interactions
          },
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxValue() * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length && labelKey != null) {
                  final label = data[index][labelKey!].toString();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label.length > 8 ? '${label.substring(0, 8)}...' : label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
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
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  _formatValue(value),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _generateBarGroups(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getMaxValue() > 0 ? _getMaxValue() / 5 : 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  Widget _buildHorizontalBarChart() {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: data.take(5).map((item) {
        final label = labelKey != null ? item[labelKey!].toString() : '';
        final value = valueKey != null ? (item[valueKey!] as num).toDouble() : 0.0;
        final maxValue = _getMaxValue();
        final percentage = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label.length > 20 ? '${label.substring(0, 20)}...' : label,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    _formatValue(value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getChartColor(),
                          _getChartColor().withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<PieChartSectionData> _generatePieSections() {
    final colors = [
      const Color(0xFF6C5CE7),
      const Color(0xFF74B9FF),
      const Color(0xFF00B894),
      const Color(0xFFFDAB3D),
      const Color(0xFFE17055),
      const Color(0xFFA29BFE),
      const Color(0xFF00CEC9),
    ];

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final value = (item['pourcentage'] ?? item['count'] ?? 0).toDouble();

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: value,
        title: '${value.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> _generateBarGroups() {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final value = valueKey != null ? (item[valueKey!] as num).toDouble() : 0.0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                _getChartColor(),
                _getChartColor().withOpacity(0.7),
              ],
            ),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxValue() {
    if (data.isEmpty || valueKey == null) return 100;
    final values = data.map((item) => (item[valueKey!] as num).toDouble()).toList();
    if (values.isEmpty) return 100;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return maxValue > 0 ? maxValue : 100;
  }

  Color _getChartColor() {
    switch (type) {
      case ChartType.pie:
        return const Color(0xFF6C5CE7);
      case ChartType.bar:
        return const Color(0xFF00B894);
      case ChartType.horizontalBar:
        return const Color(0xFFE17055);
    }
  }

  IconData _getChartIcon() {
    switch (type) {
      case ChartType.pie:
        return Icons.pie_chart;
      case ChartType.bar:
        return Icons.bar_chart;
      case ChartType.horizontalBar:
        return Icons.align_horizontal_left;
    }
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}
